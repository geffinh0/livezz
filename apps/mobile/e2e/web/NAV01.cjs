// NAV01 Navegação principal: abas, estado por aba e Seguindo para visitante.
const { flow } = require('./_lib.cjs');

flow('NAV01', async (t) => {
  await t.open('/');
  await t.button('Explorar sem conta').click();
  t.check('barra com Descobrir', await t.visible('nav.discover'));
  for (const id of ['nav.following', 'nav.live', 'nav.messages', 'nav.profile']) {
    t.check(`barra com ${id}`, await t.visible(id));
  }
  await t.shot('descobrir');
  await t.tap('nav.following');
  t.check('Seguindo para visitante mostra convite (Q-49)', await t.text('Entre para ver quem você segue'));
  t.check('Seguindo não abre o pedido de conta', !(await t.visible('entry.accountRequired', 1500)));
  await t.shot('seguindo');
  await t.tap('nav.discover');
  t.check('volta para Descobrir', await t.visible('tab.discover'));
});
