import { defaultAuthConfig, type AuthConfig } from './config.js';

// Entidades de autenticação em memória (DATABASE.md: Usuario parcial, MetodoLogin,
// CodigoVerificacao, Sessao, AceiteTermos). Segredos sempre como hash.
export type AccountStatus = 'ativa' | 'suspensa' | 'banida';

export interface AuthUser {
  id: string;
  accountStatus: AccountStatus;
  needsProfile: boolean;
  createdAt: string;
}

export interface LoginMethod {
  userId: string;
  type: 'telefone' | 'email' | 'google';
  identifier: string; // E.164 / e-mail normalizado / sub
  passwordHash: string | null;
  verifiedAt: string | null;
}

export interface PendingSignup {
  email: string;
  passwordHash: string;
}

export interface VerificationCode {
  destination: string;
  purpose: 'login' | 'signup' | 'reset';
  codeHash: string;
  attempts: number;
  expiresAt: number;
  usedAt: number | null;
}

export type RevokeReason =
  'logout' | 'outro_aparelho' | 'senha_trocada' | 'reuso_refresh' | 'expirada' | 'conta_bloqueada';

export interface AuthSession {
  id: string;
  userId: string;
  deviceId: string;
  refreshHash: string;
  previousRefreshHash: string | null;
  rotatedAt: number | null;
  createdAt: number;
  lastUsedAt: number;
  absoluteExpiresAt: number;
  revokedAt: number | null;
  revokeReason: RevokeReason | null;
}

export interface TermsAcceptance {
  userId: string;
  document: 'terms' | 'privacy' | 'guidelines';
  version: number;
  acceptedAt: string;
  deviceId: string | null;
}

export interface Notice {
  userId: string | null;
  destination: string | null;
  kind: 'ja_tem_conta' | 'novo_aparelho' | 'sessao_revogada';
  at: string;
}

export interface AuthStore {
  config: AuthConfig;
  users: Map<string, AuthUser>;
  methods: LoginMethod[];
  pendingSignups: Map<string, PendingSignup>;
  codes: Map<string, VerificationCode>; // chave: purpose|destination
  sends: Map<string, number[]>; // envios por destino (RN-02)
  sessions: Map<string, AuthSession>;
  acceptances: TermsAcceptance[];
  failures: Map<string, { count: number; lockedUntil: number }>; // força bruta
  usedAntibotTokens: Set<string>;
  notices: Notice[];
  lastCodes: Map<string, string>; // SÓ MOCK: último código em texto por destino (outbox)
}

export function createAuthStore(): AuthStore {
  return {
    config: defaultAuthConfig(),
    users: new Map(),
    methods: [],
    pendingSignups: new Map(),
    codes: new Map(),
    sends: new Map(),
    sessions: new Map(),
    acceptances: [],
    failures: new Map(),
    usedAntibotTokens: new Set(),
    notices: [],
    lastCodes: new Map(),
  };
}
