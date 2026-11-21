// ENT17 Login exigido: visitante tentando interagir vê o pedido de conta.
const { flow } = require('./_lib.cjs');

flow('ENT17', async (t) => {
  await t.open('/');
  await t.button('Explorar sem conta').click();
  t.check('visitante na Home', await t.visible('tab.discover'));
  for (const tab of ['profile', 'messages', 'live']) {
    await t.tap(`nav.${tab}`);
    t.check(`${tab} pede conta`, await t.visible('entry.accountRequired'));
    if (tab === 'profile') await t.shot('pedido-de-conta');
    await t.dismiss();
    t.check(`${tab}: pedido de conta fecha ao tocar fora`, await t.gone('entry.accountRequired'));
  }
  await t.tap('nav.profile');
  await t.visible('entry.accountRequired');
  await t.tap('entry.accountRequired.login');
  t.check('do pedido de conta vai para a escolha de entrada', await t.visible('entry.methods'));

  // Entra de verdade e volta para a ação que tentou (Perfil).
  await t.tap('entry.method.email');
  await t.type('auth.email.input', 'ana@teste.local');
  // Erro: senha errada mostra o erro e não perde a ação guardada.
  await t.type('auth.password.input', 'senhaErrada1');
  await t.tap('auth.email.submit');
  t.check('senha errada mostra erro', await t.visible('auth.error', 10000));
  await t.clear('auth.password.input');
  await t.type('auth.password.input', 'TEST_ONLY_Ana2026');
  await t.tap('auth.email.submit');
  t.check('depois de entrar, continua no Perfil (ação retomada)', await t.visible('tab.profile', 20000));
  await t.shot('retomou');
});
