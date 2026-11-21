import { Type, type Static } from '@sinclair/typebox';
import type { FastifyInstance } from 'fastify';
import { forcedMinAppVersion, maintenanceRetryAfterSeconds, slowNetworkDelayMs } from '../business.js';
import { ApiError } from '../http/errors.js';
import { isKnownServerEvent } from '../realtime/catalog.js';
import type { Hub, Target } from '../realtime/hub.js';
import { createState, scenarioNames, type ScenarioName, type State } from '../state.js';

// Rotas /__mock/* (docs/API.md). Só existem no mock-server: este módulo nunca vai para o backend real.

export interface MockContext {
  getState(): State;
  resetState(): void;
  hub: Hub;
  tenantId: string;
}

const ScenarioBody = Type.Union([Type.Object({ active: Type.Optional(Type.Boolean()) }), Type.Null()]);
const EmitBody = Type.Object({
  type: Type.String({ minLength: 1 }),
  data: Type.Optional(Type.Record(Type.String(), Type.Unknown())),
  target: Type.Union([
    Type.Object({ room: Type.String({ minLength: 1 }) }),
    Type.Object({ userId: Type.String({ minLength: 1 }) }),
    Type.Object({ all: Type.Literal(true) }),
  ]),
});

const pristine = (tenantId: string) => createState(tenantId).config;

function bumpConfig(ctx: MockContext, changed: Record<string, unknown>) {
  const cfg = ctx.getState().config;
  cfg.configVersion += 1;
  ctx.hub.emit({ all: true }, 'config.updated', { configVersion: cfg.configVersion, ...changed });
}

function applyScenario(ctx: MockContext, name: ScenarioName, active: boolean) {
  const state = ctx.getState();
  if (active) state.scenarios.add(name);
  else state.scenarios.delete(name);
  const cfg = state.config;
  if (name === 'manutencao') {
    cfg.maintenance = active
      ? { active: true, retryAfterSeconds: maintenanceRetryAfterSeconds }
      : { active: false, retryAfterSeconds: null };
    bumpConfig(ctx, { maintenance: cfg.maintenance });
  }
  if (name === 'entrada-desligada') {
    const original = pristine(ctx.tenantId).flags;
    const loginFlags = ['loginPhone', 'loginEmail', 'loginGoogle'];
    const changed: Record<string, boolean> = {};
    for (const f of loginFlags) changed[f] = active ? false : (original[f] ?? false);
    Object.assign(cfg.flags, changed);
    bumpConfig(ctx, { flags: changed });
  }
  if (name === 'exigir-desafio') {
    // Liga o App Check (RN-85: cada provedor por flag) e simula o servidor achando risco.
    const original = pristine(ctx.tenantId).flags;
    const changed = { antibotAppCheck: active ? true : (original.antibotAppCheck ?? false) };
    Object.assign(cfg.flags, changed);
    bumpConfig(ctx, { flags: changed });
  }
  if (name === 'termos-novos') {
    const terms = cfg.legalTexts.terms;
    if (terms) {
      terms.version = active ? 2 : 1;
      bumpConfig(ctx, { legalTexts: cfg.legalTexts });
    }
  }
  if (name === 'token-expira-rapido') {
    ctx.getState().auth.config.accessTokenSecondsOverride = active ? 5 : null;
  }
  if (name === 'versao-minima') {
    cfg.minAppVersion = active ? forcedMinAppVersion : pristine(ctx.tenantId).minAppVersion;
    bumpConfig(ctx, { minAppVersion: cfg.minAppVersion });
  }
}

export function registerMockRoutes(app: FastifyInstance, ctx: MockContext) {
  // Cenários que afetam todas as rotas /v1/* (inclusive /config).
  app.addHook('onRequest', async (req) => {
    if (!req.url.startsWith('/v1/')) return;
    const s = ctx.getState().scenarios;
    if (s.has('rede-lenta')) await new Promise((r) => setTimeout(r, slowNetworkDelayMs));
    if (s.has('erro-500')) throw new ApiError(500, 'erro_interno');
  });

  app.post('/__mock/reset', async (_req, reply) => {
    ctx.hub.closeAll(1001, 'mock reset');
    ctx.resetState();
    return reply.status(204).send();
  });

  app.post<{ Params: { name: string }; Body: Static<typeof ScenarioBody> }>(
    '/__mock/scenario/:name',
    { schema: { body: Type.Optional(ScenarioBody) } },
    async (req) => {
      const name = req.params.name as ScenarioName;
      if (!scenarioNames.includes(name)) throw new ApiError(404, 'nao_encontrado', { scenario: name });
      const active = req.body?.active ?? true;
      applyScenario(ctx, name, active);
      return { scenario: name, active };
    },
  );

  // Último código "enviado" para um destino (E2E). SÓ MOCK; o app nunca chama.
  app.get<{ Querystring: { destination?: string } }>('/__mock/outbox', async (req) => {
    const dest = (req.query.destination ?? '').trim().toLowerCase();
    const code =
      ctx.getState().auth.lastCodes.get(dest) ??
      ctx.getState().auth.lastCodes.get(req.query.destination ?? '');
    if (!code) throw new ApiError(404, 'nao_encontrado');
    return { code };
  });

  app.post<{ Body: Static<typeof EmitBody> }>('/__mock/emit', { schema: { body: EmitBody } }, async (req) => {
    const { type, data, target } = req.body;
    if (!isKnownServerEvent(type)) throw new ApiError(400, 'validacao', { type: 'evento fora do catálogo' });
    return { delivered: ctx.hub.emit(target as Target, type, data ?? {}) };
  });
}
