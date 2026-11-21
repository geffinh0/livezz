import Fastify, { type FastifyInstance } from 'fastify';
import { ConnectorRegistry } from './connectors/registry.js';
import { ApiError, errorBody, sendError } from './http/errors.js';
import { registerGuards } from './http/guards.js';
import { setDocumentedTypes } from './realtime/catalog.js';
import { readDocumentedServerTypes } from './realtime/docs-catalog.js';
import { Hub } from './realtime/hub.js';
import { attachRealtime } from './realtime/server.js';
import { registerConfigRoutes } from './routes/config.js';
import { registerMockRoutes } from './scenarios/mock-routes.js';
import { createState, type State } from './state.js';

export interface MockServer {
  app: FastifyInstance;
  state: State;
  hub: Hub;
  connectors: ConnectorRegistry;
}

export interface BuildOptions {
  tenantId?: string;
  logger?: boolean;
}

export async function buildApp(opts: BuildOptions = {}): Promise<MockServer> {
  const app = Fastify({ logger: opts.logger ?? false, genReqId: () => crypto.randomUUID() });
  const tenantId = opts.tenantId ?? 'liveapp';
  const state = createState(tenantId);
  const holder: MockServer = {
    app,
    state,
    hub: new Hub(),
    connectors: new ConnectorRegistry(() => holder.state.integrations),
  };
  setDocumentedTypes(readDocumentedServerTypes());

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
  attachRealtime(app, holder.hub, getState);
  registerMockRoutes(app, {
    getState,
    resetState: () => {
      // A versão da config só cresce: clientes ignoram versões antigas.
      const nextVersion = holder.state.config.configVersion + 1;
      holder.state = createState(tenantId);
      holder.state.config.configVersion = nextVersion;
    },
    hub: holder.hub,
    tenantId,
  });

  return holder;
}
