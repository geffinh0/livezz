import type { FastifyInstance } from 'fastify';
import { regionFor } from '../http/region.js';
import type { State } from '../state.js';

// GET /v1/config — docs/API.md (TRV04, ENT01). Sem auth.
export function registerConfigRoutes(app: FastifyInstance, getState: () => State) {
  // `region` é calculado por requisição: não faz parte da config guardada.
  app.get('/v1/config', async (req) => {
    const state = getState();
    return { ...state.config, region: regionFor(req, state) };
  });
}
