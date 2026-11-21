import { describe, expect, it } from 'vitest';
import { buildApp, type MockServer } from '../src/app.js';

// Cadastro inicial (plano 1c): ENT08, ENT10, ENT11, ENT12, CFG14.
const devBody = { platform: 'web', appVersion: '0.1.0', locale: 'pt-BR' };

async function device(mock: MockServer) {
  return (await mock.app.inject({ method: 'POST', url: '/v1/devices', payload: devBody })).json() as {
    deviceId: string;
    deviceSecret: string;
  };
}

async function phoneLogin(mock: MockServer, dev: object, phone: string) {
  mock.state.auth.sends.clear();
  mock.state.auth.ipHits.clear();
  await mock.app.inject({
    method: 'POST',
    url: '/v1/auth/code/send',
    payload: { channel: 'sms', destination: phone, purpose: 'login' },
  });
  const code = (
    await mock.app.inject({ method: 'GET', url: `/__mock/outbox?destination=${encodeURIComponent(phone)}` })
  ).json().code;
  return mock.app.inject({
    method: 'POST',
    url: '/v1/auth/code/verify',
    payload: { destination: phone, code, purpose: 'login', ...dev },
  });
}

/** Conta nova (telefone) com termos aceitos, ainda sem cadastro. */
async function newAccount(mock: MockServer, phone = '+5511977770001') {
  const dev = await device(mock);
  const t = (await phoneLogin(mock, dev, phone)).json() as {
    accessToken: string;
    refreshToken: string;
    user: { id: string };
  };
  for (const document of ['terms', 'privacy', 'guidelines']) {
    await req(mock, 'POST', '/v1/me/terms/accept', t.accessToken, { document, version: 1 });
  }
  return { dev, ...t };
}

function req(
  mock: MockServer,
  method: 'GET' | 'POST' | 'PATCH',
  url: string,
  token: string,
  payload?: object,
) {
  return mock.app.inject({
    method,
    url,
    headers: { authorization: `Bearer ${token}` },
    ...(payload ? { payload } : {}),
  });
}

const adult = { displayName: 'Nova Pessoa', birthDate: '1990-04-12' };

describe('perfil e portão de cadastro (ENT08)', () => {
  it('conta nova: passos pendentes e portão; conta semeada já completa', async () => {
    const mock = await buildApp();
    const t = await newAccount(mock);
    const me = (await req(mock, 'GET', '/v1/me', t.accessToken)).json();
    expect(me).toMatchObject({
      needsProfile: true,
      pendingSteps: ['profile', 'username', 'interests'],
      ageStatus: 'nao_verificada',
      birthDateSet: false,
      language: 'pt-BR',
    });
    expect((await req(mock, 'GET', '/v1/interests', t.accessToken)).json().error.code).toBe(
      'cadastro_pendente',
    );
    const ok = await req(mock, 'PATCH', '/v1/me', t.accessToken, { ...adult, gender: 'mulher' });
    expect(ok.statusCode).toBe(200);
    expect(ok.json()).toMatchObject({
      displayName: 'Nova Pessoa',
      gender: 'mulher',
      pendingSteps: ['username', 'interests'],
    });
    expect((await req(mock, 'GET', '/v1/interests', t.accessToken)).statusCode).toBe(200);
  });

  it('validação: campo extra, data inválida/futura, nome proibido ou curto', async () => {
    const mock = await buildApp();
    const t = await newAccount(mock);
    const bad = async (body: object) =>
      (await req(mock, 'PATCH', '/v1/me', t.accessToken, body)).json().error;
    // Campo fora da lista é ignorado (não muda nada): compatível com versões futuras do app.
    const ignored = await req(mock, 'PATCH', '/v1/me', t.accessToken, {
      accountStatus: 'ativa',
      ageStatus: 'verificada',
    });
    expect(ignored.json()).toMatchObject({ accountStatus: 'ativa', ageStatus: 'nao_verificada' });
    expect(await bad({ birthDate: '1990-02-30' })).toMatchObject({
      code: 'validacao',
      details: { field: 'birthDate' },
    });
    expect(await bad({ birthDate: '2999-01-01' })).toMatchObject({
      code: 'validacao',
      details: { field: 'birthDate' },
    });
    expect(await bad({ birthDate: '1800-01-01' })).toMatchObject({
      code: 'validacao',
      details: { field: 'birthDate' },
    });
    expect(await bad({ displayName: 'A' })).toMatchObject({
      details: { field: 'displayName', reason: 'tamanho' },
    });
    expect(await bad({ displayName: 'Sou idiota' })).toMatchObject({ details: { reason: 'proibido' } });
    expect(await bad({ gender: 'outro' })).toMatchObject({ code: 'validacao' });
  });

  it('data de nascimento só uma vez (RN-01), inclusive com dois pedidos ao mesmo tempo', async () => {
    const mock = await buildApp();
    const t = await newAccount(mock);
    const [a, b] = await Promise.all([
      req(mock, 'PATCH', '/v1/me', t.accessToken, { ...adult, birthDate: '1990-01-01' }),
      req(mock, 'PATCH', '/v1/me', t.accessToken, { ...adult, birthDate: '1991-01-01' }),
    ]);
    expect([a.statusCode, b.statusCode].sort()).toEqual([200, 409]);
    const conflict = [a, b].find((r) => r.statusCode === 409);
    expect(conflict?.json().error.details).toEqual({ reason: 'data_imutavel' });
    // Reenviar a mesma data é aceito (idempotente).
    const same = mock.state.auth.users.get(t.user.id)?.birthDate;
    expect((await req(mock, 'PATCH', '/v1/me', t.accessToken, { birthDate: same })).statusCode).toBe(200);
  });

  it('idioma (CFG14) e gênero só no GET /me', async () => {
    const mock = await buildApp();
    const t = await newAccount(mock);
    await req(mock, 'PATCH', '/v1/me', t.accessToken, { ...adult, gender: 'homem', language: 'en' });
    expect((await req(mock, 'GET', '/v1/me', t.accessToken)).json()).toMatchObject({
      language: 'en',
      gender: 'homem',
    });
    const login = await phoneLogin(mock, await device(mock), '+5511977770001');
    expect(JSON.stringify(login.json())).not.toMatch(/gender|homem|birth/);
  });
});

describe('bloqueio de menor (ENT10)', () => {
  it('data de menor: 403, conta congelada, sessão revogada e aparelho marcado de uma vez', async () => {
    const mock = await buildApp();
    const t = await newAccount(mock);
    const r = await req(mock, 'PATCH', '/v1/me', t.accessToken, {
      displayName: 'Jovem',
      birthDate: '2015-06-01',
    });
    expect(r.statusCode).toBe(403);
    expect(r.json().error.code).toBe('menor_de_idade');
    const protocol = r.json().error.details.protocol as string;
    expect(protocol).toMatch(/^P-[0-9A-Z_-]{8}$/);
    expect(protocol).not.toContain(t.user.id);
    expect(mock.state.auth.users.get(t.user.id)).toMatchObject({
      accountStatus: 'congelada',
      ageStatus: 'menor_bloqueado',
    });
    // Mesmo token: barrado com o motivo real.
    expect((await req(mock, 'GET', '/v1/me', t.accessToken)).json().error.code).toBe('menor_de_idade');
    // Renovar a sessão: barrado.
    const refresh = await mock.app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: t.refreshToken, ...t.dev },
    });
    expect(refresh.json().error.code).toBe('menor_de_idade');
    // Aparelho marcado: avisa no registro e não entra com outra conta.
    const again = await mock.app.inject({
      method: 'POST',
      url: '/v1/devices',
      payload: { ...devBody, ...t.dev },
    });
    expect(again.json()).toMatchObject({ blocked: true, protocol });
    expect((await phoneLogin(mock, t.dev, '+5511977770099')).json().error.code).toBe('menor_de_idade');
    expect([...mock.state.auth.users.values()].filter((u) => u.id.startsWith('u_'))).toHaveLength(1); // sem conta órfã
    // Outro aparelho, mesmo telefone: a conta continua congelada.
    expect((await phoneLogin(mock, await device(mock), '+5511977770001')).json().error.code).toBe(
      'menor_de_idade',
    );
  });

  it('sinal da loja só restringe: menor bloqueia; não compartilhado não libera nem bloqueia', async () => {
    const mock = await buildApp();
    const a = await newAccount(mock, '+5511977770002');
    const blocked = await req(mock, 'PATCH', '/v1/me', a.accessToken, {
      ...adult,
      storeAgeSignal: { status: 'shared', ageLower: 13, ageUpper: 15 },
    });
    expect(blocked.json().error.code).toBe('menor_de_idade');
    const b = await newAccount(mock, '+5511977770003');
    const fine = await req(mock, 'PATCH', '/v1/me', b.accessToken, {
      ...adult,
      storeAgeSignal: { status: 'not_shared', ageLower: null, ageUpper: null },
    });
    expect(fine.statusCode).toBe(200);
    const c = await newAccount(mock, '+5511977770004');
    const adultSignalMinorDate = await req(mock, 'PATCH', '/v1/me', c.accessToken, {
      displayName: 'Teste',
      birthDate: '2012-01-01',
      storeAgeSignal: { status: 'shared', ageLower: 18, ageUpper: null },
    });
    expect(adultSignalMinorDate.json().error.code).toBe('menor_de_idade');
  });

  it('a equipe libera a conta e o aparelho depois da revisão', async () => {
    const mock = await buildApp();
    const t = await newAccount(mock);
    await req(mock, 'PATCH', '/v1/me', t.accessToken, { displayName: 'Jovem', birthDate: '2015-06-01' });
    const un = await mock.app.inject({
      method: 'POST',
      url: '/__mock/minor/unfreeze',
      payload: { userId: t.user.id },
    });
    expect(un.statusCode).toBe(204);
    expect((await phoneLogin(mock, t.dev, '+5511977770001')).statusCode).toBe(200);
  });
});

describe('@ (ENT11)', () => {
  it('disponibilidade: formato, ocupado e reservado com sugestões; grava e bloqueia corrida', async () => {
    const mock = await buildApp();
    const t = await newAccount(mock);
    await req(mock, 'PATCH', '/v1/me', t.accessToken, { displayName: 'Ana Lúcia', birthDate: '1990-04-12' });
    const check = async (u: string) =>
      (await req(mock, 'GET', `/v1/usernames/${encodeURIComponent(u)}/availability`, t.accessToken)).json();
    expect(await check('a.')).toMatchObject({ available: false, reason: 'formato' });
    expect(await check('ana.teste')).toMatchObject({ available: false, reason: 'ocupado' });
    const reserved = await check('adm1n');
    expect(reserved).toMatchObject({ available: false, reason: 'reservado' });
    expect(reserved.suggestions[0]).toBe('ana.lucia');
    expect(await check('liveapp.oficial')).toMatchObject({ reason: 'reservado' });
    expect(await check('Ana.Lucia')).toEqual({ available: true, suggestions: [] });

    const set = await req(mock, 'POST', '/v1/me/username', t.accessToken, { username: 'ana.lucia' });
    expect(set.json()).toEqual({ username: 'ana.lucia' });
    const other = await newAccount(mock, '+5511977770005');
    await req(mock, 'PATCH', '/v1/me', other.accessToken, adult);
    const taken = await req(mock, 'POST', '/v1/me/username', other.accessToken, { username: 'ana.lucia' });
    expect(taken.statusCode).toBe(409);
    expect(taken.json().error).toMatchObject({
      code: 'username_indisponivel',
      details: { reason: 'ocupado' },
    });
  });

  it('consulta exige login e tem limite por conta', async () => {
    const mock = await buildApp();
    expect((await mock.app.inject({ method: 'GET', url: '/v1/usernames/ana/availability' })).statusCode).toBe(
      401,
    );
    const t = await newAccount(mock);
    mock.state.auth.config.usernameChecksPerUserPerMinute = 2;
    await req(mock, 'GET', '/v1/usernames/aaa/availability', t.accessToken);
    await req(mock, 'GET', '/v1/usernames/bbb/availability', t.accessToken);
    const third = await req(mock, 'GET', '/v1/usernames/ccc/availability', t.accessToken);
    expect(third.statusCode).toBe(429);
  });
});

describe('interesses (ENT12)', () => {
  it('categorias no idioma; salvar, pular e validação', async () => {
    const mock = await buildApp();
    const t = await newAccount(mock);
    await req(mock, 'PATCH', '/v1/me', t.accessToken, adult);
    const pt = (await req(mock, 'GET', '/v1/interests', t.accessToken)).json();
    expect(pt.items[0]).toEqual({ id: 'musica', name: 'Música' });
    const en = await mock.app.inject({
      method: 'GET',
      url: '/v1/interests',
      headers: { authorization: `Bearer ${t.accessToken}`, 'accept-language': 'en' },
    });
    expect(en.json().items[0]).toEqual({ id: 'musica', name: 'Music' });
    const bad = async (ids: string[]) =>
      (await req(mock, 'POST', '/v1/me/interests', t.accessToken, { ids })).statusCode;
    expect(await bad(['musica', 'musica'])).toBe(400);
    expect(await bad(['nao-existe'])).toBe(400);
    expect(await bad(Array.from({ length: 11 }, () => 'musica'))).toBe(400);
    expect(await bad([])).toBe(204); // pular
    const me = (await req(mock, 'GET', '/v1/me', t.accessToken)).json();
    expect(me.pendingSteps).toEqual(['username']);
  });
});

describe('logs sem dados de idade e gênero', () => {
  it('não registram data de nascimento, gênero nem sinal da loja', async () => {
    const lines: string[] = [];
    const mock = await buildApp({ logStream: { write: (m) => void lines.push(m) } });
    const t = await newAccount(mock);
    await req(mock, 'PATCH', '/v1/me', t.accessToken, {
      displayName: 'Pessoa',
      birthDate: '1987-03-09',
      gender: 'nao_binario',
      storeAgeSignal: { status: 'shared', ageLower: 18, ageUpper: null },
    });
    const all = lines.join('\n');
    expect(all).not.toContain('1987-03-09');
    expect(all).not.toContain('nao_binario');
  });
});
