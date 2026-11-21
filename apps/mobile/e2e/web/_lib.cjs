// Base comum dos fluxos E2E web (Playwright sobre o app Flutter web).
const { chromium } = require('playwright');
const fs = require('fs');

const MOCK = process.env.MOCK_URL || 'http://127.0.0.1:3000';
const APP = (process.env.APP_URL || 'http://localhost:8080/').replace(/\/?$/, '/');

function flow(name, body) {
  const out = process.argv[2] || 'build/e2e-web';
  fs.mkdirSync(out, { recursive: true });
  const results = [];
  const errors = [];
  (async () => {
    const browser = await chromium.launch();
    const ctx = await browser.newContext({ viewport: { width: 412, height: 915 } });
    const page = await ctx.newPage();
    page.on('pageerror', (e) => errors.push(e.message));
    const t = {
      page,
      check: (label, ok) => results.push(`${ok ? 'OK  ' : 'FALHOU'} ${name}: ${label}`),
      mock: (path, payload) =>
        fetch(MOCK + path, {
          method: 'POST',
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify(payload ?? {}),
        }),
      config: async () => (await fetch(MOCK + '/v1/config')).json(),
      byId: (id) => page.locator(`[flt-semantics-identifier="${id}"]`),
      button: (label) => page.getByRole('button', { name: label, exact: true }),
      shot: (file) => page.screenshot({ path: `${out}/${name}-${file}.png` }),
      // Abre o app do zero (sem dados locais) num caminho (rota go_router).
      open: async (route = '/', { fresh = true } = {}) => {
        if (fresh) await ctx.clearCookies();
        await page.goto(APP, { waitUntil: 'load' });
        if (fresh) await page.evaluate(() => localStorage.clear());
        await page.goto(APP + '#' + route, { waitUntil: 'load' });
        await page.reload({ waitUntil: 'load' });
        await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 30000 });
        await page.locator('flt-semantics-placeholder').evaluate((e) => e.click());
      },
      visible: async (id, timeout = 20000) => {
        try {
          await page.locator(`[flt-semantics-identifier="${id}"]`).first().waitFor({ state: 'attached', timeout });
          return true;
        } catch {
          return false;
        }
      },
      gone: async (id, timeout = 10000) => {
        try {
          await page.locator(`[flt-semantics-identifier="${id}"]`).first().waitFor({ state: 'detached', timeout });
          return true;
        } catch {
          return false;
        }
      },
      text: async (s) => (await page.getByText(s, { exact: false }).count()) > 0,
      wait: (ms) => page.waitForTimeout(ms),
    };
    let crashed = null;
    try {
      await t.mock('/__mock/reset');
      await body(t);
    } catch (e) {
      crashed = e;
    } finally {
      await t.mock('/__mock/reset').catch(() => {});
    }
    if (crashed) results.push(`FALHOU ${name}: exceção — ${crashed.message.split('\n')[0]}`);
    results.push(`${errors.length === 0 ? 'OK  ' : 'FALHOU'} ${name}: sem erros de JavaScript`);
    console.log(results.join('\n'));
    if (errors.length) console.log(errors.slice(0, 3).join('\n'));
    await browser.close();
    process.exit(results.some((r) => r.startsWith('FALHOU')) ? 1 : 0);
  })();
}

module.exports = { flow };
