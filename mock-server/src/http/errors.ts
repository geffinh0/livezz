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
  | 'regiao_bloqueada'
  | 'credenciais_invalidas'
  | 'email_nao_confirmado'
  | 'desafio_necessario'
  | 'sessao_substituida'
  | 'sessao_revogada'
  | 'sessao_expirada'
  | 'termos_pendentes'
  | 'dispositivo_invalido'
  | 'token_expirado'
  | 'codigo_invalido'
  | 'codigo_expirado'
  | 'funcionalidade_desligada'
  | 'conta_suspensa'
  | 'conta_banida'
  | 'conflito'
  | 'erro_interno';

const messages: Record<ErrorCode, { pt: string; en: string }> = {
  nao_autenticado: { pt: 'Entre na sua conta para continuar.', en: 'Sign in to continue.' },
  nao_encontrado: { pt: 'Não encontrado.', en: 'Not found.' },
  validacao: { pt: 'Dados inválidos.', en: 'Invalid data.' },
  limite_excedido: { pt: 'Muitas tentativas. Tente mais tarde.', en: 'Too many attempts. Try later.' },
  atualizacao_obrigatoria: { pt: 'Atualize o app para continuar.', en: 'Update the app to continue.' },
  manutencao: { pt: 'Estamos em manutenção. Volte em instantes.', en: 'We are under maintenance.' },
  credenciais_invalidas: { pt: 'E-mail ou senha incorretos.', en: 'Wrong email or password.' },
  email_nao_confirmado: { pt: 'Confirme seu e-mail para entrar.', en: 'Confirm your email to sign in.' },
  desafio_necessario: {
    pt: 'Precisamos confirmar que você não é um robô.',
    en: 'We need to confirm you are not a robot.',
  },
  sessao_substituida: {
    pt: 'Sua conta entrou em outro aparelho.',
    en: 'Your account signed in on another device.',
  },
  sessao_revogada: {
    pt: 'Sua sessão foi encerrada. Entre de novo.',
    en: 'Your session ended. Sign in again.',
  },
  sessao_expirada: { pt: 'Sua sessão expirou. Entre de novo.', en: 'Your session expired. Sign in again.' },
  termos_pendentes: {
    pt: 'Aceite os termos atualizados para continuar.',
    en: 'Accept the updated terms to continue.',
  },
  dispositivo_invalido: {
    pt: 'Aparelho não reconhecido. Abra o app de novo.',
    en: 'Device not recognized. Reopen the app.',
  },
  token_expirado: { pt: 'Sessão expirada. Tentando de novo…', en: 'Session expired. Retrying…' },
  codigo_invalido: { pt: 'Código incorreto.', en: 'Incorrect code.' },
  codigo_expirado: { pt: 'O código expirou. Peça um novo.', en: 'The code expired. Request a new one.' },
  funcionalidade_desligada: { pt: 'Este recurso não está disponível.', en: 'This feature is not available.' },
  conta_suspensa: { pt: 'Sua conta está suspensa.', en: 'Your account is suspended.' },
  conta_banida: { pt: 'Sua conta foi banida.', en: 'Your account has been banned.' },
  conflito: { pt: 'Isso mudou. Tente de novo.', en: 'This changed. Try again.' },
  regiao_bloqueada: {
    pt: 'O app não está disponível na sua região.',
    en: 'The app is not available in your region.',
  },
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
