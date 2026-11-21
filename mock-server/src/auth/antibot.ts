import type { FastifyRequest } from 'fastify';
import { ApiError } from '../http/errors.js';
import type { State } from '../state.js';

// Anti-bot (RN-85, SEG06). O servidor decide quando exigir o desafio.
// SÓ NO MOCK: exige quando o cenário `exigir-desafio` está ativo (ele liga o App Check)
// e há provedor ligado por flag; token válido =
// `fake-ok-<nonce>` de uso único, preso à rota. Os conectores reais entram na Fase 12.
export type AntiBotRoute = 'devices' | 'code_send' | 'signup' | 'login' | 'reset';
const PROVIDERS = ['appcheck', 'recaptcha', 'turnstile'] as const;

export class AntiBot {
  constructor(private readonly getState: () => State) {}

  private providers(): string[] {
    const f = this.getState().config.flags;
    const on = [
      f.antibotAppCheck ? 'appcheck' : null,
      f.antibotRecaptcha ? 'recaptcha' : null,
      f.antibotTurnstile ? 'turnstile' : null,
    ].filter((p): p is string => p !== null);
    return on;
  }

  // RN-85: só exige com algum provedor ligado por flag E quando o servidor decide (risco).
  private required(): boolean {
    return this.getState().scenarios.has('exigir-desafio') && this.providers().length > 0;
  }

  check(req: FastifyRequest, route: AntiBotRoute) {
    if (!this.required()) return;
    const providers = this.providers();
    const provider = req.headers['x-antibot-provider'];
    const token = req.headers['x-antibot-token'];
    const used = this.getState().auth.usedAntibotTokens;
    const key = `${route}|${String(token)}`;
    const valid =
      typeof provider === 'string' &&
      (PROVIDERS as readonly string[]).includes(provider) &&
      providers.includes(provider) &&
      typeof token === 'string' &&
      /^fake-ok-[A-Za-z0-9_-]{8,64}$/.test(token) &&
      !used.has(key);
    if (!valid) throw new ApiError(428, 'desafio_necessario', { providers });
    used.add(key);
  }
}
