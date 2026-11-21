// ENT02 Boas-vindas e modo visitante · ENT03 Escolha do método de entrada.
const { flow } = require('./_lib.cjs');

flow('ENT02-ENT03', async (t) => {
  await t.open('/');
  t.check('boas-vindas com a marca', await t.text('liveapp'));
  await t.shot('boas-vindas');

  await t.button('Entrar').click();
  t.check('escolha de entrada abre', await t.visible('entry.methods'));
  t.check('telefone (flag ligada)', await t.visible('entry.method.phone'));
  t.check('e-mail (flag ligada)', await t.visible('entry.method.email'));
  t.check('Google (flag ligada)', await t.visible('entry.method.google'));
  t.check('aviso 18+', await t.visible('entry.adultsOnly'));
  await t.shot('metodos');

  await t.button('Termos de uso').click();
  t.check('termos abrem com a URL do portal', await t.visible('legal.terms'));
  t.check('URL dos termos vem da config', await t.text('/legal/termos'));
  await t.page.goBack();
  await t.wait(800);

  await t.page.goBack();
  await t.wait(800);
  await t.button('Explorar sem conta').click();
  t.check('explorar sem conta vai para Descobrir', await t.visible('tab.discover'));

  await t.open('/', { fresh: false });
  t.check('escolha de visitante é lembrada', await t.visible('tab.discover'));
});
