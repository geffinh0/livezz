// ENT01 Splash e inicialização: decide o destino; erro com "tentar de novo";
// portões de manutenção e atualização.
const { flow } = require('./_lib.cjs');

flow('ENT01', async (t) => {
  await t.open('/');
  t.check('sem sessão vai para boas-vindas', await t.visible('entry.welcome'));

  await t.mock('/__mock/scenario/erro-500');
  await t.open('/');
  t.check('erro 500 mostra tela de erro', await t.visible('state.error'));
  await t.shot('erro');
  await t.mock('/__mock/scenario/erro-500', { active: false });
  await t.tap('state.error.action');
  t.check('"tentar de novo" recupera', await t.visible('entry.welcome'));

  await t.mock('/__mock/scenario/manutencao');
  await t.open('/');
  t.check('manutenção mostra o portão', await t.visible('gate.maintenance'));
  await t.shot('manutencao');
  await t.mock('/__mock/scenario/manutencao', { active: false });
  // O app pode liberar sozinho (rebusca da config) ou pelo "tentar de novo".
  if (await t.visible('gate.maintenance.action', 1500)) {
    await t.tap('gate.maintenance.action').catch(() => {});
  }
  t.check('manutenção acabou: libera', await t.visible('entry.welcome'));

  await t.mock('/__mock/scenario/versao-minima');
  await t.open('/');
  t.check('versão mínima abre o portão de atualização', await t.visible('gate.update'));
  await t.shot('atualizacao');
});
