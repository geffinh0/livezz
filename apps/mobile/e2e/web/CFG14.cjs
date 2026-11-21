// CFG14 Idioma: troca sem reiniciar (boas-vindas → Idioma → English).
const { flow } = require('./_lib.cjs');

flow('CFG14', async (t) => {
  await t.open('/');
  t.check('começa em português', await t.text('Explorar sem conta'));
  await t.tap('entry.welcome.language');
  t.check('tela de idioma', await t.visible('settings'));
  await t.tap('settings.language.en');
  t.check('trocou na hora', await t.text('Language'));
  await t.shot('ingles');
  await t.page.goBack();
  t.check('boas-vindas em inglês', await t.text('Explore without an account'));
  await t.open('/', { fresh: false });
  t.check('escolha lembrada ao reabrir', await t.text('Explore without an account'));
});
