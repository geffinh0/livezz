import { describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';

describe('GET /v1/config (TRV04)', () => {
  it('devolve a config pública no formato do contrato', async () => {
    const { app } = await buildApp();
    const res = await app.inject({ method: 'GET', url: '/v1/config' });
    expect(res.statusCode).toBe(200);
    const c = res.json();
    expect(c).toMatchObject({
      configVersion: 1,
      minAppVersion: '0.1.0',
      maintenance: { active: false, retryAfterSeconds: null },
      discoverTabs: ['popular', 'nearby', 'new', 'pk', 'multi', 'calls'],
      allowedRegions: ['BR'],
    });
    expect(c.flags).toMatchObject({ loginPhone: true, luckyGift: false, ageVerification: true });
    expect(c.limits.chatMaxLength).toBe(200);
    expect(c.legalTexts.terms).toEqual({ version: 1, url: 'http://localhost:3002/legal/termos' });
    expect(Object.keys(c).sort()).toEqual(
      [
        'allowedRegions',
        'configVersion',
        'discoverTabs',
        'flags',
        'legalTexts',
        'limits',
        'maintenance',
        'minAppVersion',
        'region',
      ].sort(),
    );
  });

  it('não exige autenticação', async () => {
    const { app } = await buildApp();
    const res = await app.inject({ method: 'GET', url: '/v1/config', headers: { authorization: '' } });
    expect(res.statusCode).toBe(200);
  });
});

describe('versão mínima e manutenção (Convenções da API)', () => {
  it('426 para versão abaixo da mínima, exceto em /config', async () => {
    const { app, state } = await buildApp();
    state.config.minAppVersion = '2.0.0';
    const headers = { 'x-app-version': '1.9.9' };
    const other = await app.inject({ method: 'GET', url: '/v1/qualquer', headers });
    expect(other.statusCode).toBe(426);
    expect(other.json().error.code).toBe('atualizacao_obrigatoria');
    const cfg = await app.inject({ method: 'GET', url: '/v1/config', headers });
    expect(cfg.statusCode).toBe(200);
  });

  it('versão igual ou maior passa; sem header não bloqueia', async () => {
    const { app, state } = await buildApp();
    state.config.minAppVersion = '2.0.0';
    for (const v of ['2.0.0', '2.10.0', undefined]) {
      const res = await app.inject({
        method: 'GET',
        url: '/v1/qualquer',
        headers: v ? { 'x-app-version': v } : {},
      });
      expect(res.statusCode).toBe(404);
    }
  });

  it('503 com Retry-After em manutenção, exceto em /config', async () => {
    const { app, state } = await buildApp();
    state.config.maintenance = { active: true, retryAfterSeconds: 300 };
    const other = await app.inject({ method: 'GET', url: '/v1/qualquer' });
    expect(other.statusCode).toBe(503);
    expect(other.headers['retry-after']).toBe('300');
    expect(other.json().error.code).toBe('manutencao');
    const cfg = await app.inject({ method: 'GET', url: '/v1/config' });
    expect(cfg.statusCode).toBe(200);
    expect(cfg.json().maintenance.active).toBe(true);
  });
});
