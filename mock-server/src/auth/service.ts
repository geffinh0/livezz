import { randomUUID } from 'node:crypto';
import type { ConnectorRegistry } from '../connectors/registry.js';
import { ApiError } from '../http/errors.js';
import type { Hub } from '../realtime/hub.js';
import type { Device, State } from '../state.js';
import { accessTokenTtlMs, passwordProblems } from './config.js';
import {
  dummyHashPromise,
  hashSecret,
  randomCode,
  randomToken,
  sha256,
  signAccess,
  verifyAccess,
  verifySecret,
} from './crypto.js';
import type { AuthSession, AuthUser, RevokeReason, VerificationCode } from './store.js';

export interface TokenResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: { id: string; needsProfile: boolean };
}

export interface AuthContext {
  user: AuthUser;
  session: AuthSession;
}

const PHONE = /^\+[1-9]\d{7,14}$/;
const EMAIL = /^[^\s@]{1,64}@[^\s@]{1,190}\.[^\s@]{2,}$/;
const DAY = 86_400_000;

export const normalizeEmail = (e: string) => e.trim().toLowerCase();

/** Motivo de revogação → código de erro HTTP e motivo do evento de tempo real. */
const revokeErrors: Record<
  RevokeReason,
  { code: 'sessao_substituida' | 'sessao_revogada' | 'sessao_expirada'; event: string }
> = {
  outro_aparelho: { code: 'sessao_substituida', event: 'outro_aparelho' },
  logout: { code: 'sessao_revogada', event: 'revogada' },
  reuso_refresh: { code: 'sessao_revogada', event: 'revogada' },
  senha_trocada: { code: 'sessao_revogada', event: 'senha_trocada' },
  conta_bloqueada: { code: 'sessao_revogada', event: 'conta_bloqueada' },
  expirada: { code: 'sessao_expirada', event: 'expirada' },
  mesmo_aparelho: { code: 'sessao_revogada', event: 'revogada' },
};

export class AuthService {
  constructor(
    private readonly getState: () => State,
    private readonly hub: Hub,
    private readonly connectors: ConnectorRegistry,
    private readonly clock: () => number = Date.now,
  ) {}

  private get state() {
    return this.getState();
  }
  private get store() {
    return this.state.auth;
  }

  // ---------- aparelho ----------
  async checkDevice(deviceId: string, deviceSecret: string): Promise<Device> {
    const d = this.state.devices.get(deviceId);
    if (!d?.secretHash || !(await verifySecret(deviceSecret, d.secretHash))) {
      throw new ApiError(401, 'dispositivo_invalido');
    }
    return d;
  }

  // ---------- força bruta ----------
  checkLock(...keys: string[]) {
    const now = this.clock();
    for (const k of keys) {
      const f = this.store.failures.get(k);
      if (f && f.lockedUntil > now) {
        throw new ApiError(
          429,
          'limite_excedido',
          {},
          { 'Retry-After': String(Math.ceil((f.lockedUntil - now) / 1000)) },
        );
      }
    }
  }
  fail(...keys: string[]) {
    const { loginMaxFailures, ipMaxFailures, loginLockBaseSeconds } = this.store.config;
    for (const k of keys) {
      const f = this.store.failures.get(k) ?? { count: 0, lockedUntil: 0 };
      f.count += 1;
      // IP tem limite alto (CGNAT): bloquear a rede inteira por 5 erros seria negação de serviço.
      const max = k.startsWith('ip:') ? ipMaxFailures : loginMaxFailures;
      if (f.count >= max) {
        // bloqueio progressivo: 1, 2, 4, 8… minutos
        f.lockedUntil = this.clock() + loginLockBaseSeconds * 1000 * 2 ** (f.count - max);
      }
      this.store.failures.set(k, f);
    }
  }
  clearFailures(...keys: string[]) {
    for (const k of keys) this.store.failures.delete(k);
  }

  /** Limite simples por IP e por hora (envio de código, registro de aparelho). */
  hitIp(kind: 'send' | 'device', ip: string) {
    const limit =
      kind === 'send' ? this.store.config.codeSendsPerIpPerHour : this.store.config.devicesPerIpPerHour;
    const key = `${kind}|${ip}`;
    const now = this.clock();
    const hits = (this.store.ipHits.get(key) ?? []).filter((t) => now - t < 3_600_000);
    if (hits.length >= limit) {
      const retry = Math.ceil((3_600_000 - (now - (hits[0] ?? now))) / 1000);
      throw new ApiError(429, 'limite_excedido', {}, { 'Retry-After': String(retry) });
    }
    hits.push(now);
    this.store.ipHits.set(key, hits);
  }

  // ---------- códigos (RN-02) ----------
  async sendCode(
    input: {
      channel: 'sms' | 'whatsapp' | 'email';
      destination: string;
      purpose: VerificationCode['purpose'];
    },
    ip: string,
  ) {
    this.hitIp('send', ip);
    const { flags } = this.state.config;
    const cfg = this.store.config;
    const { channel, purpose } = input;
    let destination = input.destination.trim();
    if (channel === 'email') {
      if (!flags.loginEmail) throw new ApiError(403, 'funcionalidade_desligada');
      destination = normalizeEmail(destination);
      if (!EMAIL.test(destination)) throw new ApiError(400, 'validacao', { field: 'destination' });
    } else {
      const channelOn = channel === 'sms' ? flags.loginSms : flags.loginWhatsapp;
      if (!flags.loginPhone || !channelOn) throw new ApiError(403, 'funcionalidade_desligada');
      if (!PHONE.test(destination)) throw new ApiError(400, 'validacao', { field: 'destination' });
      if (purpose === 'reset') throw new ApiError(400, 'validacao', { field: 'purpose' });
    }
    const now = this.clock();
    const recent = (this.store.sends.get(destination) ?? []).filter((t) => now - t < 3_600_000);
    const last = recent.at(-1);
    if (recent.length >= cfg.codeMaxSendsPerHour) {
      const retry = Math.ceil((3_600_000 - (now - (recent[0] ?? now))) / 1000);
      throw new ApiError(429, 'limite_excedido', {}, { 'Retry-After': String(retry) });
    }
    if (last !== undefined && now - last < cfg.codeResendSeconds * 1000) {
      const retry = Math.ceil((cfg.codeResendSeconds * 1000 - (now - last)) / 1000);
      throw new ApiError(429, 'limite_excedido', {}, { 'Retry-After': String(retry) });
    }
    recent.push(now);
    this.store.sends.set(destination, recent);

    // Respostas iguais exista ou não a conta: decidimos aqui se de fato envia código.
    const deliver = await this.shouldDeliver(channel, destination, purpose);
    if (deliver) {
      const code = randomCode();
      this.store.codes.set(`${purpose}|${destination}`, {
        destination,
        purpose,
        codeHash: sha256(code),
        attempts: 0,
        expiresAt: now + cfg.codeTtlSeconds * 1000,
        usedAt: null,
        // Cadastro: o código carrega a senha de quem o pediu (anti-sequestro de cadastro).
        passwordHash:
          purpose === 'signup' ? (this.store.pendingSignups.get(destination)?.passwordHash ?? null) : null,
      });
      this.store.lastCodes.set(destination, code); // SÓ MOCK (outbox)
      if (channel === 'email') {
        await this.connectors.email()?.sendCode({ email: destination, code, purpose });
      } else {
        await this.connectors.sms()?.sendCode({ channel, phoneE164: destination, code, locale: 'pt-BR' });
      }
    }
    return { expiresInSeconds: cfg.codeTtlSeconds, resendInSeconds: cfg.codeResendSeconds };
  }

  private async shouldDeliver(channel: string, destination: string, purpose: VerificationCode['purpose']) {
    if (channel !== 'email') return true; // telefone: login cria conta se não existir
    const confirmed = this.findMethod('email', destination);
    if (purpose === 'reset') return Boolean(confirmed?.verifiedAt);
    if (purpose === 'signup') {
      if (confirmed?.verifiedAt) {
        // já tem conta: avisa o dono em vez de mandar código (sem revelar a quem pediu)
        this.store.notices.push({
          userId: confirmed.userId,
          destination,
          kind: 'ja_tem_conta',
          at: new Date(this.clock()).toISOString(),
        });
        return false;
      }
      return this.store.pendingSignups.has(destination);
    }
    return true;
  }

  private consumeCode(
    destination: string,
    purpose: VerificationCode['purpose'],
    code: string,
  ): VerificationCode {
    const key = `${purpose}|${destination}`;
    const c = this.store.codes.get(key);
    const now = this.clock();
    if (!c || c.usedAt !== null) throw new ApiError(400, 'codigo_invalido');
    if (c.expiresAt < now) {
      this.store.codes.delete(key);
      throw new ApiError(400, 'codigo_expirado');
    }
    if (c.codeHash !== sha256(code)) {
      c.attempts += 1;
      if (c.attempts >= this.store.config.codeMaxAttempts) this.store.codes.delete(key); // morre na 5ª
      throw new ApiError(400, 'codigo_invalido');
    }
    c.usedAt = now;
    this.store.codes.delete(key);
    return c;
  }

  async verifyCode(
    input: {
      destination: string;
      code: string;
      purpose: 'login' | 'signup';
      deviceId: string;
      deviceSecret: string;
      password?: string;
    },
    ip: string,
  ) {
    const device = await this.checkDevice(input.deviceId, input.deviceSecret);
    const isEmail = input.destination.includes('@');
    const destination = isEmail ? normalizeEmail(input.destination) : input.destination.trim();
    const keys = [`dest:${destination}|dev:${device.id}`, `ip:${ip}`];
    this.checkLock(...keys);
    let code: VerificationCode;
    try {
      code = this.consumeCode(destination, input.purpose, input.code);
      // Cadastro por e-mail: só confirma quem sabe a senha usada ao pedir ESTE código.
      if (isEmail) {
        const ok =
          input.purpose === 'signup' &&
          code.passwordHash !== null &&
          (await verifySecret(input.password ?? '', code.passwordHash));
        if (!ok) throw new ApiError(400, 'codigo_invalido');
      }
    } catch (e) {
      this.fail(...keys);
      throw e;
    }
    this.clearFailures(`dest:${destination}|dev:${device.id}`);
    let userId: string;
    if (isEmail) {
      const pending = { passwordHash: code.passwordHash ?? '' };
      // novo cadastro confirmado substitui o não confirmado
      this.store.methods = this.store.methods.filter(
        (m) => !(m.type === 'email' && m.identifier === destination && !m.verifiedAt),
      );
      const user = this.createUser();
      this.store.methods.push({
        userId: user.id,
        type: 'email',
        identifier: destination,
        passwordHash: pending.passwordHash,
        verifiedAt: new Date(this.clock()).toISOString(),
      });
      this.store.pendingSignups.delete(destination);
      this.store.codes.delete(`signup|${destination}`);
      userId = user.id;
    } else {
      const method = this.findMethod('telefone', destination);
      if (method) {
        userId = method.userId;
      } else {
        const user = this.createUser();
        this.store.methods.push({
          userId: user.id,
          type: 'telefone',
          identifier: destination,
          passwordHash: null,
          verifiedAt: new Date(this.clock()).toISOString(),
        });
        userId = user.id;
      }
    }
    return this.issueSession(userId, device.id);
  }

  // ---------- e-mail e senha ----------
  async signupEmail(emailRaw: string, password: string, ip: string) {
    if (!this.state.config.flags.loginEmail) throw new ApiError(403, 'funcionalidade_desligada');
    const email = normalizeEmail(emailRaw);
    if (!EMAIL.test(email)) throw new ApiError(400, 'validacao', { field: 'email' });
    const problems = passwordProblems(password);
    if (problems.length) throw new ApiError(400, 'validacao', { field: 'password', rules: problems });
    const passwordHash = await hashSecret(password); // sempre (mesmo tempo com ou sem conta)
    if (!this.findMethod('email', email)?.verifiedAt) {
      this.store.pendingSignups.set(email, { email, passwordHash });
    }
    await this.sendCode({ channel: 'email', destination: email, purpose: 'signup' }, ip);
  }

  async loginEmail(
    input: { email: string; password: string; deviceId: string; deviceSecret: string },
    ip: string,
  ) {
    const device = await this.checkDevice(input.deviceId, input.deviceSecret);
    const email = normalizeEmail(input.email);
    // Conta+aparelho (outro aparelho errando não tranca o dono) e IP com limite alto.
    const keys = [`acct:${email}|dev:${device.id}`, `ip:${ip}`];
    this.checkLock(...keys);
    const method = this.findMethod('email', email);
    const hash = method?.passwordHash ?? (await dummyHashPromise);
    const ok = await verifySecret(input.password, hash); // roda mesmo sem conta (tempo igual)
    if (!method || !ok) {
      this.fail(...keys);
      throw new ApiError(401, 'credenciais_invalidas');
    }
    if (!method.verifiedAt) throw new ApiError(403, 'email_nao_confirmado');
    this.clearFailures(`acct:${email}|dev:${device.id}`);
    return this.issueSession(method.userId, device.id);
  }

  async resetPassword(input: { email: string; code: string; newPassword: string }, ip: string) {
    const email = normalizeEmail(input.email);
    const keys = [`dest:${email}|ip:${ip}`, `ip:${ip}`];
    this.checkLock(...keys);
    const problems = passwordProblems(input.newPassword);
    if (problems.length) throw new ApiError(400, 'validacao', { field: 'newPassword', rules: problems });
    try {
      this.consumeCode(email, 'reset', input.code);
    } catch (e) {
      this.fail(...keys);
      throw e;
    }
    const method = this.findMethod('email', email);
    if (!method) throw new ApiError(400, 'codigo_invalido');
    method.passwordHash = await hashSecret(input.newPassword);
    // RN-04: troca de senha encerra todas as sessões
    for (const s of this.store.sessions.values()) {
      if (s.userId === method.userId && !s.revokedAt) this.revoke(s, 'senha_trocada');
    }
  }

  // ---------- Google (SÓ MOCK: idToken de teste) ----------
  async google(input: { idToken: string; deviceId: string; deviceSecret: string }) {
    if (!this.state.config.flags.loginGoogle) throw new ApiError(403, 'funcionalidade_desligada');
    const device = await this.checkDevice(input.deviceId, input.deviceSecret);
    const m = /^mock-google:(.+)$/.exec(input.idToken);
    if (!m?.[1] || m[1] === 'erro' || !EMAIL.test(m[1])) throw new ApiError(401, 'credenciais_invalidas');
    const email = normalizeEmail(m[1]);
    const sub = `google-${sha256(email).slice(0, 16)}`;
    let method = this.findMethod('google', sub);
    if (!method) {
      // email_verified (sempre verdadeiro no token de teste): liga à conta de e-mail confirmada
      const byEmail = this.findMethod('email', email);
      const userId = byEmail?.verifiedAt ? byEmail.userId : this.createUser().id;
      method = {
        userId,
        type: 'google',
        identifier: sub,
        passwordHash: null,
        verifiedAt: new Date(this.clock()).toISOString(),
      };
      this.store.methods.push(method);
    }
    return this.issueSession(method.userId, device.id);
  }

  // ---------- sessões (ADR 0012) ----------
  private createUser(): AuthUser {
    const u: AuthUser = {
      id: `u_${randomUUID()}`,
      accountStatus: 'ativa',
      needsProfile: true,
      createdAt: new Date(this.clock()).toISOString(),
    };
    this.store.users.set(u.id, u);
    return u;
  }

  private findMethod(type: 'telefone' | 'email' | 'google', identifier: string) {
    return this.store.methods.find((m) => m.type === type && m.identifier === identifier);
  }

  private assertActiveAccount(user: AuthUser | undefined): asserts user is AuthUser {
    if (!user) throw new ApiError(401, 'nao_autenticado');
    if (user.accountStatus === 'banida') throw new ApiError(403, 'conta_banida');
    if (user.accountStatus === 'suspensa') throw new ApiError(403, 'conta_suspensa');
  }

  private issueSession(userId: string, deviceId: string): TokenResponse {
    const user = this.store.users.get(userId);
    this.assertActiveAccount(user);
    const now = this.clock();
    // RN-06: uma sessão ativa por conta. Em outro aparelho, a anterior cai com aviso
    // "outro aparelho"; no mesmo aparelho (novo login), cai sem esse aviso.
    const seenDevices = new Set<string>();
    for (const s of this.store.sessions.values()) {
      if (s.userId !== userId) continue;
      seenDevices.add(s.deviceId);
      if (!s.revokedAt) this.revoke(s, s.deviceId === deviceId ? 'mesmo_aparelho' : 'outro_aparelho');
    }
    if (seenDevices.size > 0 && !seenDevices.has(deviceId)) {
      // Alerta de novo aparelho ao dono (SEGURANCA.md); envio real por push na Fase 8.
      this.store.notices.push({
        userId,
        destination: null,
        kind: 'novo_aparelho',
        at: new Date(now).toISOString(),
      });
    }
    const refresh = randomToken();
    const session: AuthSession = {
      id: `s_${randomUUID()}`,
      userId,
      deviceId,
      refreshHash: sha256(refresh),
      previousRefreshHash: null,
      rotatedAt: null,
      graceUsed: false,
      createdAt: now,
      lastUsedAt: now,
      absoluteExpiresAt: now + this.store.config.sessionMaxDays * DAY,
      revokedAt: null,
      revokeReason: null,
    };
    this.store.sessions.set(session.id, session);
    const device = this.state.devices.get(deviceId);
    if (device) device.userId = userId;
    return this.tokensFor(session, refresh, user);
  }

  private tokensFor(session: AuthSession, refresh: string, user: AuthUser): TokenResponse {
    const ttl = accessTokenTtlMs(this.store.config);
    return {
      accessToken: signAccess({ sub: session.userId, sid: session.id, exp: this.clock() + ttl }),
      refreshToken: refresh,
      expiresIn: Math.round(ttl / 1000),
      user: { id: user.id, needsProfile: user.needsProfile },
    };
  }

  revoke(s: AuthSession, reason: RevokeReason) {
    s.revokedAt = this.clock();
    s.revokeReason = reason;
    const err = revokeErrors[reason];
    if (reason === 'outro_aparelho') {
      this.hub.closeSession(s.id, 4002, 'session.replaced', { at: new Date(this.clock()).toISOString() });
    } else {
      this.hub.closeSession(s.id, 4001, 'session.invalid', { reason: err.event });
    }
  }

  private expiredReason(s: AuthSession): boolean {
    const now = this.clock();
    return now > s.absoluteExpiresAt || now - s.lastUsedAt > this.store.config.sessionIdleDays * DAY;
  }

  async refresh(input: { refreshToken: string; deviceId: string; deviceSecret: string }) {
    const device = await this.checkDevice(input.deviceId, input.deviceSecret);
    const hash = sha256(input.refreshToken);
    const now = this.clock();
    for (const s of this.store.sessions.values()) {
      const current = s.refreshHash === hash;
      const previous = s.previousRefreshHash === hash;
      if (!current && !previous) continue;
      if (s.deviceId !== device.id) throw new ApiError(401, 'dispositivo_invalido');
      if (s.revokedAt) throw new ApiError(401, revokeErrors[s.revokeReason ?? 'logout'].code);
      if (this.expiredReason(s)) {
        this.revoke(s, 'expirada');
        throw new ApiError(401, 'sessao_expirada');
      }
      if (previous) {
        // Tolerância (resposta perdida na rede): o refresh anterior vale UMA vez,
        // dentro de 10 s da troca. Não reabre a janela.
        const withinGrace =
          !s.graceUsed &&
          s.rotatedAt !== null &&
          now - s.rotatedAt <= this.store.config.refreshReuseGraceSeconds * 1000;
        if (!withinGrace) {
          // reuso de refresh já trocado: alguém copiou o token
          this.revoke(s, 'reuso_refresh');
          this.store.notices.push({
            userId: s.userId,
            destination: null,
            kind: 'sessao_revogada',
            at: new Date(now).toISOString(),
          });
          throw new ApiError(401, 'sessao_revogada');
        }
      }
      const user = this.store.users.get(s.userId);
      try {
        this.assertActiveAccount(user);
      } catch (e) {
        this.revoke(s, 'conta_bloqueada');
        throw e;
      }
      const next = randomToken();
      if (current) {
        // rotação normal: o atual vira o anterior e abre a tolerância
        s.previousRefreshHash = s.refreshHash;
        s.rotatedAt = now;
        s.graceUsed = false;
      } else {
        // uso único da tolerância: não mexe em rotatedAt nem no anterior
        s.graceUsed = true;
      }
      s.refreshHash = sha256(next);
      s.lastUsedAt = now;
      return this.tokensFor(s, next, user);
    }
    throw new ApiError(401, 'sessao_revogada');
  }

  logout(input: { accessToken?: string; refreshToken?: string }) {
    let session: AuthSession | undefined;
    if (input.accessToken) {
      const c = verifyAccess(input.accessToken); // aceita vencido
      if (c) session = this.store.sessions.get(c.sid);
    }
    if (!session && input.refreshToken) {
      const h = sha256(input.refreshToken);
      session = [...this.store.sessions.values()].find(
        (s) => s.refreshHash === h || s.previousRefreshHash === h,
      );
    }
    if (session && !session.revokedAt) this.revoke(session, 'logout');
  }

  /** Valida o access token (HTTP e WebSocket). */
  authenticate(token: string): AuthContext {
    const claims = verifyAccess(token);
    if (!claims) throw new ApiError(401, 'nao_autenticado');
    const session = this.store.sessions.get(claims.sid);
    if (!session) throw new ApiError(401, 'nao_autenticado');
    if (session.revokedAt) throw new ApiError(401, revokeErrors[session.revokeReason ?? 'logout'].code);
    if (claims.exp < this.clock()) throw new ApiError(401, 'token_expirado');
    const user = this.store.users.get(session.userId);
    this.assertActiveAccount(user);
    session.lastUsedAt = this.clock();
    return { user, session };
  }

  // ---------- termos (ENT16) ----------
  pendingTerms(userId: string) {
    const required: Array<'terms' | 'privacy'> = ['terms', 'privacy'];
    const out: Array<{ document: string; version: number; url: string }> = [];
    for (const doc of required) {
      const current = this.state.config.legalTexts[doc];
      if (!current) continue;
      const accepted = this.store.acceptances.some(
        (a) => a.userId === userId && a.document === doc && a.version === current.version,
      );
      if (!accepted) out.push({ document: doc, version: current.version, url: current.url });
    }
    return out;
  }

  acceptTerms(ctx: AuthContext, document: 'terms' | 'privacy' | 'guidelines', version: number, ip: string) {
    const current = this.state.config.legalTexts[document];
    if (!current || current.version !== version)
      throw new ApiError(409, 'conflito', { currentVersion: current?.version ?? null });
    this.store.acceptances.push({
      userId: ctx.user.id,
      document,
      version,
      acceptedAt: new Date(this.clock()).toISOString(),
      deviceId: ctx.session.deviceId,
      ip,
    });
  }
}
