// ENT05 E-mail + senha: cadastro com confirmação por código; login errado não revela.
const { flow } = require('./_lib.cjs');

flow('ENT05', async (t) => {
  await t.open('/');
  await t.toMethods();
  await t.tap('entry.method.email');
  t.check('tela de e-mail', await t.visible('auth.email'));

  // erro: senha errada para conta existente — mensagem genérica
  await t.type('auth.email.input', 'ana@teste.local');
  await t.type('auth.password.input', 'Errada2026x');
  await t.tap('auth.email.submit');
  t.check('senha errada mostra erro genérico', await t.text('E-mail ou senha incorretos'));
  await t.shot('erro');

  // cadastro
  await t.button('Criar conta').first().click();
  await t.page.locator('[flt-semantics-identifier="auth.email.input"]').first().click();
  await t.page.keyboard.press('Control+A');
  await t.page.keyboard.type('nova.e2e@teste.local', { delay: 10 });
  await t.page.locator('[flt-semantics-identifier="auth.password.input"]').first().click();
  await t.page.keyboard.press('Control+A');
  await t.page.keyboard.type('Livezz2026e2e', { delay: 10 });
  await t.wait(300);
  await t.shot('cadastro');
  await t.tap('auth.email.submit');
  t.check('pede o código de confirmação', await t.visible('auth.code'));
  const code = await t.outbox('nova.e2e@teste.local');
  await t.type('auth.code.input', code);
  t.check('confirmado: conta nova cai nos termos (ENT16)', await t.visible('auth.terms', 20000));
});
