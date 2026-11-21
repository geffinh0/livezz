// ENT04 Telefone + código: envia, lê o código no outbox do mock, entra;
// erros: código errado e reenvio bloqueado por 60 s.
const { flow } = require('./_lib.cjs');

flow('ENT04', async (t) => {
  await t.open('/');
  await t.toMethods();
  await t.tap('entry.method.phone');
  t.check('tela do telefone', await t.visible('auth.phone'));
  await t.type('auth.phone.input', '11977776666');
  await t.shot('telefone');
  await t.tap('auth.phone.send');
  t.check('tela do código', await t.visible('auth.code'));
  t.check('reenviar começa bloqueado (contagem)', await t.text('Reenviar em'));

  await t.type('auth.code.input', '000001');
  await t.wait(800);
  const right = await t.outbox('+5511977776666');
  if (right === '000001') {
    t.check('código errado (pulado: sorteio igual)', true);
  } else {
    t.check('código errado mostra erro', await t.visible('auth.error'));
    t.check('texto do código incorreto', await t.text('Código incorreto'));
  }
  await t.shot('codigo-errado');
  await t.page.locator('[flt-semantics-identifier="auth.code.input"] input, [flt-semantics-identifier="auth.code.input"]').first().click();
  await t.page.keyboard.press('Control+A');
  await t.page.keyboard.press('Backspace');
  await t.page.keyboard.type(right, { delay: 20 });
  t.check('número novo: termos antes de tudo (ENT16)', await t.visible('auth.terms', 20000));
  await t.shot('termos');
});
