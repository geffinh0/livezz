import type { FastifyRequest } from 'fastify';
import type { State } from '../state.js';

// País da requisição. SÓ NO MOCK: vem do header X-Mock-Country (padrão BR) ou
// do cenário regiao-bloqueada. O backend real detecta por IP (Q-47); nunca
// confia em país informado pelo app.
export const blockedScenarioCountry = 'XX';

export function detectCountry(req: FastifyRequest, state: State): string {
  if (state.scenarios.has('regiao-bloqueada')) return blockedScenarioCountry;
  const h = req.headers['x-mock-country'];
  return typeof h === 'string' && /^[A-Za-z]{2}$/.test(h) ? h.toUpperCase() : 'BR';
}

export function regionFor(req: FastifyRequest, state: State) {
  const country = detectCountry(req, state);
  return { country, allowed: state.config.allowedRegions.includes(country) };
}
