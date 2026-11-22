// ENT08 Dados iniciais: nome, data (não muda depois) e gênero opcional; erro no campo.
const { flow } = require('./_lib.cjs');

flow('ENT08', async (t) => {
  await t.open('/');
  await t.newAccount('11955550001');
  t.check('conta nova cai em "Seus dados"', await t.visible('onboarding.profile', 20000));
  // Erro: enviar vazio mostra os erros no próprio campo e não sai da tela.
  await t.tap('onboarding.profile.submit');
  t.check('nome vazio: erro no campo', await t.text('Use de 2 a 30 caracteres.'));
  t.check('data vazia: erro no campo', await t.text('Informe sua data de nascimento.'));
  await t.shot('erros');
  // Erro do servidor: nome com palavra proibida volta no próprio campo.
  await t.type('onboarding.profile.name', 'Sou idiota');
  await t.pickDate('onboarding.profile.birth', '10/04/1995');
  await t.tap('onboarding.profile.submit');
  t.check('nome proibido pelo servidor: erro no campo', await t.text('Este nome não é permitido'));
  await t.clear('onboarding.profile.name');
  await t.type('onboarding.profile.name', 'Pessoa E2E');
  await t.tap('onboarding.profile.gender.prefiro_nao_dizer');
  await t.shot('preenchido');
  await t.tap('onboarding.profile.submit');
  t.check('segue para escolher o @ (ENT11)', await t.visible('onboarding.username', 20000));
});
