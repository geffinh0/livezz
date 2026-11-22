// ENT10 Menor de idade: data de menor → bloqueio com suporte e protocolo;
// reabrir continua bloqueado (sem "voltar e mudar a data").
const { flow } = require('./_lib.cjs');

flow('ENT10', async (t) => {
  await t.open('/');
  await t.newAccount('11955550010');
  t.check('cadastro', await t.visible('onboarding.profile', 20000));
  await t.type('onboarding.profile.name', 'Jovem E2E');
  await t.pickDate('onboarding.profile.birth', '01/06/2015');
  await t.tap('onboarding.profile.submit');
  t.check('menor: tela de bloqueio', await t.visible('minor.blocked', 20000));
  t.check('mostra o protocolo', await t.visible('minor.blocked.protocol'));
  t.check('mostra o contato de suporte do tenant', await t.visible('minor.blocked.support'));
  await t.shot('bloqueio');
  await t.open('/', { fresh: false });
  // A sessão já foi apagada no 403: quem bloqueia agora é o aparelho marcado (Q-65).
  t.check('reabrir continua bloqueado (aparelho marcado, sem sessão)', await t.visible('minor.blocked', 20000));
  t.check('sem boas-vindas nem login', !(await t.visible('entry.welcome', 1500)));
});
