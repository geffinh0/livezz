// Base comum dos fluxos E2E web (Playwright sobre o app Flutter web).
const { chromium } = require('playwright');
const fs = require('fs');

const MOCK = process.env.MOCK_URL || 'http://127.0.0.1:3000';
const APP = (process.env.APP_URL || 'http://localhost:8080/').replace(/\/?$/, '/');

// Clique no centro do elemento (o nó com o id tem pointer-events: none no
// Flutter web; o alvo real fica embaixo dele — como o dedo de uma pessoa).
async function clickId(page, id, timeout = 15000) {
  const el = page.locator(`[flt-semantics-identifier="${id}"]`).first();
  await el.waitFor({ state: 'attached', timeout });
  const box = await el.boundingBox();
  if (!box) throw new Error(`sem caixa para ${id}`);
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
}

function flow(name, body) {
  const out = process.argv[2] || 'build/e2e-web';
  fs.mkdirSync(out, { recursive: true });
  const results = [];
  const errors = [];
  (async () => {
    const browser = await chromium.launch();
    const ctx = await browser.newContext({ viewport: { width: 412, height: 915 }, locale: 'pt-BR' });
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
      newPage: async () => {
        const p2 = await (await browser.newContext({ viewport: { width: 412, height: 915 }, locale: 'pt-BR' })).newPage();
        p2.on('pageerror', (e) => errors.push(e.message));
        return p2;
      },
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
      // Espera o texto aparecer (até 5 s) em vez de olhar uma vez só.
      text: async (s, timeout = 5000) => {
        try {
          await page.getByText(s, { exact: false }).first().waitFor({ state: 'attached', timeout });
          return true;
        } catch {
          return false;
        }
      },
      wait: (ms) => page.waitForTimeout(ms),
      // Digita num campo do Flutter web: toca no campo e usa o teclado.
      type: async (id, text) => {
        await clickId(page, id);
        await page.waitForTimeout(300);
        await page.keyboard.type(text, { delay: 20 });
        await page.waitForTimeout(200);
      },
      // Apaga o conteúdo de um campo (seleciona tudo e apaga).
      clear: async (id) => {
        await clickId(page, id);
        await page.waitForTimeout(300);
        await page.keyboard.press('ControlOrMeta+A');
        await page.keyboard.press('Backspace');
        await page.waitForTimeout(200);
      },
      tap: (id) => clickId(page, id),
      outbox: async (destination) =>
        (await (await fetch(`${MOCK}/__mock/outbox?destination=${encodeURIComponent(destination)}`)).json()).code,
      // Atalho: entra como visitante → Entrar → método.
      toMethods: async () => {
        await clickId(page, 'entry.welcome.login');
        await page.locator('[flt-semantics-identifier="entry.methods"]').first().waitFor({ state: 'attached', timeout: 15000 });
      },
      // Fecha bottom sheet/diálogo tocando fora (Escape não fecha no Flutter web).
      dismiss: async () => {
        await page.mouse.click(200, 60);
        await page.waitForTimeout(700);
      },
    };
    let crashed = null;
    try {
      await t.mock('/__mock/reset');
      await body(t);
    } catch (e) {
      crashed = e;
      // Print do estado no momento da falha, para diagnóstico.
      await page.screenshot({ path: `${out}/${name}-FALHA.png` }).catch(() => {});
      console.log(`url na falha: ${page.url()}`);
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

module.exports = { flow, clickId };
