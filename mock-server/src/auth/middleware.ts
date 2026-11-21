import type { FastifyRequest, preHandlerHookHandler } from 'fastify';
import { ApiError } from '../http/errors.js';
import type { AuthContext, AuthService } from './service.js';

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
 * e, salvo exceção, termos aceitos (`403 termos_pendentes`, ENT16).
 */
export function requireAuth(
  service: AuthService,
  opts: { allowPendingTerms?: boolean } = {},
): preHandlerHookHandler {
  return async (req: FastifyRequest) => {
    const token = bearer(req);
    if (!token) throw new ApiError(401, 'nao_autenticado');
    const ctx = service.authenticate(token);
    if (!opts.allowPendingTerms && service.pendingTerms(ctx.user.id).length > 0) {
      throw new ApiError(403, 'termos_pendentes');
    }
    req.auth = ctx;
  };
}
