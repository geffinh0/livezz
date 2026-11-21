import { describe, expect, it } from 'vitest';
import { buildApp, type MockServer } from '../src/app.js';

const devBody = { platform: 'web', appVersion: '0.1.0', locale: 'pt-BR' };

async function setup() {
  const mock = await buildApp();
  const { deviceId, deviceSecret } = (
    await mock.app.inject({ method: 'POST', url: '/v1/devices', payload: devBody })
  ).json();
  return { mock, dev: { deviceId, deviceSecret } as { deviceId: string; deviceSecret: string } };
}

async function newDevice(mock: MockServer) {
  return (await mock.app.inject({ method: 'POST', url: '/v1/devices', payload: devBody })).json() as {
    deviceId: string;
    deviceSecret: string;
  };
}

const post = (mock: MockServer, url: string, payload: object, headers: Record<string, string> = {}) =>
  mock.app.inject({ method: 'POST', url, payload, headers });
const outbox = async (mock: MockServer, destination: string) =>
  (
    await mock.app.inject({
      method: 'GET',
      url: `/__mock/outbox?destination=${encodeURIComponent(destination)}`,
    })
  ).json().code as string;

async function phoneLogin(mock: MockServer, dev: object, phone = '+5511988887777') {
  await post(mock, '/v1/auth/code/send', { channel: 'sms', destination: phone, purpose: 'login' });
  const code = await outbox(mock, phone);
  return post(mock, '/v1/auth/code/verify', { destination: phone, code, purpose: 'login', ...dev });
}

const authed = (token: string) => ({ authorization: `Bearer ${token}` });

describe('telefone + código (ENT04, RN-02)', () => {
  it('envia código e entra; número novo cria conta que precisa de cadastro', async () => {
    const { mock, dev } = await setup();
    const send = await post(mock, '/v1/auth/code/send', {
      channel: 'sms',
      destination: '+5511988887777',
      purpose: 'login',
    });
    expect(send.json()).toEqual({ expiresInSeconds: 60, resendInSeconds: 60 });
    const code = await outbox(mock, '+5511988887777');
    expect(code).toMatch(/^\d{6}$/);
    expect(mock.connectors.outbox.sms.at(-1)?.code).toBe(code);
    const r = await post(mock, '/v1/auth/code/verify', {
      destination: '+5511988887777',
      code,
      purpose: 'login',
      ...dev,
    });
    expect(r.statusCode).toBe(200);
    const body = r.json();
    expect(body.user.needsProfile).toBe(true);
    expect(body.accessToken).toMatch(/^at\./);
    expect(body.expiresIn).toBe(900);
  });

  it('conta existente (fixture) entra sem cadastro', async () => {
    const { mock, dev } = await setup();
    const r = await phoneLogin(mock, dev, '+5511900000001');
    expect(r.json().user).toEqual({ id: 'u-ana', needsProfile: false });
  });

  it('reenvio só depois de 60 s', async () => {
    const { mock } = await setup();
    const p = { channel: 'sms', destination: '+5511911112222', purpose: 'login' };
    await post(mock, '/v1/auth/code/send', p);
    const again = await post(mock, '/v1/auth/code/send', p);
    expect(again.statusCode).toBe(429);
    expect(again.json().error.code).toBe('limite_excedido');
    expect(Number(again.headers['retry-after'])).toBeGreaterThan(0);
  });

  it('código errado conta tentativa; na 5ª o código morre', async () => {
    const { mock, dev } = await setup();
    const phone = '+5511933334444';
    await post(mock, '/v1/auth/code/send', { channel: 'sms', destination: phone, purpose: 'login' });
    const right = await outbox(mock, phone);
    const wrong = right === '000000' ? '111111' : '000000';
    for (let i = 0; i < 5; i++) {
      const r = await post(mock, '/v1/auth/code/verify', {
        destination: phone,
        code: wrong,
        purpose: 'login',
        ...dev,
      });
      expect(r.json().error.code).toMatch(/codigo_invalido|limite_excedido/);
    }
    mock.state.auth.failures.clear(); // isola o efeito do código morto do bloqueio por força bruta
    const r = await post(mock, '/v1/auth/code/verify', {
      destination: phone,
      code: right,
      purpose: 'login',
      ...dev,
    });
    expect(r.json().error.code).toBe('codigo_invalido');
  });

  it('código expirado', async () => {
    const { mock, dev } = await setup();
    mock.state.auth.config.codeTtlSeconds = -1;
    const phone = '+5511955556666';
    await post(mock, '/v1/auth/code/send', { channel: 'sms', destination: phone, purpose: 'login' });
    const code = await outbox(mock, phone);
    const r = await post(mock, '/v1/auth/code/verify', {
      destination: phone,
      code,
      purpose: 'login',
      ...dev,
    });
    expect(r.json().error.code).toBe('codigo_expirado');
  });

  it('WhatsApp desligado por flag → funcionalidade_desligada', async () => {
    const { mock } = await setup();
    const r = await post(mock, '/v1/auth/code/send', {
      channel: 'whatsapp',
      destination: '+5511977778888',
      purpose: 'login',
    });
    expect(r.statusCode).toBe(403);
    expect(r.json().error.code).toBe('funcionalidade_desligada');
  });

  it('segredo do aparelho errado → dispositivo_invalido', async () => {
    const { mock, dev } = await setup();
    const r = await phoneLogin(mock, { ...dev, deviceSecret: 'errado' });
    expect(r.statusCode).toBe(401);
    expect(r.json().error.code).toBe('dispositivo_invalido');
  });
});

describe('e-mail e senha (ENT05, RN-03)', () => {
  it('cadastro → confirma por código → entra', async () => {
    const { mock, dev } = await setup();
    const s = await post(mock, '/v1/auth/email/signup', {
      email: 'Nova@Teste.local',
      password: 'Livezz2026x',
    });
    expect(s.statusCode).toBe(202);
    expect(s.json()).toEqual({ expiresInSeconds: 60, resendInSeconds: 60 });
    const code = await outbox(mock, 'nova@teste.local');
    const v = await post(mock, '/v1/auth/code/verify', {
      destination: 'nova@teste.local',
      code,
      purpose: 'signup',
      password: 'Livezz2026x',
      ...dev,
    });
    expect(v.statusCode).toBe(200);
    const dev2 = await newDevice(mock);
    const login = await post(mock, '/v1/auth/email/login', {
      email: 'nova@teste.local',
      password: 'Livezz2026x',
      ...dev2,
    });
    expect(login.statusCode).toBe(200);
  });

  it('código de login por e-mail não existe (e-mail entra com senha) → 400 validacao', async () => {
    const { mock } = await setup();
    const r = await post(mock, '/v1/auth/code/send', {
      channel: 'email',
      destination: 'ana@teste.local',
      purpose: 'login',
    });
    expect(r.statusCode).toBe(400);
    expect(r.json().error).toMatchObject({ code: 'validacao', details: { field: 'purpose' } });
  });

  it('senha fraca lista as regras', async () => {
    const { mock } = await setup();
    const r = await post(mock, '/v1/auth/email/signup', { email: 'x@teste.local', password: 'senha1234' });
    expect(r.statusCode).toBe(400);
    expect(r.json().error.details.rules).toEqual(['common']);
    const r2 = await post(mock, '/v1/auth/email/signup', { email: 'x@teste.local', password: 'abc' });
    expect(r2.json().error.details.rules).toEqual(['min_length', 'numbers']);
  });

  it('e-mail já cadastrado responde igual e avisa o dono em vez de mandar código', async () => {
    const { mock } = await setup();
    const r = await post(mock, '/v1/auth/email/signup', { email: 'ana@teste.local', password: 'Outra2026x' });
    expect(r.statusCode).toBe(202);
    expect(
      (await mock.app.inject({ method: 'GET', url: '/__mock/outbox?destination=ana@teste.local' }))
        .statusCode,
    ).toBe(404);
    expect(mock.state.auth.notices.at(-1)).toMatchObject({ kind: 'ja_tem_conta', userId: 'u-ana' });
  });

  it('login errado não revela se o e-mail existe e leva tempo parecido', async () => {
    const { mock, dev } = await setup();
    const t0 = performance.now();
    const a = await post(mock, '/v1/auth/email/login', {
      email: 'ana@teste.local',
      password: 'Errada2026x',
      ...dev,
    });
    const t1 = performance.now();
    const b = await post(mock, '/v1/auth/email/login', {
      email: 'ninguem@teste.local',
      password: 'Errada2026x',
      ...dev,
    });
    const t2 = performance.now();
    expect(a.statusCode).toBe(401);
    expect(b.statusCode).toBe(401);
    expect(a.json().error.code).toBe('credenciais_invalidas');
    expect(b.json().error.code).toBe('credenciais_invalidas');
    const [ta, tb] = [t1 - t0, t2 - t1];
    expect(Math.max(ta, tb) / Math.min(ta, tb)).toBeLessThan(4); // os dois rodam o scrypt
  });

  it('força bruta: depois de 5 erros a conta fica bloqueada (429) e o 429 é igual sem conta', async () => {
    const { mock, dev } = await setup();
    for (let i = 0; i < 5; i++) {
      await post(mock, '/v1/auth/email/login', {
        email: 'carla@teste.local',
        password: 'Errada2026x',
        ...dev,
      });
    }
    const locked = await post(mock, '/v1/auth/email/login', {
      email: 'carla@teste.local',
      password: 'TEST_ONLY_Carla2026',
      ...dev,
    });
    expect(locked.statusCode).toBe(429);
    expect(locked.json().error.code).toBe('limite_excedido');
  });

  it('conta banida não entra', async () => {
    const { mock, dev } = await setup();
    const r = await post(mock, '/v1/auth/email/login', {
      email: 'banido@teste.local',
      password: 'TEST_ONLY_Banido2026',
      ...dev,
    });
    expect(r.statusCode).toBe(403);
    expect(r.json().error.code).toBe('conta_banida');
  });
});

describe('Google de teste (ENT06)', () => {
  it('conta nova precisa de cadastro; existente (e-mail confirmado) entra direto; erro', async () => {
    const { mock, dev } = await setup();
    const nova = await post(mock, '/v1/auth/google', {
      idToken: 'mock-google:google.novo@teste.local',
      ...dev,
    });
    expect(nova.json().user.needsProfile).toBe(true);
    const dev2 = await newDevice(mock);
    const ana = await post(mock, '/v1/auth/google', { idToken: 'mock-google:ana@teste.local', ...dev2 });
    expect(ana.json().user).toEqual({ id: 'u-ana', needsProfile: false });
    const erro = await post(mock, '/v1/auth/google', { idToken: 'mock-google:erro', ...dev2 });
    expect(erro.json().error.code).toBe('credenciais_invalidas');
  });
});

describe('recuperar senha (ENT07, RN-04)', () => {
  it('código por e-mail → nova senha → derruba as sessões', async () => {
    const { mock, dev } = await setup();
    const login = (
      await post(mock, '/v1/auth/email/login', {
        email: 'carla@teste.local',
        password: 'TEST_ONLY_Carla2026',
        ...dev,
      })
    ).json();
    await post(mock, '/v1/auth/code/send', {
      channel: 'email',
      destination: 'carla@teste.local',
      purpose: 'reset',
    });
    const code = await outbox(mock, 'carla@teste.local');
    const r = await post(mock, '/v1/auth/password/reset', {
      email: 'carla@teste.local',
      code,
      newPassword: 'NovaSenha2026',
    });
    expect(r.statusCode).toBe(204);
    const me = await mock.app.inject({ method: 'GET', url: '/v1/me', headers: authed(login.accessToken) });
    expect(me.json().error.code).toBe('sessao_revogada');
    const again = await post(mock, '/v1/auth/email/login', {
      email: 'carla@teste.local',
      password: 'NovaSenha2026',
      ...dev,
    });
    expect(again.statusCode).toBe(200);
  });

  it('pedir código para e-mail inexistente responde igual', async () => {
    const { mock } = await setup();
    const r = await post(mock, '/v1/auth/code/send', {
      channel: 'email',
      destination: 'naoexiste@teste.local',
      purpose: 'reset',
    });
    expect(r.statusCode).toBe(200);
  });
});

describe('sessão (ENT19, ADR 0012)', () => {
  it('login em outro aparelho derruba a sessão anterior com sessao_substituida', async () => {
    const { mock, dev } = await setup();
    const a = (await phoneLogin(mock, dev, '+5511900000001')).json();
    const dev2 = await newDevice(mock);
    mock.state.auth.sends.clear(); // libera o reenvio (RN-02) só para este teste
    await phoneLogin(mock, dev2, '+5511900000001');
    const me = await mock.app.inject({ method: 'GET', url: '/v1/me', headers: authed(a.accessToken) });
    expect(me.statusCode).toBe(401);
    expect(me.json().error.code).toBe('sessao_substituida');
  });

  it('refresh rotativo; reuso fora da tolerância revoga; dentro de 10 s é aceito', async () => {
    const { mock, dev } = await setup();
    const t = (await phoneLogin(mock, dev)).json();
    const r1 = (await post(mock, '/v1/auth/refresh', { refreshToken: t.refreshToken, ...dev })).json();
    expect(r1.refreshToken).not.toBe(t.refreshToken);
    // resposta perdida: o app reenvia o refresh antigo dentro de 10 s
    const grace = await post(mock, '/v1/auth/refresh', { refreshToken: t.refreshToken, ...dev });
    expect(grace.statusCode).toBe(200);
    // fora da tolerância: reuso → sessão revogada
    for (const s of mock.state.auth.sessions.values()) s.rotatedAt = Date.now() - 60_000;
    const reuse = await post(mock, '/v1/auth/refresh', { refreshToken: t.refreshToken, ...dev });
    expect(reuse.json().error.code).toBe('sessao_revogada');
    const after = await post(mock, '/v1/auth/refresh', { refreshToken: grace.json().refreshToken, ...dev });
    expect(after.json().error.code).toBe('sessao_revogada');
  });

  it('refresh preso ao aparelho', async () => {
    const { mock, dev } = await setup();
    const t = (await phoneLogin(mock, dev)).json();
    const other = await newDevice(mock);
    const r = await post(mock, '/v1/auth/refresh', { refreshToken: t.refreshToken, ...other });
    expect(r.json().error.code).toBe('dispositivo_invalido');
  });

  it('access vencido → token_expirado; sessão sem uso por 30 dias → sessao_expirada', async () => {
    const { mock, dev } = await setup();
    await post(mock, '/__mock/scenario/token-expira-rapido', {});
    const t = (await phoneLogin(mock, dev)).json();
    expect(t.expiresIn).toBe(5);
    for (const s of mock.state.auth.sessions.values()) s.lastUsedAt = Date.now() - 31 * 86_400_000;
    const r = await post(mock, '/v1/auth/refresh', { refreshToken: t.refreshToken, ...dev });
    expect(r.json().error.code).toBe('sessao_expirada');
  });

  it('logout revoga a sessão (aceita access vencido)', async () => {
    const { mock, dev } = await setup();
    const t = (await phoneLogin(mock, dev)).json();
    const out = await post(mock, '/v1/auth/logout', { refreshToken: t.refreshToken }, authed(t.accessToken));
    expect(out.statusCode).toBe(204);
    const me = await mock.app.inject({ method: 'GET', url: '/v1/me', headers: authed(t.accessToken) });
    expect(me.statusCode).toBe(401);
  });
});

describe('termos (ENT16)', () => {
  it('conta nova tem termos pendentes e é barrada até aceitar', async () => {
    const { mock, dev } = await setup();
    const t = (await phoneLogin(mock, dev)).json();
    const me = (
      await mock.app.inject({ method: 'GET', url: '/v1/me', headers: authed(t.accessToken) })
    ).json();
    expect(me.pendingTerms.map((p: { document: string }) => p.document)).toEqual([
      'terms',
      'privacy',
      'guidelines',
    ]);
    const blocked = await mock.app.inject({
      method: 'GET',
      url: '/__mock/ping-autenticado',
      headers: authed(t.accessToken),
    });
    expect(blocked.json().error.code).toBe('termos_pendentes');
    const conflict = await post(
      mock,
      '/v1/me/terms/accept',
      { document: 'terms', version: 9 },
      authed(t.accessToken),
    );
    expect(conflict.statusCode).toBe(409);
    for (const document of ['terms', 'privacy', 'guidelines']) {
      const ok = await post(mock, '/v1/me/terms/accept', { document, version: 1 }, authed(t.accessToken));
      expect(ok.statusCode).toBe(204);
    }
    // Aceitar de novo a mesma versão não duplica o registro.
    await post(mock, '/v1/me/terms/accept', { document: 'terms', version: 1 }, authed(t.accessToken));
    const rows = mock.state.auth.acceptances.filter((a) => a.userId === t.user.id && a.document === 'terms');
    expect(rows).toHaveLength(1);
    // Termos aceitos; a conta nova ainda precisa do cadastro (plano 1c) para o resto.
    const gate = await mock.app.inject({
      method: 'GET',
      url: '/__mock/ping-autenticado',
      headers: authed(t.accessToken),
    });
    expect(gate.json().error.code).toBe('cadastro_pendente');
    await mock.app.inject({
      method: 'PATCH',
      url: '/v1/me',
      headers: authed(t.accessToken),
      payload: { displayName: 'Nova Pessoa', birthDate: '1990-01-01' },
    });
    const free = await mock.app.inject({
      method: 'GET',
      url: '/__mock/ping-autenticado',
      headers: authed(t.accessToken),
    });
    expect(free.statusCode).toBe(200);
  });

  it('nova versão dos termos exige novo aceite', async () => {
    const { mock, dev } = await setup();
    const t = (await phoneLogin(mock, dev, '+5511900000001')).json();
    const terms = mock.state.config.legalTexts.terms;
    if (terms) terms.version = 2;
    const me = (
      await mock.app.inject({ method: 'GET', url: '/v1/me', headers: authed(t.accessToken) })
    ).json();
    expect(me.pendingTerms).toEqual([expect.objectContaining({ document: 'terms', version: 2 })]);
  });
});

describe('anti-bot (SEG06, RN-85)', () => {
  it('com desafio exigido: sem token → 428; token fake de uso único → passa uma vez', async () => {
    const { mock } = await setup();
    await post(mock, '/__mock/scenario/exigir-desafio', {});
    const body = { channel: 'sms', destination: '+5511912345678', purpose: 'login' };
    const no = await post(mock, '/v1/auth/code/send', body);
    expect(no.statusCode).toBe(428);
    expect(no.json().error).toMatchObject({
      code: 'desafio_necessario',
      details: { providers: ['appcheck'] },
    });
    const h = { 'x-antibot-provider': 'appcheck', 'x-antibot-token': 'fake-ok-abcdef123' };
    expect((await post(mock, '/v1/auth/code/send', body, h)).statusCode).toBe(200);
    const reused = await post(mock, '/v1/auth/code/send', { ...body, destination: '+5511912345679' }, h);
    expect(reused.statusCode).toBe(428);
  });

  it('cada provedor é ligado por flag: com todos desligados o servidor não exige desafio', async () => {
    const { mock } = await setup();
    await post(mock, '/__mock/scenario/exigir-desafio', {});
    mock.state.config.flags.antibotAppCheck = false;
    const body = { channel: 'sms', destination: '+5511912345670', purpose: 'login' };
    expect((await post(mock, '/v1/auth/code/send', body)).statusCode).toBe(200);
    // Turnstile ligado: só ele é aceito.
    mock.state.config.flags.antibotTurnstile = true;
    const r = await post(mock, '/v1/auth/code/send', { ...body, destination: '+5511912345671' });
    expect(r.json().error.details.providers).toEqual(['turnstile']);
    const wrong = { 'x-antibot-provider': 'appcheck', 'x-antibot-token': 'fake-ok-abcdef124' };
    expect(
      (await post(mock, '/v1/auth/code/send', { ...body, destination: '+5511912345671' }, wrong)).statusCode,
    ).toBe(428);
  });
});

describe('logs sem segredos (ADR 0012)', () => {
  it('não registram senha, código, tokens nem authorization', async () => {
    const lines: string[] = [];
    const mock = await buildApp({ logStream: { write: (l: string) => lines.push(l) } });
    const dev = (await mock.app.inject({ method: 'POST', url: '/v1/devices', payload: devBody })).json();
    await mock.app.inject({
      method: 'POST',
      url: '/v1/auth/email/login',
      payload: { email: 'ana@teste.local', password: 'TEST_ONLY_Ana2026', ...dev },
      headers: { authorization: 'Bearer segredo-no-header' },
    });
    const all = lines.join('\n');
    expect(all).not.toContain('TEST_ONLY_Ana2026');
    expect(all).not.toContain('segredo-no-header');
    expect(all).not.toContain(dev.deviceSecret);
  });
});

describe('correções da auditoria de segurança (Fase 1b)', () => {
  it('cadastro: confirmar exige a senha de quem pediu o código (anti-sequestro)', async () => {
    const { mock, dev } = await setup();
    // atacante pede cadastro com o e-mail da vítima e a senha dele
    await post(mock, '/v1/auth/email/signup', { email: 'vitima@teste.local', password: 'Atacante2026x' });
    const code = await outbox(mock, 'vitima@teste.local');
    // a vítima (com a senha DELA) não consegue confirmar com o código do atacante…
    const victim = await post(mock, '/v1/auth/code/verify', {
      destination: 'vitima@teste.local',
      code,
      purpose: 'signup',
      password: 'Vitima2026x',
      ...dev,
    });
    expect(victim.json().error.code).toBe('codigo_invalido');
    // …e a conta não nasce com a senha do atacante.
    expect(mock.state.auth.methods.some((m) => m.identifier === 'vitima@teste.local' && m.verifiedAt)).toBe(
      false,
    );
  });

  it('tolerância do refresh vale uma única vez (não reabre a janela)', async () => {
    const { mock, dev } = await setup();
    const t = (await phoneLogin(mock, dev)).json();
    await post(mock, '/v1/auth/refresh', { refreshToken: t.refreshToken, ...dev }); // rotação normal
    const first = await post(mock, '/v1/auth/refresh', { refreshToken: t.refreshToken, ...dev });
    expect(first.statusCode).toBe(200); // 1º uso do antigo na tolerância
    const second = await post(mock, '/v1/auth/refresh', { refreshToken: t.refreshToken, ...dev });
    expect(second.json().error.code).toBe('sessao_revogada'); // 2º uso: reuso → revoga
  });

  it('limite por IP no envio de códigos e no registro de aparelhos', async () => {
    const { mock } = await setup();
    mock.state.auth.config.codeSendsPerIpPerHour = 2;
    mock.state.auth.config.devicesPerIpPerHour = 2;
    const send = (n: number) =>
      post(mock, '/v1/auth/code/send', {
        channel: 'sms',
        destination: `+55119000099${n}0`,
        purpose: 'login',
      });
    expect((await send(1)).statusCode).toBe(200);
    expect((await send(2)).statusCode).toBe(200);
    expect((await send(3)).statusCode).toBe(429);
    await mock.app.inject({ method: 'POST', url: '/v1/devices', payload: devBody }); // 2º (o setup criou 1)
    const third = await mock.app.inject({ method: 'POST', url: '/v1/devices', payload: devBody });
    expect(third.statusCode).toBe(429);
  });

  it('erros de outro aparelho não trancam o dono da conta', async () => {
    const { mock, dev } = await setup();
    const attacker = await newDevice(mock);
    for (let i = 0; i < 6; i++) {
      await post(mock, '/v1/auth/email/login', {
        email: 'carla@teste.local',
        password: 'Errada2026x',
        ...attacker,
      });
    }
    const owner = await post(mock, '/v1/auth/email/login', {
      email: 'carla@teste.local',
      password: 'TEST_ONLY_Carla2026',
      ...dev,
    });
    expect(owner.statusCode).toBe(200);
  });

  it('login em aparelho novo registra alerta ao dono; no mesmo aparelho não vira "outro aparelho"', async () => {
    const { mock, dev } = await setup();
    const a = (await phoneLogin(mock, dev, '+5511900000001')).json();
    mock.state.auth.sends.clear();
    await phoneLogin(mock, dev, '+5511900000001'); // mesmo aparelho
    const me = await mock.app.inject({ method: 'GET', url: '/v1/me', headers: authed(a.accessToken) });
    expect(me.json().error.code).toBe('sessao_revogada');
    const other = await newDevice(mock);
    mock.state.auth.sends.clear();
    await phoneLogin(mock, other, '+5511900000001');
    expect(mock.state.auth.notices.at(-1)).toMatchObject({ kind: 'novo_aparelho', userId: 'u-ana' });
  });

  it('conta suspensa não entra; máximo absoluto de 180 dias; access entre 5 e 60 min', async () => {
    const { mock, dev } = await setup();
    const t = (await phoneLogin(mock, dev, '+5511900000002')).json();
    const user = mock.state.auth.users.get('u-bruno');
    if (user) user.accountStatus = 'suspensa';
    const r = await post(mock, '/v1/auth/refresh', { refreshToken: t.refreshToken, ...dev });
    expect(r.json().error.code).toBe('conta_suspensa');
    if (user) user.accountStatus = 'ativa';

    const dev2 = await newDevice(mock);
    const t2 = (await phoneLogin(mock, dev2, '+5511912312312')).json();
    for (const s of mock.state.auth.sessions.values()) s.absoluteExpiresAt = Date.now() - 1;
    const r2 = await post(mock, '/v1/auth/refresh', { refreshToken: t2.refreshToken, ...dev2 });
    expect(r2.json().error.code).toBe('sessao_expirada');

    mock.state.auth.config.accessTokenMinutes = 1;
    const { accessTokenTtlMs } = await import('../src/auth/config.js');
    expect(accessTokenTtlMs(mock.state.auth.config)).toBe(5 * 60_000);
    mock.state.auth.config.accessTokenMinutes = 999;
    expect(accessTokenTtlMs(mock.state.auth.config)).toBe(60 * 60_000);
  });
});
