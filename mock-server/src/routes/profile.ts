import { Type, type Static } from '@sinclair/typebox';
import type { FastifyInstance } from 'fastify';
import { requireAuth } from '../auth/middleware.js';
import type { AuthService } from '../auth/service.js';
import { isEnglish } from '../http/errors.js';
import type { ProfileService } from '../profile/service.js';

// Cadastro inicial (plano 1c) — docs/API.md "Cadastro inicial".
const Gender = Type.Union([
  Type.Literal('mulher'),
  Type.Literal('homem'),
  Type.Literal('nao_binario'),
  Type.Literal('prefiro_nao_dizer'),
]);
const PatchBody = Type.Object(
  {
    displayName: Type.Optional(Type.String({ maxLength: 60 })),
    birthDate: Type.Optional(Type.String({ maxLength: 10 })),
    gender: Type.Optional(Type.Union([Gender, Type.Null()])),
    language: Type.Optional(Type.Union([Type.Literal('pt-BR'), Type.Literal('en')])),
    storeAgeSignal: Type.Optional(
      Type.Object(
        {
          status: Type.Union([
            Type.Literal('shared'),
            Type.Literal('not_shared'),
            Type.Literal('verification_required'),
            Type.Literal('unavailable'),
          ]),
          ageLower: Type.Union([Type.Integer({ minimum: 0, maximum: 150 }), Type.Null()]),
          ageUpper: Type.Union([Type.Integer({ minimum: 0, maximum: 150 }), Type.Null()]),
        },
        { additionalProperties: false },
      ),
    ),
  },
  { additionalProperties: false },
);
const UsernameBody = Type.Object(
  { username: Type.String({ maxLength: 40 }) },
  { additionalProperties: false },
);
const InterestsBody = Type.Object(
  { ids: Type.Array(Type.String({ maxLength: 40 }), { maxItems: 10 }) },
  { additionalProperties: false },
);

export function registerProfileRoutes(app: FastifyInstance, auth: AuthService, profile: ProfileService) {
  const open = requireAuth(auth, { allowPendingTerms: true, allowPendingProfile: true });
  const gated = requireAuth(auth);

  app.get('/v1/me', { preHandler: open }, async (req) => {
    if (!req.auth) throw new Error('auth ausente');
    return profile.me(req.auth.user);
  });

  app.patch<{ Body: Static<typeof PatchBody> }>(
    '/v1/me',
    { schema: { body: PatchBody }, preHandler: open },
    async (req) => {
      if (!req.auth) throw new Error('auth ausente');
      const { user, session } = req.auth;
      const b = req.body;
      return profile.patch(user, session.deviceId, {
        ...(b.displayName !== undefined ? { displayName: b.displayName } : {}),
        ...(b.birthDate !== undefined ? { birthDate: b.birthDate } : {}),
        ...(b.gender !== undefined ? { gender: b.gender } : {}),
        ...(b.language !== undefined ? { language: b.language } : {}),
        ...(b.storeAgeSignal !== undefined ? { storeAgeSignal: b.storeAgeSignal } : {}),
      });
    },
  );

  app.get<{ Params: { u: string } }>('/v1/usernames/:u/availability', { preHandler: open }, async (req) => {
    if (!req.auth) throw new Error('auth ausente');
    auth.hitIp('username', req.ip);
    profile.limitUser(req.auth.user.id);
    return profile.availability(req.auth.user, req.params.u.slice(0, 40));
  });

  app.post<{ Body: Static<typeof UsernameBody> }>(
    '/v1/me/username',
    { schema: { body: UsernameBody }, preHandler: gated },
    async (req) => {
      if (!req.auth) throw new Error('auth ausente');
      return profile.setUsername(req.auth.user, req.body.username);
    },
  );

  app.get('/v1/interests', { preHandler: gated }, async (req) => profile.interests(isEnglish(req)));

  app.post<{ Body: Static<typeof InterestsBody> }>(
    '/v1/me/interests',
    { schema: { body: InterestsBody }, preHandler: gated },
    async (req, reply) => {
      if (!req.auth) throw new Error('auth ausente');
      profile.setInterests(req.auth.user, req.body.ids);
      return reply.status(204).send();
    },
  );
}
