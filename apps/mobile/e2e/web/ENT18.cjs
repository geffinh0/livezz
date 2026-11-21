// ENT18 Restrição regional: fora da região mostra tela informativa.
const { flow } = require('./_lib.cjs');

flow('ENT18', async (t) => {
  await t.mock('/__mock/scenario/regiao-bloqueada');
  await t.open('/');
  t.check('fora da região mostra o portão', await t.visible('gate.region'));
  t.check('texto explica a restrição', await t.text('não está disponível na sua região'));
  await t.shot('regiao');
  await t.mock('/__mock/scenario/regiao-bloqueada', { active: false });
  await t.button('Tentar de novo').click();
  t.check('dentro da região libera', await t.visible('entry.welcome'));
});
