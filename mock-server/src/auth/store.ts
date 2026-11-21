import { defaultAuthConfig, type AuthConfig } from './config.js';

// Entidades de autenticação em memória (DATABASE.md: Usuario parcial, MetodoLogin,
// CodigoVerificacao, Sessao, AceiteTermos). Segredos sempre como hash.
export type AccountStatus = 'ativa' | 'suspensa' | 'banida' | 'congelada';
export type AgeStatus = 'nao_verificada' | 'pendente' | 'verificada' | 'reprovada' | 'menor_bloqueado';
export type Gender = 'mulher' | 'homem' | 'nao_binario' | 'prefiro_nao_dizer';
export type Language = 'pt-BR' | 'en';

/** Sinal de idade da loja (Play Age Signals), como o app recebeu. Só restringe (Q-64). */
export interface StoreAgeSignal {
  status: 'shared' | 'not_shared' | 'verification_required' | 'unavailable';
  ageLower: number | null;
  ageUpper: number | null;
}

/** Usuario (DATABASE.md): conta + perfil do cadastro inicial (plano 1c). */
export interface AuthUser {
  id: string;
  accountStatus: AccountStatus;
  ageStatus: AgeStatus;
  displayName: string | null;
  username: string | null;
  /** Privado (Q-59): só aparece em GET /me. */
  gender: Gender | null;
  /** 🔒 AAAA-MM-DD, imutável depois de gravada (RN-01). */
  birthDate: string | null;
  /** null = ainda não respondeu; [] = pulou (ENT12). */
  interests: string[] | null;
  language: Language;
  storeAgeSignal: StoreAgeSignal | null;
  frozenAt: string | null;
  createdAt: string;
}

export type OnboardingStep = 'profile' | 'username' | 'interests';

/** Passos do cadastro que faltam (needsProfile = lista não vazia). */
export function pendingSteps(u: AuthUser): OnboardingStep[] {
  const steps: OnboardingStep[] = [];
  if (!u.displayName || !u.birthDate) steps.push('profile');
  if (!u.username) steps.push('username');
  if (u.interests === null) steps.push('interests');
  return steps;
}

/** IdentificadorBloqueado (Q-65): HMAC do telefone/e-mail/Google de conta congelada. */
export interface BlockedIdentifier {
  type: 'telefone' | 'email' | 'google';
  userId: string;
  at: string;
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
  /** Cadastro: hash da senha de QUEM pediu este código (confirmação exige a mesma senha). */
  passwordHash: string | null;
}

export type RevokeReason =
  | 'logout'
  | 'outro_aparelho'
  | 'senha_trocada'
  | 'reuso_refresh'
  | 'expirada'
  | 'conta_bloqueada'
  | 'mesmo_aparelho';

export interface AuthSession {
  id: string;
  userId: string;
  deviceId: string;
  refreshHash: string;
  previousRefreshHash: string | null;
  rotatedAt: number | null;
  /** O refresh anterior já foi usado na tolerância (só vale uma vez). */
  graceUsed: boolean;
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
  ip: string | null;
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
  ipHits: Map<string, number[]>; // limites por IP (envio de código, registro de aparelho)
  blockedIdentifiers: Map<string, BlockedIdentifier>; // chave: HMAC de tipo:identificador
  /** Limites por conta (ex.: consulta de @): horários por chave. */
  userHits: Map<string, number[]>;
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
    ipHits: new Map(),
    blockedIdentifiers: new Map(),
    userHits: new Map(),
  };
}
