import { randomUUID } from 'node:crypto';
import { hashSecret, randomToken, verifySecret } from '../auth/crypto.js';
import type { AntiBot } from '../auth/antibot.js';
import { minorProtocol } from '../auth/service.js';
import { Type, type Static } from '@sinclair/typebox';
import type { FastifyInstance } from 'fastify';
import type { State } from '../state.js';

// POST /v1/devices — docs/API.md (ENT01). O servidor gera o id; id desconhecido
// ou forjado nunca é adotado.
const Body = Type.Object(
  {
    deviceId: Type.Optional(Type.String({ maxLength: 64 })),
    deviceSecret: Type.Optional(Type.String({ maxLength: 128 })),
    platform: Type.Union([Type.Literal('android'), Type.Literal('ios'), Type.Literal('web')]),
    appVersion: Type.String({ pattern: '^\\d+\\.\\d+\\.\\d+$' }),
    locale: Type.Union([Type.Literal('pt-BR'), Type.Literal('en')]),
    model: Type.Optional(Type.String({ maxLength: 80 })),
  },
  { additionalProperties: false },
);

export function registerDeviceRoutes(
  app: FastifyInstance,
  getState: () => State,
  antibot: AntiBot,
  limitIp: (ip: string) => void,
) {
  app.post<{ Body: Static<typeof Body> }>('/v1/devices', { schema: { body: Body } }, async (req, reply) => {
    antibot.check(req, 'devices');
    limitIp(req.ip); // criação em massa de aparelhos (e de scrypt) bloqueada por IP
    const { devices } = getState();
    const now = new Date().toISOString();
    const { deviceId, deviceSecret, platform, appVersion, locale, model } = req.body;
    const candidate = deviceId ? devices.get(deviceId) : undefined;
    // Atualizar exige o segredo certo (ADR 0012); sem ele, cria outro aparelho.
    const known =
      candidate?.secretHash && deviceSecret && (await verifySecret(deviceSecret, candidate.secretHash))
        ? candidate
        : undefined;
    if (known) {
      Object.assign(known, { platform, appVersion, locale, model: model ?? known.model, seenAt: now });
      // ENT10: aparelho marcado avisa o app para mostrar a tela de bloqueio.
      return reply.status(200).send({
        deviceId: known.id,
        blocked: known.blockedMinorAt !== null,
        ...(known.blockedMinorAt ? { protocol: minorProtocol(known.blockedMinorUserId) } : {}),
      });
    }
    const id = randomUUID();
    const secret = randomToken();
    devices.set(id, {
      secretHash: await hashSecret(secret),
      userId: null,
      id,
      platform,
      appVersion,
      locale,
      model: model ?? null,
      registeredAt: now,
      seenAt: now,
      blockedMinorAt: null,
      blockedMinorUserId: null,
    });
    return reply.status(201).send({ deviceId: id, deviceSecret: secret, blocked: false });
  });
}
