---
paths:
  - "apps/mobile/e2e/**/*"
  - "apps/mobile/lib/features/**/presentation/**"
---

# Testes E2E das telas (Maestro)

- Cada item de tela de `docs/ESPECIFICACAO.md` tem um fluxo em `apps/mobile/e2e/<ID>.yaml` (ex.: `PRE01.yaml`).
- O fluxo cobre os critérios de aceite do item e pelo menos um caminho de erro (usando `/__mock/scenario/*` para forçar a situação).
- Antes de cada fluxo: `POST /__mock/reset` para começar de um estado conhecido.
- Encontrar elementos por `id` (Key/Semantics), nunca por texto que muda por tenant.
- Roda contra o flavor `liveapp` e o mock-server local.
- Item de tela sem fluxo E2E passando não é considerado pronto.
