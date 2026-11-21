---
paths:
  - "apps/mobile/e2e/**/*"
  - "apps/mobile/lib/features/**/presentation/**"
---

# Testes E2E das telas (navegador e Maestro)

- Cada item de tela de `docs/ESPECIFICACAO.md` tem um fluxo E2E (Q-44):
  - **no navegador** (`apps/mobile/e2e/web/<ID>.cjs`, Playwright sobre o app Flutter web) quando não usa recurso nativo; roda com `bash tools/dev/e2e-web.sh` e no CI;
  - **no Android** (`apps/mobile/e2e/<ID>.yaml`, Maestro) quando usa câmera, permissões, vídeo nativo, push ou compra na loja.
- Guardar prints dos estados principais (claro/escuro, pt/en): o print já pegou bug de contraste que o teste de widget não pegou.
- O fluxo cobre os critérios de aceite do item e pelo menos um caminho de erro (usando `/__mock/scenario/*` para forçar a situação).
- Antes de cada fluxo: `POST /__mock/reset` para começar de um estado conhecido.
- Encontrar elementos por `id` (`TestId` → `Semantics.identifier`; no navegador vira `flt-semantics-identifier`), nunca por texto que muda por tenant.
- Roda contra o flavor `liveapp` e o mock-server local.
- Item de tela sem fluxo E2E passando não é considerado pronto.
