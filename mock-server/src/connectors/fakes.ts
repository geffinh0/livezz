import { randomUUID } from 'node:crypto';
import type {
  AgeVerificationConnector,
  AnyConnector,
  BaseConnector,
  ConnectorType,
  EmailConnector,
  SmsWhatsappConnector,
} from './types.js';

/** Registro de mensagens "enviadas" pelo fake de SMS, para os testes e cenários lerem o código. */
export interface FakeOutbox {
  sms: Array<{ channel: 'sms' | 'whatsapp'; phoneE164: string; code: string }>;
  email: Array<{ email: string; code?: string; kind?: string }>;
}

export function fakeEmail(outbox: FakeOutbox): EmailConnector {
  return {
    type: 'email',
    provider: 'fake',
    testConnection: async () => ({ ok: true }),
    sendCode: async ({ email, code }) => {
      outbox.email.push({ email, code });
      return { delivered: true };
    },
    sendNotice: async ({ email, kind }) => {
      outbox.email.push({ email, kind });
      return { delivered: true };
    },
  };
}

export function fakeSms(outbox: FakeOutbox): SmsWhatsappConnector {
  return {
    type: 'sms_whatsapp',
    provider: 'fake',
    testConnection: async () => ({ ok: true }),
    sendCode: async ({ channel, phoneE164, code }) => {
      outbox.sms.push({ channel, phoneE164, code });
      return { delivered: true, providerMessageId: randomUUID() };
    },
  };
}

/** Resultado controlado por cenário (padrão: aprovada). */
export function fakeAgeVerification(
  outcome: () => 'aprovada' | 'reprovada' = () => 'aprovada',
): AgeVerificationConnector {
  const sessions = new Map<string, 'aprovada' | 'reprovada'>();
  return {
    type: 'verificacao_idade',
    provider: 'fake',
    testConnection: async () => ({ ok: true }),
    startSession: async () => {
      const sessionId = randomUUID();
      sessions.set(sessionId, outcome());
      return { sessionId, redirectUrl: `http://localhost:3000/__mock/age/${sessionId}` };
    },
    getResult: async (id) => {
      const s = sessions.get(id);
      if (!s) return { status: 'pendente', adult: null };
      return { status: s, adult: s === 'aprovada' };
    },
  };
}

export function fakeBase(type: ConnectorType): BaseConnector {
  return { type, provider: 'fake', testConnection: async () => ({ ok: true }) };
}

export function fakeFor(type: ConnectorType, outbox: FakeOutbox): AnyConnector {
  if (type === 'sms_whatsapp') return fakeSms(outbox);
  if (type === 'verificacao_idade') return fakeAgeVerification();
  if (type === 'email') return fakeEmail(outbox);
  return fakeBase(type);
}
