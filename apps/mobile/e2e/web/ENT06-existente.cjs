// ENT06 Google (conta de teste do mock, Q-53): conta existente com e-mail
// confirmado entra direto, sem termos nem cadastro.
const { flow } = require('./_lib.cjs');

flow('ENT06-existente', async (t) => {
  await t.open('/');
  await t.toMethods();
  await t.tap('entry.method.google');
  await t.tap('auth.google.existing');
  t.check('conta existente entra direto', await t.visible('tab.discover', 20000));
});
