import { describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';
import { connectorTypes } from '../src/connectors/types.js';

describe('conectores (TRV13)', () => {
  it('todo tipo tem fake ativo que passa no teste de conexão', async () => {
    const { connectors } = await buildApp();
    for (const t of connectorTypes) {
      const c = connectors.get(t);
      expect(c?.type).toBe(t);
      expect(c?.provider).toBe('fake');
      await expect(c?.testConnection()).resolves.toEqual({ ok: true });
    }
  });

  it('sms fake registra o envio no outbox', async () => {
    const { connectors } = await buildApp();
    const r = await connectors.sms()?.sendCode({
      channel: 'whatsapp',
      phoneE164: '+5511900000000',
      code: '123456',
      locale: 'pt-BR',
    });
    expect(r?.delivered).toBe(true);
    expect(connectors.outbox.sms).toEqual([
      { channel: 'whatsapp', phoneE164: '+5511900000000', code: '123456' },
    ]);
  });

  it('verificação de idade fake aprova; sessão desconhecida fica pendente', async () => {
    const { connectors } = await buildApp();
    const av = connectors.ageVerification();
    const s = await av?.startSession({ userId: 'u-ana', method: 'estimativa_facial' });
    expect(s?.redirectUrl).toContain(s?.sessionId);
    await expect(av?.getResult(s?.sessionId ?? '')).resolves.toEqual({ status: 'aprovada', adult: true });
    await expect(av?.getResult('x')).resolves.toEqual({ status: 'pendente', adult: null });
  });

  it('tipo desligado pelo comprador devolve null', async () => {
    const { connectors, state } = await buildApp();
    const i = state.integrations.find((x) => x.type === 'verificacao_idade');
    if (i) i.active = false;
    expect(connectors.ageVerification()).toBeNull();
  });

  it('provedor desconhecido é erro de configuração', async () => {
    const { connectors, state } = await buildApp();
    const i = state.integrations.find((x) => x.type === 'traducao');
    if (i) i.provider = 'inexistente';
    expect(() => connectors.get('traducao')).toThrow(/provedor desconhecido/);
  });
});
