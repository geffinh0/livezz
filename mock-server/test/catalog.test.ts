import { describe, expect, it } from 'vitest';
import { serverEventTypes } from '../src/realtime/catalog.js';
import { readDocumentedServerTypes } from '../src/realtime/docs-catalog.js';

describe('catálogo de eventos', () => {
  it('todo tipo implementado está documentado em EVENTOS-TEMPO-REAL.md', () => {
    const documented = new Set(readDocumentedServerTypes());
    for (const t of serverEventTypes) expect(documented.has(t), t).toBe(true);
  });

  it('lê tipos com barra (live.host.paused / live.host.resumed)', () => {
    const documented = readDocumentedServerTypes();
    expect(documented).toContain('live.host.resumed');
    expect(documented).toContain('live.gift.sent');
  });
});
