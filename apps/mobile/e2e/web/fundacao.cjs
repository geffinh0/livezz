// Fundação (TRV): vitrine de debug, tema, idioma, tempo real, erro e portões.
const { flow } = require('./_lib.cjs');

flow('TRV', async (t) => {
  await t.open('/dev/showcase');
  t.check('vitrine abre', await t.visible('showcase.appName'));
  t.check('config carregada', await t.visible('showcase.configVersion'));
  t.check('tempo real conectado', await t.visible('showcase.realtime.connected'));
  await t.shot('claro-pt');

  await t.button('Escuro').click();
  await t.button('en').click();
  await t.wait(800);
  t.check('troca para inglês', await t.text('Foundation showcase'));
  await t.shot('escuro-en');

  const before = (await t.config()).configVersion;
  await t.mock('/__mock/scenario/manutencao');
  await t.wait(1500);
  t.check(`config.updated chega (${before} → ${before + 1})`, await t.text(`Config version: ${before + 1}`));
  await t.mock('/__mock/scenario/manutencao', { active: false });

  await t.button('Light').click();
  await t.button('pt-BR').click();
  await t.button('Abrir bottom sheet').click();
  await t.wait(800);
  t.check('bottom sheet abre', await t.text('Fluxos da live abrem aqui'));
  await t.page.keyboard.press('Escape');
  await t.wait(600);
  await t.button('Abrir diálogo').click();
  await t.wait(800);
  t.check('diálogo abre', await t.text('Confirmações usam este diálogo.'));
  await t.shot('dialogo');
});
