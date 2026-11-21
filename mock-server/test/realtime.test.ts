import { afterEach, describe, expect, it } from 'vitest';
import WebSocket from 'ws';
import { buildApp, type MockServer } from '../src/app.js';

let server: MockServer | undefined;

async function start() {
  server = await buildApp();
  await server.app.listen({ port: 0, host: '127.0.0.1' });
  const addr = server.app.server.address();
  if (!addr || typeof addr === 'string') throw new Error('sem porta');
  return { mock: server, url: `ws://127.0.0.1:${addr.port}/v1/realtime` };
}

afterEach(async () => {
  await server?.app.close();
  server = undefined;
});

interface Client {
  ws: WebSocket;
  next(type?: string): Promise<Record<string, unknown> & { type: string; data: Record<string, unknown> }>;
  send(type: string, data?: object, id?: string): void;
  closed: Promise<number>;
}

function connect(url: string): Promise<Client> {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url);
    const queue: Array<Record<string, unknown> & { type: string; data: Record<string, unknown> }> = [];
    const waiters: Array<() => void> = [];
    ws.on('message', (raw) => {
      queue.push(JSON.parse(String(raw)));
      waiters.splice(0).forEach((w) => w());
    });
    const closed = new Promise<number>((r) => ws.on('close', (code) => r(code)));
    ws.on('error', reject);
    ws.on('open', () =>
      resolve({
        ws,
        closed,
        send: (type, data = {}, id = crypto.randomUUID()) =>
          ws.send(JSON.stringify({ v: 1, id, type, ts: new Date().toISOString(), data })),
        next: async (type) => {
          for (;;) {
            const i = queue.findIndex((m) => !type || m.type === type);
            const found = i >= 0 ? queue.splice(i, 1)[0] : undefined;
            if (found) return found;
            await new Promise<void>((r) => waiters.push(r));
          }
        },
      }),
    );
  });
}

async function authed(url: string, user = 'u-ana') {
  const c = await connect(url);
  c.send('auth', { token: `dev-token-${user}` }, 'a1');
  const ack = await c.next('ack');
  expect(ack.data).toEqual({ refId: 'a1', ok: true });
  return c;
}

describe('WebSocket /v1/realtime (TRV01)', () => {
  it('auth válido → ack; ping → pong no envelope v1', async () => {
    const { url } = await start();
    const c = await authed(url);
    c.send('ping');
    const pong = await c.next('pong');
    expect(pong).toMatchObject({ v: 1, type: 'pong', data: {} });
    expect(typeof pong.id).toBe('string');
    expect(Number.isNaN(Date.parse(String(pong.ts)))).toBe(false);
    c.ws.close();
  });

  it('token inválido → session.invalid e fechamento 4001', async () => {
    const { url } = await start();
    const c = await connect(url);
    c.send('auth', { token: 'dev-token-quem' });
    expect((await c.next('session.invalid')).data).toEqual({ reason: 'token_invalido' });
    expect(await c.closed).toBe(4001);
  });

  it('mensagem antes do auth → ack nao_autenticado', async () => {
    const { url } = await start();
    const c = await connect(url);
    c.send('ping', {}, 'p1');
    expect((await c.next('ack')).data).toEqual({ refId: 'p1', ok: false, error: 'nao_autenticado' });
    c.ws.close();
  });

  it('sem auth em 5 s fecha com 4000', async () => {
    const { url } = await start();
    const c = await connect(url);
    const t0 = Date.now();
    expect(await c.closed).toBe(4000);
    expect(Date.now() - t0).toBeGreaterThanOrEqual(4900);
  }, 8000);

  it('room.join recebe eventos da sala; room.leave para de receber; formato inválido → validacao', async () => {
    const { url, mock } = await start();
    const c = await authed(url);
    c.send('room.join', { room: 'live:abc' }, 'j1');
    expect((await c.next('ack')).data).toEqual({ refId: 'j1', ok: true });
    expect(mock.hub.emit({ room: 'live:abc' }, 'live.likes', { total: 1, burst: 1 })).toBe(1);
    expect((await c.next('live.likes')).data).toEqual({ total: 1, burst: 1 });
    c.send('room.leave', { room: 'live:abc' }, 'l1');
    await c.next('ack');
    expect(mock.hub.emit({ room: 'live:abc' }, 'live.likes', {})).toBe(0);
    c.send('room.join', { room: 'qualquer coisa' }, 'j2');
    expect((await c.next('ack')).data).toEqual({ refId: 'j2', ok: false, error: 'validacao' });
    c.ws.close();
  });

  it('sala que exige participação → sem_permissao; teto de salas → limite_excedido', async () => {
    const { url } = await start();
    const c = await authed(url);
    c.send('room.join', { room: 'conversation:alheia' }, 'x1');
    expect((await c.next('ack')).data).toEqual({ refId: 'x1', ok: false, error: 'sem_permissao' });
    for (let i = 0; i < 20; i++) {
      if (i % 10 === 0) await new Promise((r) => setTimeout(r, 1100)); // fica abaixo do limite de taxa
      c.send('room.join', { room: `live:l${i}` }, `r${i}`);
      await c.next('ack');
    }
    c.send('room.join', { room: 'live:extra' }, 'r21');
    expect((await c.next('ack')).data).toEqual({ refId: 'r21', ok: false, error: 'limite_excedido' });
    c.ws.close();
  });

  it('auth de novo na mesma conexão é recusado', async () => {
    const { url } = await start();
    const c = await authed(url);
    c.send('auth', { token: 'dev-token-u-bruno' }, 'a2');
    expect((await c.next('ack')).data).toEqual({ refId: 'a2', ok: false, error: 'conflito' });
    c.ws.close();
  });

  it('rajada acima do limite fecha com 4008', async () => {
    const { url } = await start();
    const c = await authed(url);
    for (let i = 0; i < 30; i++) c.send('ping');
    expect(await c.closed).toBe(4008);
  });

  it('segunda conexão da mesma conta substitui a primeira (RN-06)', async () => {
    const { url } = await start();
    const first = await authed(url);
    const second = await authed(url);
    expect((await first.next('session.replaced')).data).toHaveProperty('at');
    expect(await first.closed).toBe(4002);
    second.send('ping');
    await second.next('pong');
    second.ws.close();
  });

  it('cenário de manutenção chega como config.updated pelo WebSocket', async () => {
    const { url, mock } = await start();
    const c = await authed(url);
    await mock.app.inject({ method: 'POST', url: '/__mock/scenario/manutencao' });
    const ev = await c.next('config.updated');
    expect(ev.data).toMatchObject({ configVersion: 2, maintenance: { active: true } });
    c.ws.close();
  });

  it('JSON inválido é ignorado sem derrubar a conexão', async () => {
    const { url } = await start();
    const c = await authed(url);
    c.ws.send('isso não é json');
    c.send('ping');
    await c.next('pong');
    c.ws.close();
  });
});
