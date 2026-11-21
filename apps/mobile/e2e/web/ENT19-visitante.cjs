// ENT19 Sessão: quem explorava sem conta e entrou pelo pedido de conta (ENT17)
// também volta às boas-vindas com o aviso quando a conta entra em outro aparelho.
const { flow, clickId } = require('./_lib.cjs');

async function typeInto(page, id, text) {
  await clickId(page, id);
  await page.waitForTimeout(300);
  await page.keyboard.type(text, { delay: 10 });
}

flow('ENT19-visitante', async (t) => {
  await t.open('/');
  await t.button('Explorar sem conta').click();
  t.check('visitante na Home', await t.visible('tab.discover'));
  await t.tap('nav.profile');
  await t.tap('entry.accountRequired.login');
  await t.tap('entry.method.email');
  await t.type('auth.email.input', 'ana@teste.local');
  await t.type('auth.password.input', 'TEST_ONLY_Ana2026');
  await t.tap('auth.email.submit');
  t.check('entrou e voltou ao Perfil', await t.visible('tab.profile', 20000));

  const other = await t.newPage();
  await other.goto(process.env.APP_URL || 'http://localhost:8080/', { waitUntil: 'load' });
  await other.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 30000 });
  await other.locator('flt-semantics-placeholder').evaluate((e) => e.click());
  await clickId(other, 'entry.welcome.login');
  await clickId(other, 'entry.method.email');
  await typeInto(other, 'auth.email.input', 'ana@teste.local');
  await typeInto(other, 'auth.password.input', 'TEST_ONLY_Ana2026');
  await clickId(other, 'auth.email.submit');
  await other.locator('[flt-semantics-identifier="tab.discover"]').first().waitFor({ state: 'attached', timeout: 20000 });

  t.check('primeiro aparelho volta às boas-vindas com aviso', await t.visible('entry.sessionNotice', 20000));
  await t.shot('aviso');
  await t.tap('entry.welcome.explore');
  t.check('depois do aviso pode seguir como visitante', await t.visible('tab.discover', 10000));
});
