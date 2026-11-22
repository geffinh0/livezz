// CFG14 com conta: Perfil → Configurações → Idioma. Caminho de erro: o
// servidor falha ao salvar; a troca vale na hora e o erro aparece.
const { flow } = require('./_lib.cjs');

flow('CFG14-conta', async (t) => {
  await t.open('/');
  await t.toMethods();
  await t.tap('entry.method.email');
  await t.type('auth.email.input', 'ana@teste.local');
  await t.type('auth.password.input', 'TEST_ONLY_Ana2026');
  await t.tap('auth.email.submit');
  t.check('logada', await t.visible('tab.discover', 20000));
  await t.tap('nav.profile');
  await t.tap('tab.profile.settings');
  t.check('configurações', await t.visible('settings'));
  await t.mock('/__mock/scenario/erro-500');
  await t.tap('settings.language.en');
  t.check('trocou na hora mesmo com falha', await t.text('Language'));
  t.check('erro do servidor aparece', await t.visible('auth.error', 10000));
  await t.mock('/__mock/scenario/erro-500', { active: false });
  await t.tap('settings.language.pt');
  t.check('voltou para português', await t.text('Idioma'));
});
