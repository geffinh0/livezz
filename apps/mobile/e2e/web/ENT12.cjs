// ENT12 Interesses: categorias do servidor; escolher e continuar entra na Home.
// Caminho de erro: falha do servidor ao salvar mostra o erro e fica na tela.
const { flow } = require('./_lib.cjs');

flow('ENT12', async (t) => {
  await t.open('/');
  await t.newAccount('11955550030');
  await t.type('onboarding.profile.name', 'Pessoa Interesses');
  await t.pickDate('onboarding.profile.birth', '10/04/1990');
  await t.tap('onboarding.profile.submit');
  await t.visible('onboarding.username', 20000);
  await t.type('onboarding.username.input', 'pessoa.interesses');
  await t.text('Disponível');
  await t.tap('onboarding.username.submit');
  t.check('categorias do servidor', await t.visible('onboarding.interests.musica', 20000));
  await t.tap('onboarding.interests.musica');
  await t.tap('onboarding.interests.danca');
  await t.shot('escolhidos');
  await t.mock('/__mock/scenario/erro-500');
  await t.tap('onboarding.interests.submit');
  t.check('erro ao salvar aparece', await t.visible('auth.error', 10000));
  await t.mock('/__mock/scenario/erro-500', { active: false });
  await t.tap('onboarding.interests.submit');
  t.check('cadastro completo: Home', await t.visible('tab.discover', 20000));
});
