import type { FastifyInstance } from 'fastify';
import type { State } from '../state.js';

// GET /v1/config — docs/API.md (TRV04, ENT01). Sem auth.
export function registerConfigRoutes(app: FastifyInstance, getState: () => State) {
  app.get('/v1/config', async () => getState().config);
}
