// ENT11 Criar @: ocupado mostra motivo e sugestões; sugestão disponível segue.
const { flow } = require('./_lib.cjs');

flow('ENT11', async (t) => {
  await t.open('/');
  await t.newAccount('11955550020');
  await t.type('onboarding.profile.name', 'Ana Lúcia');
  await t.pickDate('onboarding.profile.birth', '10/04/1995');
  await t.tap('onboarding.profile.submit');
  t.check('passo do @', await t.visible('onboarding.username', 20000));
  await t.type('onboarding.username.input', 'ana.teste');
  t.check('ocupado: motivo no campo', await t.text('Já está em uso.'));
  t.check('sugestão aparece', await t.visible('onboarding.username.suggestion.0'));
  await t.shot('ocupado');
  await t.tap('onboarding.username.suggestion.0');
  t.check('sugestão disponível', await t.text('Disponível'));
  await t.tap('onboarding.username.submit');
  t.check('segue para interesses (ENT12)', await t.visible('onboarding.interests', 20000));
});
