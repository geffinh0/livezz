import type { FastifyInstance } from 'fastify';

// CORS só para origens locais (app Flutter web e painel/portal em dev).
// O mock roda só em 127.0.0.1; o backend real terá sua própria lista.
const LOCAL_ORIGIN = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

export function registerCors(app: FastifyInstance) {
  app.addHook('onRequest', async (req, reply) => {
    const origin = req.headers.origin;
    if (!origin || !LOCAL_ORIGIN.test(origin)) return;
    reply.header('Access-Control-Allow-Origin', origin);
    reply.header('Vary', 'Origin');
    reply.header('Access-Control-Expose-Headers', 'Retry-After');
    if (req.method === 'OPTIONS') {
      reply.header('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
      reply.header(
        'Access-Control-Allow-Headers',
        'Content-Type,Authorization,Accept-Language,X-App-Version,Idempotency-Key,X-Mock-Country',
      );
      reply.header('Access-Control-Max-Age', '600');
      return reply.status(204).send();
    }
  });
}
