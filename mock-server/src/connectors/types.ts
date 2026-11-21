// Conectores de provedores (ADR 0007, TRV13). O comprador escolhe o provedor no painel (ADM19);
// o app nunca fala com provedores que exigem segredo. Aqui só as interfaces + fakes do mock.

export const connectorTypes = [
  'pagamento_loja_alternativa',
  'pagamento_web',
  'repasse_saque',
  'sms_whatsapp',
  'verificacao_idade',
  'traducao',
  'moderacao_midia',
  'antibot',
  'push',
  'analytics',
] as const;
export type ConnectorType = (typeof connectorTypes)[number];

/** Comum a todos: o painel usa para "testar conexão". */
export interface BaseConnector {
  readonly type: ConnectorType;
  readonly provider: string;
  testConnection(): Promise<{ ok: boolean; message?: string }>;
}

// Contrato detalhado só onde a Fase 1 já vai usar (revisão do arquiteto, item 6).
// Os demais ganham métodos quando a feature dona chegar.

/** sms_whatsapp (ENT04, RN-02). O código é gerado pelo servidor; o conector só entrega. */
export interface SmsWhatsappConnector extends BaseConnector {
  readonly type: 'sms_whatsapp';
  sendCode(input: {
    channel: 'sms' | 'whatsapp';
    phoneE164: string;
    code: string;
    locale: 'pt-BR' | 'en';
  }): Promise<{ delivered: boolean; providerMessageId?: string }>;
}

/** verificacao_idade (ENT09, RN-01). Resultado chega por webhook no backend real; no fake, na hora. */
export interface AgeVerificationConnector extends BaseConnector {
  readonly type: 'verificacao_idade';
  startSession(input: {
    userId: string;
    method: 'estimativa_facial' | 'documento';
  }): Promise<{ sessionId: string; redirectUrl: string }>;
  getResult(
    sessionId: string,
  ): Promise<{ status: 'pendente' | 'aprovada' | 'reprovada'; adult: boolean | null }>;
}

export type AnyConnector = BaseConnector | SmsWhatsappConnector | AgeVerificationConnector;
