import {
  createHash,
  createHmac,
  randomBytes,
  scrypt as scryptCb,
  scryptSync,
  timingSafeEqual,
} from 'node:crypto';
import { promisify } from 'node:util';

const scrypt = promisify(scryptCb) as (pw: string, salt: Buffer, len: number) => Promise<Buffer>;

// Chave que assina os access tokens: variável de ambiente ou aleatória no boot (nunca no repositório).
const signingKey = process.env.MOCK_TOKEN_SECRET
  ? Buffer.from(process.env.MOCK_TOKEN_SECRET)
  : randomBytes(32);

/** Hash forte (scrypt + sal) para senhas e segredos do aparelho. */
export async function hashSecret(secret: string): Promise<string> {
  const salt = randomBytes(16);
  const key = await scrypt(secret, salt, 32);
  return `${salt.toString('base64')}:${key.toString('base64')}`;
}

/** Versão síncrona, só para semear fixtures. */
export function hashSecretSync(secret: string): string {
  const salt = randomBytes(16);
  return `${salt.toString('base64')}:${scryptSync(secret, salt, 32).toString('base64')}`;
}

export async function verifySecret(secret: string, stored: string): Promise<boolean> {
  const [saltB64, keyB64] = stored.split(':');
  if (!saltB64 || !keyB64) return false;
  const key = await scrypt(secret, Buffer.from(saltB64, 'base64'), 32);
  const expected = Buffer.from(keyB64, 'base64');
  return expected.length === key.length && timingSafeEqual(expected, key);
}

/** Hash usado quando a conta não existe: mantém o tempo de resposta igual (anti-enumeração). */
export const dummyHashPromise = hashSecret('nao-existe-' + randomBytes(8).toString('hex'));

/** Hash rápido para valores aleatórios longos (refresh token) e códigos curtos com sal fixo do boot. */
export function sha256(value: string): string {
  return createHash('sha256').update(signingKey).update(value).digest('base64url');
}

/** HMAC-SHA256 com a chave do servidor: identificadores enumeráveis (telefone, e-mail). */
export function hmac(value: string): string {
  return createHmac('sha256', signingKey).update(value).digest('base64url');
}

export function randomToken(bytes = 32): string {
  return randomBytes(bytes).toString('base64url');
}

export function randomCode(): string {
  return String(randomBytes(4).readUInt32BE(0) % 1_000_000).padStart(6, '0');
}

export interface AccessClaims {
  sub: string;
  sid: string;
  exp: number; // ms epoch
}

export function signAccess(claims: AccessClaims): string {
  const body = Buffer.from(JSON.stringify(claims)).toString('base64url');
  const sig = createHmac('sha256', signingKey).update(body).digest('base64url');
  return `at.${body}.${sig}`;
}

export function verifyAccess(token: string): AccessClaims | null {
  const [prefix, body, sig] = token.split('.');
  if (prefix !== 'at' || !body || !sig) return null;
  const expected = createHmac('sha256', signingKey).update(body).digest('base64url');
  const a = Buffer.from(sig);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !timingSafeEqual(a, b)) return null;
  try {
    const c = JSON.parse(Buffer.from(body, 'base64url').toString()) as AccessClaims;
    return typeof c.sub === 'string' && typeof c.sid === 'string' && typeof c.exp === 'number' ? c : null;
  } catch {
    return null;
  }
}
