import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { defaultLimits } from './business.js';
import { hashSecretSync } from './auth/crypto.js';
import { createAuthStore, type AuthStore } from './auth/store.js';
import { defaultIntegrations, type IntegracaoProvedor } from './connectors/registry.js';

// Estado em memória. Cada estrutura corresponde a uma entidade de docs/DATABASE.md.

export interface User {
  id: string;
  username: string;
  displayName: string;
  locale: 'pt-BR' | 'en';
}

export interface LegalText {
  version: number;
  url: string;
}

/** ConfigApp (DATABASE.md). Flags em camelCase no JSON; correspondência no DATABASE.md. */
export interface ConfigApp {
  configVersion: number;
  minAppVersion: string;
  maintenance: { active: boolean; retryAfterSeconds: number | null };
  flags: Record<string, boolean>;
  limits: Record<string, number>;
  discoverTabs: string[];
  legalTexts: Record<string, LegalText>;
  allowedRegions: string[];
}

export type ScenarioName =
  | 'erro-500'
  | 'rede-lenta'
  | 'manutencao'
  | 'versao-minima'
  | 'regiao-bloqueada'
  | 'entrada-desligada'
  | 'exigir-desafio'
  | 'token-expira-rapido'
  | 'termos-novos';
export const scenarioNames: readonly ScenarioName[] = [
  'erro-500',
  'rede-lenta',
  'manutencao',
  'versao-minima',
  'regiao-bloqueada',
  'entrada-desligada',
  'exigir-desafio',
  'token-expira-rapido',
  'termos-novos',
];

/** Dispositivo (DATABASE.md). */
export interface Device {
  id: string;
  platform: 'android' | 'ios' | 'web';
  model: string | null;
  appVersion: string;
  locale: 'pt-BR' | 'en';
  registeredAt: string;
  seenAt: string;
  secretHash: string | null; // ADR 0012
  userId: string | null;
}

export interface State {
  config: ConfigApp;
  users: Map<string, User>;
  scenarios: Set<ScenarioName>;
  integrations: IntegracaoProvedor[];
  devices: Map<string, Device>;
  auth: AuthStore;
}

const here = dirname(fileURLToPath(import.meta.url));
export const repoRoot = resolve(here, '..', '..');
const fixturesDir = resolve(here, '..', 'fixtures');

const readJson = <T>(file: string): T => JSON.parse(readFileSync(file, 'utf8')) as T;

interface TenantFile {
  portalBaseUrl: string;
  features: Record<string, boolean>;
  allowedRegions: string[];
}
interface ConfigFixture {
  minAppVersion: string;
  loginMethods: Record<string, boolean>;
  discoverTabs: string[];
  legalTexts: Record<string, { version: number; path: string }>;
}

// Fora do produto (ADR 0006): nunca vira flag.
const excludedFeatures = new Set(['games']);

export function createState(tenantId = 'liveapp'): State {
  const tenant = readJson<TenantFile>(join(repoRoot, 'tenants', tenantId, 'tenant.json'));
  const fx = readJson<ConfigFixture>(join(fixturesDir, 'config.json'));
  const users = readJson<User[]>(join(fixturesDir, 'users.json'));

  const flags: Record<string, boolean> = { ...fx.loginMethods };
  for (const [k, v] of Object.entries(tenant.features)) if (!excludedFeatures.has(k)) flags[k] = v;

  const legalTexts: Record<string, LegalText> = {};
  for (const [k, v] of Object.entries(fx.legalTexts)) {
    legalTexts[k] = { version: v.version, url: new URL(v.path, tenant.portalBaseUrl).toString() };
  }

  return {
    config: {
      configVersion: 1,
      minAppVersion: fx.minAppVersion,
      maintenance: { active: false, retryAfterSeconds: null },
      flags,
      limits: { ...defaultLimits },
      discoverTabs: [...fx.discoverTabs],
      legalTexts,
      allowedRegions: [...tenant.allowedRegions],
    },
    users: new Map(users.map((u) => [u.id, u])),
    scenarios: new Set(),
    integrations: defaultIntegrations(),
    devices: new Map(),
    auth: seedAuth(createAuthStore()),
  };
}

interface AuthFixture {
  accounts: Array<{
    userId: string;
    email?: string;
    password?: string;
    phone?: string;
    status?: 'ativa' | 'suspensa' | 'banida';
  }>;
}

/** Contas de teste do mock (fixtures/auth.json): já confirmadas e com termos v1 aceitos. */
function seedAuth(store: AuthStore): AuthStore {
  const fx = readJson<AuthFixture>(join(fixturesDir, 'auth.json'));
  const at = new Date(0).toISOString();
  for (const a of fx.accounts) {
    store.users.set(a.userId, {
      id: a.userId,
      accountStatus: a.status ?? 'ativa',
      needsProfile: false,
      createdAt: at,
    });
    if (a.email) {
      store.methods.push({
        userId: a.userId,
        type: 'email',
        identifier: a.email,
        passwordHash: a.password ? hashSecretSync(a.password) : null,
        verifiedAt: at,
      });
    }
    if (a.phone) {
      store.methods.push({
        userId: a.userId,
        type: 'telefone',
        identifier: a.phone,
        passwordHash: null,
        verifiedAt: at,
      });
    }
    for (const document of ['terms', 'privacy'] as const) {
      store.acceptances.push({ userId: a.userId, document, version: 1, acceptedAt: at, deviceId: null });
    }
  }
  return store;
}
