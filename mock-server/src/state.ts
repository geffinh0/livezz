import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { defaultLimits } from './business.js';
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
  'erro-500' | 'rede-lenta' | 'manutencao' | 'versao-minima' | 'regiao-bloqueada' | 'entrada-desligada';
export const scenarioNames: readonly ScenarioName[] = [
  'erro-500',
  'rede-lenta',
  'manutencao',
  'versao-minima',
  'regiao-bloqueada',
  'entrada-desligada',
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
}

export interface State {
  config: ConfigApp;
  users: Map<string, User>;
  scenarios: Set<ScenarioName>;
  integrations: IntegracaoProvedor[];
  devices: Map<string, Device>;
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
  };
}
