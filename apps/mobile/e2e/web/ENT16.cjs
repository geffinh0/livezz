// ENT16 Termos: nova versão exige novo aceite antes de continuar.
const { flow } = require('./_lib.cjs');

async function loginAna(t) {
  await t.toMethods();
  await t.tap('entry.method.email');
  await t.type('auth.email.input', 'ana@teste.local');
  await t.type('auth.password.input', 'TEST_ONLY_Ana2026');
  await t.tap('auth.email.submit');
}

flow('ENT16', async (t) => {
  await t.open('/');
  await loginAna(t);
  t.check('termos em dia: entra direto', await t.visible('tab.discover', 20000));
  await t.mock('/__mock/scenario/termos-novos');
  await t.open('/', { fresh: false }); // reabre: sessão restaurada, termos novos
  t.check('nova versão pede aceite', await t.visible('auth.terms', 20000));
  t.check('mostra a versão 2', await t.text('Versão 2'));
  await t.shot('termos-novos');
  t.check('aceitar fica desligado sem marcar', !(await t.visible('tab.discover', 1500)));
  await t.tap('auth.terms.agree');
  await t.tap('auth.terms.accept');
  t.check('aceitou: segue para a Home', await t.visible('tab.discover', 20000));
});
