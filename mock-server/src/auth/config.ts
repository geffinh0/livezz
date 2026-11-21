// Parâmetros de autenticação do lado do SERVIDOR (não vão no GET /config público).
// Configuráveis pelo comprador no painel (ADR 0007); aqui os padrões.
// Fontes: RN-02, RN-03, Q-50, Q-54, ADR 0012.
export interface AuthConfig {
  accessTokenMinutes: number; // 5..60
  accessTokenSecondsOverride: number | null; // cenário token-expira-rapido
  sessionIdleDays: number; // Q-50
  sessionMaxDays: number; // Q-54
  refreshReuseGraceSeconds: number; // ADR 0012
  codeTtlSeconds: number; // RN-02
  codeResendSeconds: number; // RN-02
  codeMaxSendsPerHour: number; // RN-02
  codeMaxAttempts: number; // RN-02
  loginMaxFailures: number; // por conta+aparelho, antes do bloqueio progressivo
  ipMaxFailures: number; // por IP (alto: IP compartilhado/CGNAT é comum no Brasil)
  loginLockBaseSeconds: number;
  codeSendsPerIpPerHour: number;
  devicesPerIpPerHour: number;
}

export function defaultAuthConfig(): AuthConfig {
  return {
    accessTokenMinutes: 15,
    accessTokenSecondsOverride: null,
    sessionIdleDays: 30,
    sessionMaxDays: 180,
    refreshReuseGraceSeconds: 10,
    codeTtlSeconds: 60,
    codeResendSeconds: 60,
    codeMaxSendsPerHour: 5,
    codeMaxAttempts: 5,
    loginMaxFailures: 5,
    ipMaxFailures: 50,
    loginLockBaseSeconds: 60,
    codeSendsPerIpPerHour: 60,
    devicesPerIpPerHour: 60,
  };
}

export function accessTokenTtlMs(c: AuthConfig): number {
  if (c.accessTokenSecondsOverride !== null) return c.accessTokenSecondsOverride * 1000;
  const minutes = Math.min(60, Math.max(5, c.accessTokenMinutes)); // piso e teto (segurança)
  return minutes * 60_000;
}

// RN-03: lista curta de senhas comuns (o backend real usa uma lista grande).
export const commonPasswords = new Set([
  '12345678',
  '123456789',
  '1234567890',
  'password',
  'password1',
  'senha123',
  'senha1234',
  'qwerty123',
  'abc12345',
  'abcd1234',
  '11111111',
  '00000000',
  'iloveyou1',
  'admin123',
  'brasil123',
  'flamengo1',
]);

/** RN-03: 8+ caracteres, letras e números, fora da lista de comuns. Retorna as regras violadas. */
export function passwordProblems(password: string): string[] {
  const problems: string[] = [];
  if (password.length < 8) problems.push('min_length');
  if (!/[A-Za-z]/.test(password)) problems.push('letters');
  if (!/\d/.test(password)) problems.push('numbers');
  if (commonPasswords.has(password.toLowerCase())) problems.push('common');
  return problems;
}
