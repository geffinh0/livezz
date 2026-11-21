// ENT17 Login exigido: visitante tentando interagir vê o pedido de conta.
const { flow } = require('./_lib.cjs');

flow('ENT17', async (t) => {
  await t.open('/');
  await t.button('Explorar sem conta').click();
  t.check('visitante na Home', await t.visible('tab.discover'));
  for (const tab of ['Perfil', 'Mensagens', 'Ao vivo']) {
    await t.button(tab).click();
    t.check(`${tab} pede conta`, await t.visible('entry.accountRequired'));
    if (tab === 'Perfil') await t.shot('pedido-de-conta');
    await t.page.keyboard.press('Escape');
    await t.gone('entry.accountRequired');
  }
  await t.button('Perfil').click();
  await t.visible('entry.accountRequired');
  await t.button('Entrar').click();
  t.check('do pedido de conta vai para a escolha de entrada', await t.visible('entry.methods'));
});
