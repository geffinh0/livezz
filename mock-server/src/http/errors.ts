import { randomUUID } from 'node:crypto';
import type { FastifyReply, FastifyRequest } from 'fastify';

// Catálogo de erros: docs/API.md. O app traduz por `code`; `message` é só um texto seguro.
export type ErrorCode =
  | 'nao_autenticado'
  | 'nao_encontrado'
  | 'validacao'
  | 'limite_excedido'
  | 'atualizacao_obrigatoria'
  | 'manutencao'
  | 'erro_interno';

const messages: Record<ErrorCode, { pt: string; en: string }> = {
  nao_autenticado: { pt: 'Entre na sua conta para continuar.', en: 'Sign in to continue.' },
  nao_encontrado: { pt: 'Não encontrado.', en: 'Not found.' },
  validacao: { pt: 'Dados inválidos.', en: 'Invalid data.' },
  limite_excedido: { pt: 'Muitas tentativas. Tente mais tarde.', en: 'Too many attempts. Try later.' },
  atualizacao_obrigatoria: { pt: 'Atualize o app para continuar.', en: 'Update the app to continue.' },
  manutencao: { pt: 'Estamos em manutenção. Volte em instantes.', en: 'We are under maintenance.' },
  erro_interno: { pt: 'Algo deu errado. Tente de novo.', en: 'Something went wrong. Try again.' },
};

export class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: ErrorCode,
    public readonly details: Record<string, unknown> = {},
    public readonly headers: Record<string, string> = {},
  ) {
    super(code);
  }
}

export function isEnglish(req: FastifyRequest): boolean {
  return (req.headers['accept-language'] ?? '').toLowerCase().startsWith('en');
}

export function errorBody(req: FastifyRequest, code: ErrorCode, details: Record<string, unknown> = {}) {
  const m = messages[code];
  return {
    error: {
      code,
      message: isEnglish(req) ? m.en : m.pt,
      details,
      requestId: String(req.id ?? randomUUID()),
    },
  };
}

export function sendError(req: FastifyRequest, reply: FastifyReply, err: ApiError) {
  for (const [k, v] of Object.entries(err.headers)) reply.header(k, v);
  return reply.status(err.status).send(errorBody(req, err.code, err.details));
}
