import { buildApp } from './app.js';

const port = Number(process.env.PORT ?? 3000);
// Só na máquina local por padrão: /__mock/* não tem autenticação.
// Celular: `adb reverse tcp:3000 tcp:3000`; emulador: 10.0.2.2 já chega aqui.
const host = process.env.HOST ?? '127.0.0.1';

if (process.env.NODE_ENV === 'production') {
  console.error('mock-server não roda em produção (NODE_ENV=production).');
  process.exit(1);
}
const tenantId = process.env.TENANT ?? 'liveapp';

const { app } = await buildApp({ tenantId, logger: true });
await app.listen({ port, host });
console.info(`mock-server (${tenantId}) em http://localhost:${port}`);
