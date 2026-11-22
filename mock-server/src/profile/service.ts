import { ApiError } from '../http/errors.js';
import { minorError, type AuthService } from '../auth/service.js';
import {
  pendingSteps,
  type AuthUser,
  type Gender,
  type Language,
  type StoreAgeSignal,
} from '../auth/store.js';
import type { State } from '../state.js';
import {
  ageOn,
  checkDisplayName,
  isReserved,
  isValidDate,
  todayIn,
  usernameBase,
  usernameFormatOk,
} from './rules.js';

export interface ProfilePatch {
  displayName?: string;
  birthDate?: string;
  gender?: Gender | null;
  language?: Language;
  storeAgeSignal?: StoreAgeSignal;
}

const ADULT = 18;
const MAX_AGE = 120;
const SUGGESTIONS = 3;

/** Cadastro inicial (plano 1c): perfil, decisão de idade, @ e interesses. */
export class ProfileService {
  constructor(
    private readonly getState: () => State,
    private readonly auth: AuthService,
    private readonly clock: () => number = Date.now,
  ) {}

  private get state() {
    return this.getState();
  }

  /** GET /me: o único lugar onde gênero e data aparecem (Q-59). */
  me(user: AuthUser) {
    const steps = pendingSteps(user);
    return {
      id: user.id,
      needsProfile: steps.length > 0,
      pendingSteps: steps,
      accountStatus: user.accountStatus,
      ageStatus: user.ageStatus,
      displayName: user.displayName,
      username: user.username,
      gender: user.gender,
      birthDateSet: user.birthDate !== null,
      language: user.language,
      pendingTerms: this.auth.pendingTerms(user.id),
    };
  }

  /** PATCH /me. Data uma vez só; idade decidida aqui (RN-01). Sem await: atômico. */
  patch(user: AuthUser, deviceId: string, body: ProfilePatch) {
    let birthDate = user.birthDate;
    if (body.birthDate !== undefined) {
      if (!isValidDate(body.birthDate)) throw new ApiError(400, 'validacao', { field: 'birthDate' });
      if (user.birthDate !== null && user.birthDate !== body.birthDate) {
        throw new ApiError(409, 'conflito', { reason: 'data_imutavel' });
      }
      const today = todayIn(this.state.tenant.timezone, new Date(this.clock()));
      if (body.birthDate > today || ageOn(body.birthDate, today) > MAX_AGE) {
        throw new ApiError(400, 'validacao', { field: 'birthDate' });
      }
      birthDate = body.birthDate;
    }
    let displayName = user.displayName;
    if (body.displayName !== undefined) {
      const r = checkDisplayName(body.displayName, this.state.profileLists.blockedNameWords);
      if (!r.ok) throw new ApiError(400, 'validacao', { field: 'displayName', reason: r.reason });
      displayName = r.value;
    }
    const signal = body.storeAgeSignal ?? user.storeAgeSignal;

    // O servidor decide a idade, só quando chega data ou sinal novo (trocar o
    // idioma não reavalia) e nunca depois de a equipe liberar com verificação.
    // O sinal da loja vem do app: só restringe, nunca libera.
    const ageInput = body.birthDate !== undefined || body.storeAgeSignal !== undefined;
    const today = todayIn(this.state.tenant.timezone, new Date(this.clock()));
    const minorByDate = birthDate !== null && ageOn(birthDate, today) < ADULT;
    const minorBySignal =
      signal?.status === 'shared' &&
      ((signal.ageUpper !== null && signal.ageUpper < ADULT) ||
        (signal.ageLower !== null && signal.ageLower < ADULT));
    if (ageInput && user.ageStatus !== 'verificada' && (minorByDate || minorBySignal)) {
      user.birthDate = birthDate;
      user.storeAgeSignal = signal;
      this.auth.freezeMinor(user, deviceId);
      throw minorError(user.id);
    }

    user.birthDate = birthDate;
    user.displayName = displayName;
    user.storeAgeSignal = signal;
    if (body.gender !== undefined) user.gender = body.gender;
    if (body.language !== undefined) user.language = body.language;
    return this.me(user);
  }

  private takenUsernames(): Set<string> {
    // Conta congelada continua com o @ reservado.
    const taken = new Set<string>();
    for (const u of this.state.auth.users.values()) if (u.username) taken.add(u.username);
    return taken;
  }

  private reserved(): string[] {
    const { reservedUsernames } = this.state.profileLists;
    return [...reservedUsernames, this.state.tenant.id, this.state.tenant.appName];
  }

  private reasonFor(u: string, taken: Set<string>): 'formato' | 'ocupado' | 'reservado' | null {
    if (!usernameFormatOk(u)) return 'formato';
    if (isReserved(u, this.reserved())) return 'reservado';
    if (taken.has(u)) return 'ocupado';
    return null;
  }

  private suggest(user: AuthUser, taken: Set<string>): string[] {
    // Nome com termo reservado ("Suporte Ana") daria só sugestões reservadas: usa a base neutra.
    const fromName = usernameBase(user.displayName);
    const base = isReserved(fromName, this.reserved()) ? 'usuario' : fromName;
    const out: string[] = [];
    const candidates = [base, ...Array.from({ length: 40 }, (_, i) => `${base}${(i * 37 + 11) % 1000}`)];
    for (const c of candidates) {
      if (out.length >= SUGGESTIONS) break;
      if (c.length <= 20 && this.reasonFor(c, taken) === null) out.push(c);
    }
    return out;
  }

  /** Limite por conta (o limite por IP fica na rota). */
  limitUser(userId: string) {
    const key = `username|${userId}`;
    const now = this.clock();
    const hits = (this.state.auth.userHits.get(key) ?? []).filter((t) => t > now - 60_000);
    if (hits.length >= this.state.auth.config.usernameChecksPerUserPerMinute) {
      throw new ApiError(429, 'limite_excedido', {}, { 'Retry-After': '60' });
    }
    hits.push(now);
    this.state.auth.userHits.set(key, hits);
  }

  availability(user: AuthUser, raw: string) {
    const u = raw.toLowerCase();
    if (user.username === u) return { available: true, suggestions: [] as string[] }; // o próprio @
    const taken = this.takenUsernames();
    const reason = this.reasonFor(u, taken);
    return reason === null
      ? { available: true, suggestions: [] as string[] }
      : { available: false, reason, suggestions: this.suggest(user, taken) };
  }

  /** POST /me/username: checa e grava num passo só (sem await). */
  setUsername(user: AuthUser, raw: string) {
    const u = raw.toLowerCase();
    // Troca a cada 30 dias é do PER02 (Fase 2): no cadastro, só a primeira
    // definição. Checado antes de tudo para não virar oráculo de @ ocupados.
    if (user.username !== null) {
      if (user.username === u) return { username: u };
      throw new ApiError(409, 'conflito', { reason: 'ja_definido' });
    }
    const reason = this.reasonFor(u, this.takenUsernames());
    if (reason === 'formato') throw new ApiError(400, 'validacao', { field: 'username' });
    if (reason !== null) throw new ApiError(409, 'username_indisponivel', { reason });
    user.username = u;
    return { username: u };
  }

  interests(english: boolean) {
    return {
      items: this.state.profileLists.interests
        .filter((i) => i.active !== false)
        .map((i) => ({ id: i.id, name: english ? i.en : i.pt })),
    };
  }

  setInterests(user: AuthUser, ids: string[]) {
    const known = new Set(
      this.state.profileLists.interests.filter((i) => i.active !== false).map((i) => i.id),
    );
    if (new Set(ids).size !== ids.length || ids.some((id) => !known.has(id))) {
      throw new ApiError(400, 'validacao', { field: 'ids' });
    }
    user.interests = [...ids];
  }
}
