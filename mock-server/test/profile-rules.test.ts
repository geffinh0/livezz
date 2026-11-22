import { describe, expect, it } from 'vitest';
import {
  ageOn,
  checkDisplayName,
  isReserved,
  isValidDate,
  todayIn,
  usernameBase,
  usernameFormatOk,
} from '../src/profile/rules.js';

describe('regras de nome e @ (RN-05)', () => {
  it('nome de exibição: tamanho, espaços e palavras bloqueadas (com variações)', () => {
    expect(checkDisplayName('  Ana   Teste ', [])).toEqual({ ok: true, value: 'Ana Teste' });
    expect(checkDisplayName('A', [])).toEqual({ ok: false, reason: 'tamanho' });
    expect(checkDisplayName('x'.repeat(31), [])).toEqual({ ok: false, reason: 'tamanho' });
    expect(checkDisplayName('Seu 1d1ota', ['idiota'])).toEqual({ ok: false, reason: 'proibido' });
  });

  it('formato do @', () => {
    for (const ok of ['ana', 'ana.teste', 'a_b.c9', 'x'.repeat(20)]) expect(usernameFormatOk(ok)).toBe(true);
    for (const bad of ['an', 'Ana', '.ana', 'ana.', 'a..b', 'ana-b', 'x'.repeat(21), 'ána'])
      expect(usernameFormatOk(bad)).toBe(false);
  });

  it('reservados pegam a marca e variações', () => {
    const r = ['admin', 'suporte', 'liveapp'];
    expect(isReserved('adm1n', r)).toBe(true);
    expect(isReserved('suporte.oficial', r)).toBe(true);
    expect(isReserved('live.app2', r)).toBe(true);
    expect(isReserved('ana.teste', r)).toBe(false);
    // Sem falso positivo por trecho.
    expect(isReserved('groot', ['root'])).toBe(false);
    expect(isReserved('helpdesk.ana', ['help'])).toBe(false);
    expect(isReserved('adminx', r)).toBe(true);
  });

  it('sugestão base a partir do nome', () => {
    expect(usernameBase('Ana Lúcia')).toBe('ana.lucia');
    expect(usernameBase('Jo')).toBe('usuario');
  });
});

describe('idade (RN-01: só datas, fuso do tenant)', () => {
  it('faz 18 no dia do aniversário', () => {
    expect(ageOn('2008-11-21', '2026-11-21')).toBe(18);
    expect(ageOn('2008-11-22', '2026-11-21')).toBe(17);
    expect(ageOn('2008-12-01', '2026-11-21')).toBe(17);
  });

  it('o dia de hoje segue o fuso (meia-noite em UTC ainda é ontem em São Paulo)', () => {
    const now = new Date('2026-11-22T01:30:00Z');
    expect(todayIn('America/Sao_Paulo', now)).toBe('2026-11-21');
    expect(todayIn('UTC', now)).toBe('2026-11-22');
  });

  it('datas válidas', () => {
    expect(isValidDate('2000-02-29')).toBe(true);
    expect(isValidDate('2001-02-29')).toBe(false);
    expect(isValidDate('2000-13-01')).toBe(false);
    expect(isValidDate('01/02/2000')).toBe(false);
  });
});
