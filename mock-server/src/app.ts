import Fastify, { type FastifyInstance } from 'fastify';
import { AntiBot } from './auth/antibot.js';
import { AuthService } from './auth/service.js';
import { ConnectorRegistry } from './connectors/registry.js';
import { ApiError, errorBody, sendError } from './http/errors.js';
import { registerCors } from './http/cors.js';
import { registerGuards } from './http/guards.js';
import { setDocumentedTypes } from './realtime/catalog.js';
import { readDocumentedServerTypes } from './realtime/docs-catalog.js';
import { Hub } from './realtime/hub.js';
import { attachRealtime } from './realtime/server.js';
import { registerAuthRoutes } from './routes/auth.js';
import { registerConfigRoutes } from './routes/config.js';
import { registerDeviceRoutes } from './routes/devices.js';
import { registerMockRoutes } from './scenarios/mock-routes.js';
import { createState, type State } from './state.js';

export interface MockServer {
  app: FastifyInstance;
  state: State;
  hub: Hub;
  connectors: ConnectorRegistry;
  auth: AuthService;
}

export interface BuildOptions {
  tenantId?: string;
  logger?: boolean;
  /** Para testes que conferem o conteúdo dos logs. */
  logStream?: { write(msg: string): void };
}

export async function buildApp(opts: BuildOptions = {}): Promise<MockServer> {
  // Logs nunca levam segredos (ADR 0012, SEGURANCA.md).
  const redact = {
    paths: [
      'req.headers.authorization',
      'req.headers["x-antibot-token"]',
      '*.password',
      '*.newPassword',
      '*.code',
      '*.refreshToken',
      '*.deviceSecret',
      '*.idToken',
      '*.destination',
      '*.email',
    ],
    censor: '[oculto]',
  };
  const logger = opts.logStream
    ? { level: 'info', redact, stream: opts.logStream }
    : opts.logger
      ? { level: 'info', redact }
      : false;
  const app = Fastify({ logger, genReqId: () => crypto.randomUUID() });
  const tenantId = opts.tenantId ?? 'liveapp';
  const state = createState(tenantId);
  const hub = new Hub();
  const connectors = new ConnectorRegistry(() => holder.state.integrations);
  const holder: MockServer = {
    app,
    state,
    hub,
    connectors,
    auth: new AuthService(() => holder.state, hub, connectors),
  };
  const antibot = new AntiBot(() => holder.state);
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
  registerCors(app);
  registerGuards(app, getState);
  registerConfigRoutes(app, getState);
  registerDeviceRoutes(app, getState, antibot, (ip) => holder.auth.hitIp('device', ip));
  registerAuthRoutes(app, holder.auth, antibot, getState);
  attachRealtime(app, holder.hub, getState, holder.auth);
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
