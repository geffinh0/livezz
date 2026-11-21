import Fastify, { type FastifyInstance } from 'fastify';
import { ApiError, errorBody, sendError } from './http/errors.js';
import { registerGuards } from './http/guards.js';
import { registerConfigRoutes } from './routes/config.js';
import { createState, type State } from './state.js';

export interface MockServer {
  app: FastifyInstance;
  state: State;
}

export interface BuildOptions {
  tenantId?: string;
  logger?: boolean;
}

export async function buildApp(opts: BuildOptions = {}): Promise<MockServer> {
  const app = Fastify({ logger: opts.logger ?? false, genReqId: () => crypto.randomUUID() });
  const holder: MockServer = { app, state: createState(opts.tenantId) };

  app.setErrorHandler((err, req, reply) => {
    if (err instanceof ApiError) return sendError(req, reply, err);
    const e = err as { validation?: unknown; statusCode?: number };
    if (e.validation) return reply.status(400).send(errorBody(req, 'validacao'));
    req.log.error(err);
    return reply.status(500).send(errorBody(req, 'erro_interno'));
  });
  app.setNotFoundHandler((req, reply) => reply.status(404).send(errorBody(req, 'nao_encontrado')));

  const getState = () => holder.state;
  registerGuards(app, getState);
  registerConfigRoutes(app, getState);

  return holder;
}
