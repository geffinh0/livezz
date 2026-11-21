// ENT17 Login exigido: visitante tentando interagir vê o pedido de conta.
const { flow } = require('./_lib.cjs');

flow('ENT17', async (t) => {
  await t.open('/');
  await t.button('Explorar sem conta').click();
  t.check('visitante na Home', await t.visible('tab.discover'));
  for (const tab of ['profile', 'messages', 'live']) {
    await t.byId(`nav.${tab}`).click();
    t.check(`${tab} pede conta`, await t.visible('entry.accountRequired'));
    if (tab === 'profile') await t.shot('pedido-de-conta');
    await t.dismiss();
    t.check(`${tab}: pedido de conta fecha ao tocar fora`, await t.gone('entry.accountRequired'));
  }
  await t.byId('nav.profile').click();
  await t.visible('entry.accountRequired');
  await t.byId('entry.accountRequired.login').click();
  t.check('do pedido de conta vai para a escolha de entrada', await t.visible('entry.methods'));
});
