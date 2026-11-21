import { randomUUID } from 'node:crypto';
import { Type, type Static } from '@sinclair/typebox';
import type { FastifyInstance } from 'fastify';
import type { State } from '../state.js';

// POST /v1/devices — docs/API.md (ENT01). O servidor gera o id; id desconhecido
// ou forjado nunca é adotado.
const Body = Type.Object(
  {
    deviceId: Type.Optional(Type.String({ maxLength: 64 })),
    platform: Type.Union([Type.Literal('android'), Type.Literal('ios'), Type.Literal('web')]),
    appVersion: Type.String({ pattern: '^\\d+\\.\\d+\\.\\d+$' }),
    locale: Type.Union([Type.Literal('pt-BR'), Type.Literal('en')]),
    model: Type.Optional(Type.String({ maxLength: 80 })),
  },
  { additionalProperties: false },
);

export function registerDeviceRoutes(app: FastifyInstance, getState: () => State) {
  app.post<{ Body: Static<typeof Body> }>('/v1/devices', { schema: { body: Body } }, async (req, reply) => {
    const { devices } = getState();
    const now = new Date().toISOString();
    const { deviceId, platform, appVersion, locale, model } = req.body;
    const known = deviceId ? devices.get(deviceId) : undefined;
    if (known) {
      Object.assign(known, { platform, appVersion, locale, model: model ?? known.model, seenAt: now });
      return reply.status(200).send({ deviceId: known.id });
    }
    const id = randomUUID();
    devices.set(id, {
      id,
      platform,
      appVersion,
      locale,
      model: model ?? null,
      registeredAt: now,
      seenAt: now,
    });
    return reply.status(201).send({ deviceId: id });
  });
}
