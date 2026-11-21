import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateTenant } from './schema.mjs';
import { loadTenant, toDart, toTs } from './generate.mjs';

const valid = () => structuredClone(loadTenant('liveapp'));

test('tenant liveapp é válido', () => {
  assert.deepEqual(validateTenant(valid(), 'liveapp'), []);
});

test('rejeita cor fora do formato', () => {
  const t = valid();
  t.theme.primary = 'DEFINIR';
  assert.match(validateTenant(t).join(), /theme.primary/);
});

test('rejeita jogos ligados (fora do produto)', () => {
  const t = valid();
  t.features.games = true;
  assert.match(validateTenant(t).join(), /games/);
});

test('rejeita id diferente da pasta e locale fora da lista', () => {
  const t = valid();
  t.defaultLocale = 'es';
  const errs = validateTenant(t, 'outro').join();
  assert.match(errs, /difere da pasta/);
  assert.match(errs, /defaultLocale/);
});

test('Dart gerado contém marca e cores, sem flags', () => {
  const dart = toDart(valid());
  assert.match(dart, /appName: 'liveapp'/);
  assert.match(dart, /primary: Color\(0xFFE91E8C\)/);
  assert.match(dart, /fontFamily: 'Plus Jakarta Sans'/);
  assert.doesNotMatch(dart, /luckyGift|features/);
});

test('Dart escapa aspas e cifrão', () => {
  const t = valid();
  t.appName = "Live's $app";
  assert.match(toDart(t), /appName: 'Live\\'s \\\$app'/);
});

test('TS gerado não leva flags', () => {
  assert.doesNotMatch(toTs(valid()), /features/);
});
