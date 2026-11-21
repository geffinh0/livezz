// Validação do tenants/<id>/tenant.json (sem dependências externas).
// Marca, cores, URLs e IDs públicos do cliente moram no tenant (CLAUDE.md, regra 7).
// Flags de funcionalidade aqui são só o valor inicial da config do servidor (mock);
// o app nunca lê flags do tenant (servidor autoritativo).

const HEX = /^#[0-9A-Fa-f]{6}$/;
const PACKAGE = /^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/;
const ID = /^[a-z][a-z0-9]{1,30}$/; // sem hífen: vira nome de flavor do Android
const LOCALES = new Set(['pt-BR', 'en']);
const THEME_MODES = new Set(['light', 'dark', 'system']);
const THEME_COLORS = [
  'primary',
  'primaryAction',
  'onPrimaryAction',
  'secondary',
  'onSecondary',
  'darkBackground',
  'lightBackground',
];
// Fora do produto (ADR 0006 / Q-18): nunca pode ser ligado.
const FORBIDDEN_FEATURES = ['games'];

function isUrl(v) {
  try {
    const u = new URL(v);
    return u.protocol === 'http:' || u.protocol === 'https:';
  } catch {
    return false;
  }
}

/** @returns {string[]} lista de erros (vazia = válido) */
export function validateTenant(t, expectedId) {
  const e = [];
  if (typeof t !== 'object' || t === null) return ['tenant.json deve ser um objeto'];
  if (!ID.test(t.id ?? '')) e.push('id inválido (minúsculas e números, sem hífen)');
  if (expectedId && t.id !== expectedId) e.push(`id "${t.id}" difere da pasta "${expectedId}"`);
  if (typeof t.appName !== 'string' || !t.appName.trim()) e.push('appName obrigatório');
  if (!PACKAGE.test(t.androidPackage ?? '')) e.push('androidPackage inválido');
  for (const k of ['apiBaseUrl', 'portalBaseUrl']) if (!isUrl(t[k])) e.push(`${k} deve ser URL http(s)`);
  const th = t.theme ?? {};
  for (const c of THEME_COLORS) if (!HEX.test(th[c] ?? '')) e.push(`theme.${c} deve ser cor #RRGGBB`);
  if (typeof th.fontFamily !== 'string' || !th.fontFamily.trim()) e.push('theme.fontFamily obrigatório');
  if (th.iconSet !== 'material-symbols') e.push('theme.iconSet suportado: material-symbols');
  if (!Array.isArray(t.supportedLocales) || t.supportedLocales.length === 0) {
    e.push('supportedLocales obrigatório');
  } else {
    for (const l of t.supportedLocales) if (!LOCALES.has(l)) e.push(`locale não suportado: ${l}`);
    if (!t.supportedLocales.includes(t.defaultLocale)) e.push('defaultLocale precisa estar em supportedLocales');
  }
  if (!Array.isArray(t.themeModes) || t.themeModes.some((m) => !THEME_MODES.has(m))) {
    e.push('themeModes aceita light, dark, system');
  }
  const f = t.features ?? {};
  for (const [k, v] of Object.entries(f)) if (typeof v !== 'boolean') e.push(`features.${k} deve ser booleano`);
  for (const k of FORBIDDEN_FEATURES) if (f[k] === true) e.push(`features.${k} é fora do produto e não pode ser ligado`);
  if (!Array.isArray(t.allowedRegions) || t.allowedRegions.some((r) => !/^[A-Z]{2}$/.test(r))) {
    e.push('allowedRegions: códigos de país ISO de 2 letras');
  }
  return e;
}
