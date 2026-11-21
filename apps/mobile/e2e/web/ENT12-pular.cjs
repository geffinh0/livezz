// ENT12: pular também termina o cadastro.
const { flow } = require('./_lib.cjs');

flow('ENT12-pular', async (t) => {
  await t.open('/');
  await t.newAccount('11955550031');
  await t.type('onboarding.profile.name', 'Pessoa Pula');
  await t.pickDate('onboarding.profile.birth', '10/04/1990');
  await t.tap('onboarding.profile.submit');
  await t.visible('onboarding.username', 20000);
  await t.type('onboarding.username.input', 'pessoa.pula');
  await t.text('Disponível');
  await t.tap('onboarding.username.submit');
  await t.visible('onboarding.interests', 20000);
  await t.tap('onboarding.interests.skip');
  t.check('pulou: Home', await t.visible('tab.discover', 20000));
});
