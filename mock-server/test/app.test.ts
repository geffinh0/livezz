import { describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';

describe('mock-server base', () => {
  it('rota desconhecida responde 404 no formato do contrato', async () => {
    const { app } = await buildApp();
    const res = await app.inject({ method: 'GET', url: '/v1/nao-existe' });
    expect(res.statusCode).toBe(404);
    const body = res.json();
    expect(body.error.code).toBe('nao_encontrado');
    expect(typeof body.error.requestId).toBe('string');
    expect(body.error.message).toBe('Não encontrado.');
  });

  it('mensagem segue o Accept-Language', async () => {
    const { app } = await buildApp();
    const res = await app.inject({ method: 'GET', url: '/x', headers: { 'accept-language': 'en' } });
    expect(res.json().error.message).toBe('Not found.');
  });

  it('estado inicial vem do tenant e nunca inclui jogos', async () => {
    const { state } = await buildApp();
    expect(state.config.flags.luckyGift).toBe(false);
    expect(state.config.flags.pk).toBe(true);
    expect('games' in state.config.flags).toBe(false);
    expect(state.users.size).toBe(3);
  });
});
