// Textos de interface em pt-BR e inglês (TRV07). Nada de texto fixo nos componentes.
export const messages = {
  'pt-BR': {
    title: 'Painel do comprador',
    description: 'Administração de usuários, lives, economia, moderação e integrações (Fase 9).',
    configVersion: 'Versão da config',
    apiOffline: 'Servidor indisponível no momento.',
  },
  en: {
    title: 'Buyer dashboard',
    description: 'Users, lives, economy, moderation and integrations (Phase 9).',
    configVersion: 'Config version',
    apiOffline: 'Server unavailable right now.',
  },
} as const;

export type Locale = keyof typeof messages;
export type Messages = (typeof messages)[Locale];

export function pickLocale(acceptLanguage: string | null | undefined, fallback: string): Locale {
  const wanted = (acceptLanguage ?? '').toLowerCase();
  if (wanted.startsWith('en')) return 'en';
  if (wanted.startsWith('pt')) return 'pt-BR';
  return fallback === 'en' ? 'en' : 'pt-BR';
}
