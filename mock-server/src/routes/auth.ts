import { Type, type Static } from '@sinclair/typebox';
import type { FastifyInstance } from 'fastify';
import type { AntiBot } from '../auth/antibot.js';
import { bearer, requireAuth } from '../auth/middleware.js';
import type { AuthService } from '../auth/service.js';
import type { State } from '../state.js';

// Autenticação — docs/API.md (Fase 1b), ADR 0012.
const Device = {
  deviceId: Type.String({ minLength: 1, maxLength: 64 }),
  deviceSecret: Type.String({ minLength: 1, maxLength: 128 }),
};
const Email = Type.String({ minLength: 3, maxLength: 254 });
const Password = Type.String({ minLength: 1, maxLength: 128 });
const Code = Type.String({ pattern: '^\\d{6}$' });

const SendBody = Type.Object({
  channel: Type.Union([Type.Literal('sms'), Type.Literal('whatsapp'), Type.Literal('email')]),
  destination: Type.String({ minLength: 3, maxLength: 254 }),
  purpose: Type.Union([Type.Literal('login'), Type.Literal('signup'), Type.Literal('reset')]),
});
const VerifyBody = Type.Object({
  destination: Type.String({ minLength: 3, maxLength: 254 }),
  code: Code,
  purpose: Type.Union([Type.Literal('login'), Type.Literal('signup')]),
  ...Device,
});
const SignupBody = Type.Object({ email: Email, password: Password });
const LoginBody = Type.Object({ email: Email, password: Password, ...Device });
const GoogleBody = Type.Object({ idToken: Type.String({ minLength: 1, maxLength: 4096 }), ...Device });
const ResetBody = Type.Object({ email: Email, code: Code, newPassword: Password });
const RefreshBody = Type.Object({ refreshToken: Type.String({ minLength: 1, maxLength: 256 }), ...Device });
const LogoutBody = Type.Union([
  Type.Object({ refreshToken: Type.Optional(Type.String({ maxLength: 256 })) }),
  Type.Null(),
]);
const TermsBody = Type.Object({
  document: Type.Union([Type.Literal('terms'), Type.Literal('privacy'), Type.Literal('guidelines')]),
  version: Type.Integer({ minimum: 1 }),
});

export function registerAuthRoutes(
  app: FastifyInstance,
  service: AuthService,
  antibot: AntiBot,
  getState: () => State,
) {
  app.post<{ Body: Static<typeof SendBody> }>(
    '/v1/auth/code/send',
    { schema: { body: SendBody } },
    async (req) => {
      antibot.check(req, 'code_send');
      return service.sendCode(req.body);
    },
  );

  app.post<{ Body: Static<typeof VerifyBody> }>(
    '/v1/auth/code/verify',
    { schema: { body: VerifyBody } },
    async (req) => service.verifyCode(req.body, req.ip),
  );

  app.post<{ Body: Static<typeof SignupBody> }>(
    '/v1/auth/email/signup',
    { schema: { body: SignupBody } },
    async (req, reply) => {
      antibot.check(req, 'signup');
      await service.signupEmail(req.body.email, req.body.password);
      return reply.status(202).send();
    },
  );

  app.post<{ Body: Static<typeof LoginBody> }>(
    '/v1/auth/email/login',
    { schema: { body: LoginBody } },
    async (req) => {
      antibot.check(req, 'login');
      return service.loginEmail(req.body, req.ip);
    },
  );

  app.post<{ Body: Static<typeof GoogleBody> }>(
    '/v1/auth/google',
    { schema: { body: GoogleBody } },
    async (req) => service.google(req.body),
  );

  app.post<{ Body: Static<typeof ResetBody> }>(
    '/v1/auth/password/reset',
    { schema: { body: ResetBody } },
    async (req, reply) => {
      antibot.check(req, 'reset');
      await service.resetPassword(req.body, req.ip);
      return reply.status(204).send();
    },
  );

  app.post<{ Body: Static<typeof RefreshBody> }>(
    '/v1/auth/refresh',
    { schema: { body: RefreshBody } },
    async (req) => service.refresh(req.body),
  );

  app.post<{ Body: Static<typeof LogoutBody> }>(
    '/v1/auth/logout',
    { schema: { body: Type.Optional(LogoutBody) } },
    async (req, reply) => {
      const access = bearer(req);
      service.logout({
        ...(access ? { accessToken: access } : {}),
        ...(req.body?.refreshToken ? { refreshToken: req.body.refreshToken } : {}),
      });
      return reply.status(204).send();
    },
  );

  app.get('/v1/me', { preHandler: requireAuth(service, { allowPendingTerms: true }) }, async (req) => {
    const ctx = req.auth;
    if (!ctx) throw new Error('auth ausente');
    return {
      id: ctx.user.id,
      needsProfile: ctx.user.needsProfile,
      accountStatus: ctx.user.accountStatus,
      pendingTerms: service.pendingTerms(ctx.user.id),
    };
  });

  app.post<{ Body: Static<typeof TermsBody> }>(
    '/v1/me/terms/accept',
    { schema: { body: TermsBody }, preHandler: requireAuth(service, { allowPendingTerms: true }) },
    async (req, reply) => {
      const ctx = req.auth;
      if (!ctx) throw new Error('auth ausente');
      service.acceptTerms(ctx, req.body.document, req.body.version);
      return reply.status(204).send();
    },
  );

  // Só para os testes de contrato provarem o bloqueio por termos pendentes (rota autenticada qualquer).
  app.get('/v1/me/ping', { preHandler: requireAuth(service) }, async () => ({
    ok: true,
    at: getState().config.configVersion,
  }));
}
