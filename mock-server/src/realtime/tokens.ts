import type { State } from '../state.js';

// SÓ NO MOCK (Fase 0): tokens de teste `dev-token-<userId>` para os usuários das fixtures.
// O login real (Fase 1) troca isto pela validação do access token.
const prefix = 'dev-token-';

export function userIdFromToken(state: State, token: unknown): string | null {
  if (typeof token !== 'string' || !token.startsWith(prefix)) return null;
  const id = token.slice(prefix.length);
  return state.users.has(id) ? id : null;
}
