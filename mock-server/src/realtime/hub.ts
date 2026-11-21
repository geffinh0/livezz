import { envelope, type Envelope } from './envelope.js';

/** Uma conexão autenticada (o transporte WebSocket implementa esta interface). */
export interface Connection {
  userId: string | null;
  /** Sessão (ADR 0012); null para tokens de teste do mock. */
  sessionId: string | null;
  rooms: Set<string>;
  send(e: Envelope): void;
  close(code: number, reason: string): void;
}

export type Target = { room: string } | { userId: string } | { all: true };

/** Hub de salas e entregas em memória. */
export class Hub {
  private readonly connections = new Set<Connection>();

  add(c: Connection) {
    this.connections.add(c);
  }

  remove(c: Connection) {
    this.connections.delete(c);
  }

  /** Conexão autenticada da conta (uma por conta, RN-06). */
  byUser(userId: string): Connection | undefined {
    for (const c of this.connections) if (c.userId === userId) return c;
    return undefined;
  }

  /** Só conexões autenticadas recebem eventos. Retorna quantas receberam. */
  emit(target: Target, type: string, data: unknown): number {
    let n = 0;
    for (const c of this.connections) {
      if (c.userId === null) continue;
      const hit =
        'all' in target ? true : 'room' in target ? c.rooms.has(target.room) : c.userId === target.userId;
      if (hit) {
        c.send(envelope(type, data));
        n++;
      }
    }
    return n;
  }

  /** Revogação: avisa e fecha as conexões da sessão. */
  closeSession(sessionId: string, code: number, type: string, data: unknown) {
    for (const c of [...this.connections]) {
      if (c.sessionId !== sessionId) continue;
      c.send(envelope(type, data));
      c.close(code, type);
      this.connections.delete(c);
    }
  }

  bySession(sessionId: string): Connection | undefined {
    for (const c of this.connections) if (c.sessionId === sessionId) return c;
    return undefined;
  }

  closeAll(code: number, reason: string) {
    for (const c of [...this.connections]) c.close(code, reason);
    this.connections.clear();
  }

  get size() {
    return this.connections.size;
  }
}
