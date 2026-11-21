import { tenant } from '../tenant.generated';

export interface PublicConfig {
  configVersion: number;
}

/** GET /v1/config (docs/API.md). URL da API por ambiente; padrão do tenant. */
export async function fetchConfig(locale: string): Promise<PublicConfig | null> {
  const base = process.env.API_BASE_URL ?? tenant.apiBaseUrl;
  try {
    const res = await fetch(`${base.replace(/\/+$/, '')}/v1/config`, {
      headers: { 'Accept-Language': locale },
      cache: 'no-store',
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return null;
    return (await res.json()) as PublicConfig;
  } catch {
    return null;
  }
}
