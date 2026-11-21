import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { repoRoot } from '../state.js';

/** Lê os tipos servidor → cliente das tabelas de docs/EVENTOS-TEMPO-REAL.md. */
export function readDocumentedServerTypes(file = join(repoRoot, 'docs', 'EVENTOS-TEMPO-REAL.md')): string[] {
  const md = readFileSync(file, 'utf8');
  const start = md.indexOf('## Servidor → cliente');
  const end = md.indexOf('\n## ', start + 1);
  const section = md.slice(start, end === -1 ? undefined : end);
  const types = new Set<string>();
  for (const line of section.split('\n')) {
    const m = /^\| ([a-z][a-z0-9_.]*(?: \/ [a-z][a-z0-9_.]*)*) \|/.exec(line);
    if (!m?.[1] || m[1] === 'type') continue;
    for (const t of m[1].split(' / ')) types.add(t.trim());
  }
  return [...types];
}
