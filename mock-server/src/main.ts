import { buildApp } from './app.js';

const port = Number(process.env.PORT ?? 3000);
const host = process.env.HOST ?? '0.0.0.0';
const tenantId = process.env.TENANT ?? 'liveapp';

const { app } = await buildApp({ tenantId, logger: true });
await app.listen({ port, host });
console.info(`mock-server (${tenantId}) em http://localhost:${port}`);
