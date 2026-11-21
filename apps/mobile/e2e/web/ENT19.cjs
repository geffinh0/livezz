// ENT19 Sessão: um aparelho por conta (2º login derruba o 1º com aviso) e
// renovação automática do token.
const { flow, clickId } = require('./_lib.cjs');

async function loginAna(t, page) {
  await clickId(page, 'entry.welcome.login');
  await clickId(page, 'entry.method.email');
  await clickId(page, 'auth.email.input');
  await page.waitForTimeout(300);
  await page.keyboard.type('ana@teste.local', { delay: 10 });
  await clickId(page, 'auth.password.input');
  await page.waitForTimeout(300);
  await page.keyboard.type('TEST_ONLY_Ana2026', { delay: 10 });
  await clickId(page, 'auth.email.submit');
}

flow('ENT19', async (t) => {
  // Renovação: access de 5 s; depois de vencer, reabrir continua logado.
  await t.mock('/__mock/scenario/token-expira-rapido');
  await t.open('/');
  await loginAna(t, t.page);
  t.check('logado', await t.visible('tab.discover', 20000));
  await t.wait(6500);
  await t.open('/', { fresh: false });
  t.check('token vencido renovado sozinho (continua logado)', await t.visible('tab.discover', 20000));
  await t.mock('/__mock/scenario/token-expira-rapido', { active: false });

  // Outro aparelho: segundo navegador entra na mesma conta.
  const other = await t.newPage();
  await other.goto(process.env.APP_URL || 'http://localhost:8080/', { waitUntil: 'load' });
  await other.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 30000 });
  await other.locator('flt-semantics-placeholder').evaluate((e) => e.click());
  await loginAna(t, other);
  await other.locator('[flt-semantics-identifier="tab.discover"]').first().waitFor({ state: 'attached', timeout: 20000 });
  t.check('primeiro aparelho volta às boas-vindas com aviso', await t.visible('entry.sessionNotice', 20000));
  t.check('aviso diz "outro aparelho"', await t.text('outro aparelho'));
  await t.shot('outro-aparelho');
});
