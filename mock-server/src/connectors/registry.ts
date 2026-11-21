import { fakeFor, type FakeOutbox } from './fakes.js';
import {
  connectorTypes,
  type AgeVerificationConnector,
  type AnyConnector,
  type ConnectorType,
  type SmsWhatsappConnector,
} from './types.js';

/** IntegracaoProvedor (DATABASE.md) — Fase 0: só tipo, provedor e ativo; sem credenciais. */
export interface IntegracaoProvedor {
  type: ConnectorType;
  provider: string;
  active: boolean;
}

export function defaultIntegrations(): IntegracaoProvedor[] {
  return connectorTypes.map((type) => ({ type, provider: 'fake', active: true }));
}

type Factory = (type: ConnectorType, outbox: FakeOutbox) => AnyConnector;

/** Escolhe a implementação de cada tipo a partir da IntegracaoProvedor configurada. */
export class ConnectorRegistry {
  private readonly factories = new Map<string, Factory>([['fake', fakeFor]]);
  private readonly cache = new Map<ConnectorType, AnyConnector>();
  readonly outbox: FakeOutbox = { sms: [] };

  constructor(private readonly integrations: () => IntegracaoProvedor[]) {}

  /** Retorna null quando o tipo está desligado (ex.: verificação de idade desligada pelo comprador). */
  get(type: ConnectorType): AnyConnector | null {
    const cfg = this.integrations().find((i) => i.type === type);
    if (!cfg?.active) return null;
    const factory = this.factories.get(cfg.provider);
    if (!factory) throw new Error(`provedor desconhecido para ${type}: ${cfg.provider}`);
    const cached = this.cache.get(type);
    if (cached && cached.provider === cfg.provider) return cached;
    const c = factory(type, this.outbox);
    this.cache.set(type, c);
    return c;
  }

  sms(): SmsWhatsappConnector | null {
    return this.get('sms_whatsapp') as SmsWhatsappConnector | null;
  }

  ageVerification(): AgeVerificationConnector | null {
    return this.get('verificacao_idade') as AgeVerificationConnector | null;
  }
}
