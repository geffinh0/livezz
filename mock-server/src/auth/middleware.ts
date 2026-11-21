import type { FastifyRequest, preHandlerHookHandler } from 'fastify';
import { ApiError } from '../http/errors.js';
import type { AuthContext, AuthService } from './service.js';
import { pendingSteps } from './store.js';

declare module 'fastify' {
  interface FastifyRequest {
    auth?: AuthContext;
  }
}

export function bearer(req: FastifyRequest): string | null {
  const h = req.headers.authorization;
  return typeof h === 'string' && h.startsWith('Bearer ') ? h.slice(7) : null;
}

/**
 * Rotas autenticadas: token válido, sessão ativa (revogação imediata), conta ativa
 * e, salvo exceção, termos aceitos (`403 termos_pendentes`, ENT16) e cadastro com
 * nome e data (`403 cadastro_pendente`, plano 1c).
 */
export function requireAuth(
  service: AuthService,
  opts: { allowPendingTerms?: boolean; allowPendingProfile?: boolean } = {},
): preHandlerHookHandler {
  return async (req: FastifyRequest) => {
    const token = bearer(req);
    if (!token) throw new ApiError(401, 'nao_autenticado');
    const ctx = service.authenticate(token);
    if (!opts.allowPendingTerms && service.pendingTerms(ctx.user.id).length > 0) {
      throw new ApiError(403, 'termos_pendentes');
    }
    // Portão de cadastro (plano 1c): sem nome e data, quase nada funciona.
    if (!opts.allowPendingProfile && pendingSteps(ctx.user).includes('profile')) {
      throw new ApiError(403, 'cadastro_pendente');
    }
    req.auth = ctx;
  };
}
