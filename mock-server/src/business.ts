// Valores de negócio PROVISÓRIOS, num lugar só (regra do mock-server).
// Todos são configuráveis pelo comprador no painel (ADR 0007); aqui só os padrões iniciais.
// Fonte: docs/REGRAS-DE-NEGOCIO.md.
export const defaultLimits = {
  chatMaxLength: 200, // RN-40
  chatMessagesPerSecond: 1, // RN-40
  pkInviteTtlSeconds: 15, // RN-55
  stageInviteTtlSeconds: 15, // RN-55
  callInviteTtlSeconds: 30, // RN-55
} as const;

export const maintenanceRetryAfterSeconds = 300;
export const slowNetworkDelayMs = 3000;
export const forcedMinAppVersion = '99.0.0';
export const realtimeAuthTimeoutMs = 5000;

// Proteções do canal de tempo real (valores do mock; o backend real terá os seus).
export const realtimeMaxRoomsPerConnection = 20;
export const realtimeMaxMessagesPerSecond = 20;
