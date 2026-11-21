import { randomUUID } from 'node:crypto';

/** Envelope versionado (ADR 0005). */
export interface Envelope<T = unknown> {
  v: 1;
  id: string;
  type: string;
  ts: string;
  data: T;
}

export function envelope<T>(type: string, data: T): Envelope<T> {
  return { v: 1, id: randomUUID(), type, ts: new Date().toISOString(), data };
}
