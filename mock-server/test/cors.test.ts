import { describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';

describe('CORS (dev local)', () => {
  it('libera origem local e responde preflight', async () => {
    const { app } = await buildApp();
    const pre = await app.inject({
      method: 'OPTIONS',
      url: '/v1/config',
      headers: { origin: 'http://localhost:8080', 'access-control-request-method': 'GET' },
    });
    expect(pre.statusCode).toBe(204);
    expect(pre.headers['access-control-allow-origin']).toBe('http://localhost:8080');
    expect(pre.headers['access-control-allow-headers']).toContain('X-App-Version');
    const get = await app.inject({
      method: 'GET',
      url: '/v1/config',
      headers: { origin: 'http://127.0.0.1:5000' },
    });
    expect(get.headers['access-control-allow-origin']).toBe('http://127.0.0.1:5000');
  });

  it('não libera origem externa', async () => {
    const { app } = await buildApp();
    const res = await app.inject({
      method: 'GET',
      url: '/v1/config',
      headers: { origin: 'https://evil.example' },
    });
    expect(res.headers['access-control-allow-origin']).toBeUndefined();
  });
});
