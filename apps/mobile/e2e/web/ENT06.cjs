// ENT06 Google (contas de teste do mock, Q-53): nova → cadastro; falha; cancelar.
const { flow } = require('./_lib.cjs');

flow('ENT06', async (t) => {
  await t.open('/');
  await t.toMethods();
  await t.tap('entry.method.google');
  t.check('lista de contas de teste', await t.visible('auth.google'));
  await t.shot('contas');
  await t.tap('auth.google.failing');
  t.check('conta que falha mostra erro', await t.visible('auth.error'));
  await t.tap('auth.google.cancel');
  t.check('cancelar volta para a escolha de entrada', await t.visible('entry.methods'));
  await t.tap('entry.method.google');
  await t.tap('auth.google.new');
  t.check('conta nova: termos antes do cadastro', await t.visible('auth.terms', 20000));
  await t.tap('auth.terms.agree');
  await t.tap('auth.terms.accept');
  t.check('depois dos termos: complete seu cadastro (1c)', await t.visible('auth.completeProfile', 20000));
  await t.shot('complete-cadastro');
});
