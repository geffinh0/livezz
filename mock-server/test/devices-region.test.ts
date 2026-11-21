import { describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';

const body = { platform: 'android', appVersion: '0.1.0', locale: 'pt-BR' };

describe('POST /v1/devices (ENT01)', () => {
  it('cria com id gerado pelo servidor (201) e atualiza com o mesmo id (200)', async () => {
    const { app, state } = await buildApp();
    const r1 = await app.inject({ method: 'POST', url: '/v1/devices', payload: body });
    expect(r1.statusCode).toBe(201);
    const { deviceId } = r1.json();
    expect(deviceId).toMatch(/^[0-9a-f-]{36}$/);
    const r2 = await app.inject({
      method: 'POST',
      url: '/v1/devices',
      payload: { ...body, deviceId, appVersion: '0.2.0' },
    });
    expect(r2.statusCode).toBe(200);
    expect(r2.json()).toEqual({ deviceId });
    expect(state.devices.get(deviceId)?.appVersion).toBe('0.2.0');
    expect(state.devices.size).toBe(1);
  });

  it('campos desconhecidos são descartados (não guardados)', async () => {
    const { app, state } = await buildApp();
    const r = await app.inject({ method: 'POST', url: '/v1/devices', payload: { ...body, extra: 'x' } });
    expect(r.statusCode).toBe(201);
    expect(state.devices.get(r.json().deviceId)).not.toHaveProperty('extra');
  });

  it('id desconhecido ou forjado não é adotado', async () => {
    const { app, state } = await buildApp();
    const r = await app.inject({
      method: 'POST',
      url: '/v1/devices',
      payload: { ...body, deviceId: 'forjado' },
    });
    expect(r.statusCode).toBe(201);
    expect(r.json().deviceId).not.toBe('forjado');
    expect(state.devices.has('forjado')).toBe(false);
  });

  it('valida o corpo', async () => {
    const { app } = await buildApp();
    for (const payload of [
      { ...body, platform: 'tv' },
      { ...body, appVersion: 'x' },
      { ...body, extra: 1 },
    ]) {
      const r = await app.inject({ method: 'POST', url: '/v1/devices', payload });
      expect(r.statusCode).toBe(400);
      expect(r.json().error.code).toBe('validacao');
    }
  });
});

describe('região (ENT18)', () => {
  it('config informa a região calculada por requisição', async () => {
    const { app } = await buildApp();
    const br = await app.inject({ method: 'GET', url: '/v1/config' });
    expect(br.json().region).toEqual({ country: 'BR', allowed: true });
    const us = await app.inject({ method: 'GET', url: '/v1/config', headers: { 'x-mock-country': 'us' } });
    expect(us.statusCode).toBe(200);
    expect(us.json().region).toEqual({ country: 'US', allowed: false });
  });

  it('fora da região: demais rotas respondem 403 regiao_bloqueada', async () => {
    const { app } = await buildApp();
    const r = await app.inject({
      method: 'POST',
      url: '/v1/devices',
      payload: body,
      headers: { 'x-mock-country': 'PT' },
    });
    expect(r.statusCode).toBe(403);
    expect(r.json().error).toMatchObject({ code: 'regiao_bloqueada', details: { country: 'PT' } });
  });

  it('cenário regiao-bloqueada', async () => {
    const { app } = await buildApp();
    await app.inject({ method: 'POST', url: '/__mock/scenario/regiao-bloqueada' });
    expect((await app.inject({ method: 'GET', url: '/v1/config' })).json().region).toEqual({
      country: 'XX',
      allowed: false,
    });
    expect((await app.inject({ method: 'POST', url: '/v1/devices', payload: body })).statusCode).toBe(403);
    await app.inject({
      method: 'POST',
      url: '/__mock/scenario/regiao-bloqueada',
      payload: { active: false },
    });
    expect((await app.inject({ method: 'POST', url: '/v1/devices', payload: body })).statusCode).toBe(201);
  });
});
