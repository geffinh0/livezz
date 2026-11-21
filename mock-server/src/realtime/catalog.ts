// Tipos servidor → cliente do catálogo docs/EVENTOS-TEMPO-REAL.md.
// Um teste confere que esta lista bate com o documento (contrato primeiro).
export const serverEventTypes = [
  'pong',
  'ack',
  'session.invalid',
  'session.replaced',
  'config.updated',
  'account.sanctioned',
  'age.verification.updated',
  'notification.new',
  'unread.updated',
  'ui.offer',
  'ui.banner',
  'presence.changed',
] as const;

export const clientMessageTypes = [
  'auth',
  'ping',
  'room.join',
  'room.leave',
  'presence.watch',
  'presence.unwatch',
];

let extraTypes: ReadonlySet<string> = new Set();

/** Tipos documentados lidos do catálogo (preenchido no início a partir do markdown). */
export function setDocumentedTypes(types: Iterable<string>) {
  extraTypes = new Set(types);
}

export function isKnownServerEvent(type: string): boolean {
  return (serverEventTypes as readonly string[]).includes(type) || extraTypes.has(type);
}
