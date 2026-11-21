const { chromium } = require('playwright');
// E2E do app no navegador (Flutter web + Playwright). Mesmo roteiro do
// e2e/TRV-fundacao.yaml (Maestro), mais tema, idioma e componentes.
// Use via tools/dev/e2e-web.sh (compila, sobe mock-server e app, roda isto).
const out = process.argv[2] || 'build/e2e-web';
const APP = process.env.APP_URL || 'http://localhost:8080/';
require('fs').mkdirSync(out, { recursive: true });
const MOCK = process.env.MOCK_URL || 'http://127.0.0.1:3000';
const results = [];
const check = (name, ok) => { results.push(`${ok ? 'OK  ' : 'FALHOU'} ${name}`); };
const mock = (path, body) => fetch(MOCK + path, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body ?? {}) });
const byId = (page, id) => page.locator(`[flt-semantics-identifier="${id}"]`);

async function open(page) {
  await page.goto(APP, { waitUntil: 'load' });
  await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 30000 });
  await page.locator('flt-semantics-placeholder').evaluate((e) => e.click());
}
async function visible(page, id, timeout = 20000) {
  try { await byId(page, id).first().waitFor({ state: 'attached', timeout }); return true; } catch { return false; }
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 412, height: 915 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));

  // Caminho principal
  await mock('/__mock/reset');
  await open(page);
  check('vitrine abre (showcase.appName)', await visible(page, 'showcase.appName'));
  check('config carregada (showcase.configVersion)', await visible(page, 'showcase.configVersion'));
  check('tempo real conectado', await visible(page, 'showcase.realtime.connected'));
  await page.screenshot({ path: `${out}/02-claro-pt.png` });

  // Tema escuro e inglês
  await page.getByRole('button', { name: 'Escuro', exact: true }).click();
  await page.getByRole('button', { name: 'en', exact: true }).click();
  await page.waitForTimeout(800);
  check('troca para inglês', (await page.getByText('Foundation showcase').count()) > 0);
  await page.screenshot({ path: `${out}/03-escuro-en.png` });

  // config.updated em tempo real: manutenção liga e a tela some/troca
  const before = (await (await fetch(MOCK + '/v1/config')).json()).configVersion;
  check(`tela mostra a versão atual (${before})`, (await page.getByText(`Config version: ${before}`).count()) > 0);
  await mock('/__mock/scenario/manutencao');
  await page.waitForTimeout(1500);
  check(`config.updated chega pelo WebSocket (${before} → ${before + 1})`,
    (await page.getByText(`Config version: ${before + 1}`).count()) > 0);
  await mock('/__mock/scenario/manutencao', { active: false });

  // Bottom sheet e diálogo
  await page.getByRole('button', { name: 'Light', exact: true }).click();
  await page.getByRole('button', { name: 'pt-BR', exact: true }).click();
  await page.getByRole('button', { name: 'Abrir bottom sheet', exact: true }).click();
  await page.waitForTimeout(800);
  check('bottom sheet abre', (await page.getByText('Fluxos da live abrem aqui').count()) > 0);
  await page.screenshot({ path: `${out}/04-sheet.png` });
  await page.keyboard.press('Escape');
  await page.waitForTimeout(600);
  await page.getByRole('button', { name: 'Abrir diálogo', exact: true }).click();
  await page.waitForTimeout(800);
  check('diálogo abre', (await page.getByText('Confirmações usam este diálogo.').count()) > 0);
  await page.screenshot({ path: `${out}/05-dialogo.png` });
  await page.getByRole('button', { name: 'Cancelar', exact: true }).click();

  // Caminho de erro: erro 500 → tela de erro → tentar de novo
  await mock('/__mock/scenario/erro-500');
  await page.evaluate(() => localStorage.clear());
  await open(page);
  check('erro 500 mostra tela de erro', await visible(page, 'state.error'));
  await page.screenshot({ path: `${out}/06-erro.png` });
  await mock('/__mock/scenario/erro-500', { active: false });
  await byId(page, 'state.error.action').first().locator('flt-semantics, [role=button]').first().click().catch(async () => {
    await page.getByRole('button', { name: 'Tentar de novo', exact: true }).click();
  });
  check('tentar de novo recupera', await visible(page, 'showcase.appName'));
  await page.screenshot({ path: `${out}/07-recuperado.png` });

  // Versão mínima acima da do app → portão de atualização
  await mock('/__mock/reset');
  await mock('/__mock/scenario/versao-minima');
  await open(page);
  check('versão mínima abre o portão de atualização', await visible(page, 'gate.update'));
  await page.screenshot({ path: `${out}/09-atualizacao.png` });
  await mock('/__mock/reset');

  // Manutenção ao abrir
  await mock('/__mock/scenario/manutencao');
  await open(page);
  check('manutenção mostra o portão', await visible(page, 'gate.maintenance'));
  await page.screenshot({ path: `${out}/08-manutencao.png` });
  await mock('/__mock/reset');

  check('sem erros de JavaScript na página', errors.length === 0);
  console.log(results.join('\n'));
  if (errors.length) console.log('erros:', errors.slice(0, 5).join('\n'));
  await browser.close();
  process.exit(results.some((r) => r.startsWith('FALHOU')) ? 1 : 0);
})();
