// ENT07 Recuperar senha: código por e-mail → nova senha → entra com a nova.
const { flow } = require('./_lib.cjs');

flow('ENT07', async (t) => {
  await t.open('/');
  await t.toMethods();
  await t.tap('entry.method.email');
  await t.tap('auth.email.forgot');
  t.check('tela de recuperar', await t.visible('auth.reset'));
  await t.type('auth.reset.email', 'carla@teste.local');
  await t.tap('auth.reset.submit');
  t.check('pede código e nova senha', await t.visible('auth.reset.code'));
  const code = await t.outbox('carla@teste.local');
  await t.type('auth.reset.code', code);
  await t.type('auth.reset.password', 'NovaE2e2026');
  await t.tap('auth.reset.submit');
  t.check('volta para entrar com e-mail', await t.visible('auth.email', 20000));
  await t.type('auth.email.input', 'carla@teste.local');
  await t.type('auth.password.input', 'NovaE2e2026');
  await t.tap('auth.email.submit');
  t.check('entra com a senha nova', await t.visible('tab.discover', 20000));
});
