import { describe, expect, it, vi } from 'vitest';
import { buildApp } from '../src/app.js';
import type { Envelope } from '../src/realtime/envelope.js';
import type { Connection } from '../src/realtime/hub.js';

function fakeConn(userId: string | null, rooms: string[] = []) {
  const sent: Envelope[] = [];
  const c: Connection = {
    userId,
    sessionId: null,
    rooms: new Set(rooms),
    send: (e) => sent.push(e),
    close: vi.fn(),
  };
  return { c, sent };
}

describe('/__mock/scenario', () => {
  it('erro-500 faz /v1/* responder 500 até desligar', async () => {
    const { app } = await buildApp();
    await app.inject({ method: 'POST', url: '/__mock/scenario/erro-500' });
    const r1 = await app.inject({ method: 'GET', url: '/v1/config' });
    expect(r1.statusCode).toBe(500);
    expect(r1.json().error.code).toBe('erro_interno');
    await app.inject({ method: 'POST', url: '/__mock/scenario/erro-500', payload: { active: false } });
    expect((await app.inject({ method: 'GET', url: '/v1/config' })).statusCode).toBe(200);
  });

  it('manutencao ativa 503, sobe configVersion e emite config.updated só a autenticados', async () => {
    const { app, hub } = await buildApp();
    const logged = fakeConn('u-ana');
    const anon = fakeConn(null);
    hub.add(logged.c);
    hub.add(anon.c);
    const res = await app.inject({ method: 'POST', url: '/__mock/scenario/manutencao' });
    expect(res.json()).toEqual({ scenario: 'manutencao', active: true });
    expect((await app.inject({ method: 'GET', url: '/v1/x' })).statusCode).toBe(503);
    const cfg = (await app.inject({ method: 'GET', url: '/v1/config' })).json();
    expect(cfg.configVersion).toBe(2);
    expect(logged.sent).toHaveLength(1);
    expect(logged.sent[0]).toMatchObject({
      v: 1,
      type: 'config.updated',
      data: { configVersion: 2, maintenance: { active: true, retryAfterSeconds: 300 } },
    });
    expect(anon.sent).toHaveLength(0);
  });

  it('versao-minima força 99.0.0 e volta ao original ao desligar', async () => {
    const { app, state } = await buildApp();
    await app.inject({ method: 'POST', url: '/__mock/scenario/versao-minima' });
    expect(state.config.minAppVersion).toBe('99.0.0');
    const r = await app.inject({ method: 'GET', url: '/v1/x', headers: { 'x-app-version': '1.0.0' } });
    expect(r.statusCode).toBe(426);
    await app.inject({ method: 'POST', url: '/__mock/scenario/versao-minima', payload: { active: false } });
    expect(state.config.minAppVersion).toBe('0.1.0');
  });

  it('cenário desconhecido responde 404', async () => {
    const { app } = await buildApp();
    const r = await app.inject({ method: 'POST', url: '/__mock/scenario/nao-existe' });
    expect(r.statusCode).toBe(404);
    expect(r.json().error.code).toBe('nao_encontrado');
  });

  it('rede-lenta atrasa as respostas', async () => {
    vi.useFakeTimers({ toFake: ['setTimeout'] });
    try {
      const { app } = await buildApp();
      await app.inject({ method: 'POST', url: '/__mock/scenario/rede-lenta' });
      let done = false;
      const p = app.inject({ method: 'GET', url: '/v1/config' }).then((r) => {
        done = true;
        return r;
      });
      await vi.advanceTimersByTimeAsync(2900);
      expect(done).toBe(false);
      await vi.advanceTimersByTimeAsync(200);
      expect((await p).statusCode).toBe(200);
    } finally {
      vi.useRealTimers();
    }
  });
});

describe('/__mock/reset', () => {
  it('zera cenários, restaura estado e fecha conexões', async () => {
    const mock = await buildApp();
    const conn = fakeConn('u-ana');
    mock.hub.add(conn.c);
    await mock.app.inject({ method: 'POST', url: '/__mock/scenario/erro-500' });
    const r = await mock.app.inject({ method: 'POST', url: '/__mock/reset' });
    expect(r.statusCode).toBe(204);
    expect(mock.state.scenarios.size).toBe(0);
    expect(mock.state.config.configVersion).toBe(2); // só cresce
    expect(conn.c.close).toHaveBeenCalledWith(1001, 'mock reset');
    expect((await mock.app.inject({ method: 'GET', url: '/v1/config' })).statusCode).toBe(200);
  });
});

describe('/__mock/emit', () => {
  it('entrega evento do catálogo para a sala', async () => {
    const { app, hub } = await buildApp();
    const inRoom = fakeConn('u-ana', ['live:1']);
    const outside = fakeConn('u-bruno');
    hub.add(inRoom.c);
    hub.add(outside.c);
    const r = await app.inject({
      method: 'POST',
      url: '/__mock/emit',
      payload: { type: 'live.chat.message', data: { message: { text: 'oi' } }, target: { room: 'live:1' } },
    });
    expect(r.json()).toEqual({ delivered: 1 });
    expect(inRoom.sent[0]?.type).toBe('live.chat.message');
    expect(outside.sent).toHaveLength(0);
  });

  it('recusa tipo fora do catálogo', async () => {
    const { app } = await buildApp();
    const r = await app.inject({
      method: 'POST',
      url: '/__mock/emit',
      payload: { type: 'inventado.agora', target: { all: true } },
    });
    expect(r.statusCode).toBe(400);
    expect(r.json().error.code).toBe('validacao');
  });

  it('valida o corpo', async () => {
    const { app } = await buildApp();
    const r = await app.inject({ method: 'POST', url: '/__mock/emit', payload: { type: 'pong' } });
    expect(r.statusCode).toBe(400);
  });
});

describe('cenário entrada-desligada', () => {
  it('desliga os métodos de login e volta ao original', async () => {
    const { app, state } = await buildApp();
    await app.inject({ method: 'POST', url: '/__mock/scenario/entrada-desligada' });
    const flags = (await app.inject({ method: 'GET', url: '/v1/config' })).json().flags;
    expect([flags.loginPhone, flags.loginEmail, flags.loginGoogle]).toEqual([false, false, false]);
    expect(flags.pk).toBe(true);
    await app.inject({
      method: 'POST',
      url: '/__mock/scenario/entrada-desligada',
      payload: { active: false },
    });
    expect(state.config.flags.loginPhone).toBe(true);
  });
});
