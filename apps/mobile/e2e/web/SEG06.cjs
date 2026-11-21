// SEG06 Anti-bot: com desafio exigido pelo servidor, o app resolve (fake) e segue.
const { flow } = require('./_lib.cjs');

flow('SEG06', async (t) => {
  await t.mock('/__mock/scenario/exigir-desafio');
  await t.open('/');
  await t.toMethods();
  await t.tap('entry.method.phone');
  await t.type('auth.phone.input', '11966665555');
  await t.tap('auth.phone.send');
  t.check('desafio resolvido: código enviado', await t.visible('auth.code', 20000));
  const code = await t.outbox('+5511966665555');
  await t.type('auth.code.input', code);
  t.check('entrou mesmo com desafio exigido', await t.visible('auth.terms', 20000));
});
