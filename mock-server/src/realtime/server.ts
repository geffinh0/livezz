import type { IncomingMessage } from 'node:http';
import type { FastifyInstance } from 'fastify';
import { WebSocketServer, type WebSocket } from 'ws';
import { realtimeAuthTimeoutMs } from '../business.js';
import type { State } from '../state.js';
import { envelope, type Envelope } from './envelope.js';
import type { Connection, Hub } from './hub.js';
import { userIdFromToken } from './tokens.js';

// WebSocket /v1/realtime — docs/EVENTOS-TEMPO-REAL.md.
export const CLOSE = { authTimeout: 4000, invalidToken: 4001, replaced: 4002 } as const;
const ROOM = /^(live|pk|call|conversation):[A-Za-z0-9_-]{1,64}$/;
const MAX_MESSAGE_BYTES = 16 * 1024;

interface ClientMessage {
  v?: unknown;
  id?: unknown;
  type?: unknown;
  data?: Record<string, unknown>;
}

class WsConnection implements Connection {
  userId: string | null = null;
  rooms = new Set<string>();
  constructor(private readonly ws: WebSocket) {}
  send(e: Envelope) {
    if (this.ws.readyState === this.ws.OPEN) this.ws.send(JSON.stringify(e));
  }
  close(code: number, reason: string) {
    this.ws.close(code, reason);
  }
}

export function attachRealtime(app: FastifyInstance, hub: Hub, getState: () => State) {
  const wss = new WebSocketServer({ noServer: true, maxPayload: MAX_MESSAGE_BYTES });

  app.server.on('upgrade', (req: IncomingMessage, socket, head) => {
    const path = (req.url ?? '').split('?')[0];
    if (path !== '/v1/realtime') {
      socket.destroy();
      return;
    }
    wss.handleUpgrade(req, socket, head, (ws) => onConnection(ws));
  });

  app.addHook('onClose', async () => {
    hub.closeAll(1001, 'server closing');
    wss.close();
  });

  function onConnection(ws: WebSocket) {
    const conn = new WsConnection(ws);
    hub.add(conn);
    const authTimer = setTimeout(() => {
      if (conn.userId === null) conn.close(CLOSE.authTimeout, 'auth timeout');
    }, realtimeAuthTimeoutMs);

    ws.on('close', () => {
      clearTimeout(authTimer);
      hub.remove(conn);
    });

    ws.on('message', (raw) => {
      let msg: ClientMessage;
      try {
        msg = JSON.parse(String(raw)) as ClientMessage;
      } catch {
        return; // não é JSON: ignorado
      }
      if (typeof msg !== 'object' || msg === null || typeof msg.type !== 'string') return;
      const refId = typeof msg.id === 'string' ? msg.id : null;
      const ack = (ok: boolean, error?: string) => {
        if (refId) conn.send(envelope('ack', error ? { refId, ok, error } : { refId, ok }));
      };
      const data = typeof msg.data === 'object' && msg.data !== null ? msg.data : {};

      if (msg.type === 'auth') {
        const userId = userIdFromToken(getState(), data.token);
        if (!userId) {
          conn.send(envelope('session.invalid', { reason: 'token_invalido' }));
          conn.close(CLOSE.invalidToken, 'invalid token');
          return;
        }
        // Uma conexão por conta (RN-06): a anterior é substituída.
        const previous = hub.byUser(userId);
        if (previous && previous !== conn) {
          previous.send(envelope('session.replaced', { at: new Date().toISOString() }));
          previous.close(CLOSE.replaced, 'session replaced');
          hub.remove(previous);
        }
        conn.userId = userId;
        clearTimeout(authTimer);
        ack(true);
        return;
      }

      if (conn.userId === null) {
        ack(false, 'nao_autenticado');
        return;
      }

      switch (msg.type) {
        case 'ping':
          conn.send(envelope('pong', {}));
          return;
        case 'room.join':
        case 'room.leave': {
          const room = data.room;
          if (typeof room !== 'string' || !ROOM.test(room)) {
            ack(false, 'validacao');
            return;
          }
          if (msg.type === 'room.join') conn.rooms.add(room);
          else conn.rooms.delete(room);
          ack(true);
          return;
        }
        default:
          ack(false, 'validacao');
      }
    });
  }
}
