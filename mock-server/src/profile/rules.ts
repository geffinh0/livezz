// Regras de nome, @ e idade (RN-01, RN-05). Puras e testáveis; o servidor é a fonte da verdade.

/** Tira acentos e deixa minúsculo (para comparar com listas). */
export function fold(s: string): string {
  return s
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .toLowerCase();
}

// Troca de dígitos comuns para enxergar variações ("adm1n", "supp0rt").
const LEET: Record<string, string> = { '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '@': 'a' };
const unleet = (s: string) => s.replace(/[013457@]/g, (c) => LEET[c] ?? c);

/** RN-05: nome de exibição 2–30, sem palavras bloqueadas. Devolve o nome limpo ou o motivo. */
export function checkDisplayName(
  raw: string,
  blockedWords: readonly string[],
): { ok: true; value: string } | { ok: false; reason: 'tamanho' | 'proibido' } {
  const value = raw.replace(/\s+/g, ' ').trim();
  const len = [...value].length;
  if (len < 2 || len > 30) return { ok: false, reason: 'tamanho' };
  const folded = unleet(fold(value)).replace(/[^a-z]/g, '');
  if (blockedWords.some((w) => folded.includes(fold(w)))) return { ok: false, reason: 'proibido' };
  return { ok: true, value };
}

const USERNAME = /^[a-z0-9._]{3,20}$/;

/** RN-05: formato do @ (3–20, [a-z0-9._], sem ponto nas pontas nem pontos seguidos). */
export function usernameFormatOk(u: string): boolean {
  return USERNAME.test(u) && !u.startsWith('.') && !u.endsWith('.') && !u.includes('..');
}

/**
 * Reservado: termo da lista (ou a marca do tenant), inclusive com variações
 * ("adm1n", "suporte.oficial", "live.app"). Para não recusar @ inocentes
 * ("groot", "helpdesk.ana"), compara pedaço a pedaço e só aceita prefixo de
 * termos longos (≥ 5 letras: "adminx", "liveappbr").
 */
export function isReserved(u: string, reserved: readonly string[]): boolean {
  const l = unleet(u);
  const parts = l.split(/[._0-9]+/).filter(Boolean);
  const core = parts.join('');
  return reserved.some((r) => {
    const term = fold(r).replace(/[^a-z]/g, '');
    if (!term) return false;
    return core === term || parts.includes(term) || (term.length >= 5 && core.startsWith(term));
  });
}

/** Base de sugestão a partir do nome: "Ana Lúcia" → "ana.lucia". */
export function usernameBase(displayName: string | null): string {
  const base = fold(displayName ?? '')
    .replace(/[^a-z0-9]+/g, '.')
    .replace(/^\.+|\.+$/g, '')
    .slice(0, 16);
  return base.length >= 3 ? base : 'usuario';
}

/** Data de hoje (AAAA-MM-DD) no fuso do tenant (RN-01). */
export function todayIn(timeZone: string, now: Date): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(now);
}

/** Data válida no formato AAAA-MM-DD. */
export function isValidDate(d: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(d)) return false;
  const dt = new Date(`${d}T00:00:00Z`);
  return !Number.isNaN(dt.getTime()) && dt.toISOString().slice(0, 10) === d;
}

/** Idade em anos completos comparando só datas (faz aniversário no próprio dia). */
export function ageOn(birthDate: string, today: string): number {
  const [by, bm, bd] = birthDate.split('-').map(Number) as [number, number, number];
  const [ty, tm, td] = today.split('-').map(Number) as [number, number, number];
  let age = ty - by;
  if (tm < bm || (tm === bm && td < bd)) age -= 1;
  return age;
}
