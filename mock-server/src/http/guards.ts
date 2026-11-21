import type { FastifyInstance } from 'fastify';
import type { State } from '../state.js';
import { ApiError } from './errors.js';
import { compareVersions } from './version.js';

// Convenções da API: 426 (versão mínima) e 503 (manutenção) em /v1/*, exceto GET /v1/config.
export function registerGuards(app: FastifyInstance, getState: () => State) {
  app.addHook('onRequest', async (req) => {
    const path = req.url.split('?')[0] ?? '';
    if (!path.startsWith('/v1/') || path === '/v1/config' || path === '/v1/realtime') return;
    const { config } = getState();
    if (config.maintenance.active) {
      const retry = String(config.maintenance.retryAfterSeconds ?? 60);
      throw new ApiError(503, 'manutencao', {}, { 'Retry-After': retry });
    }
    const v = req.headers['x-app-version'];
    if (typeof v === 'string' && compareVersions(v, config.minAppVersion) < 0) {
      throw new ApiError(426, 'atualizacao_obrigatoria', { minAppVersion: config.minAppVersion });
    }
  });
}
