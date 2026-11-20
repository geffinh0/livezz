---
paths:
  - "apps/mobile/lib/features/**/presentation/**"
  - "apps/mobile/lib/core/ui/**"
  - "apps/admin/**/components/**"
  - "apps/portal/**/components/**"
---

# Regras de interface

- Siga `docs/DESIGN-SYSTEM.md`: use os componentes de `lib/core/ui/`; não crie variações soltas de botão, sheet, diálogo ou campo. Precisa de um componente novo? Crie no `core/ui` e documente no design system.
- Cores, fontes, espaçamentos e raios só por tokens do tema (vindos do tenant). Nada de valores mágicos. Tema claro e escuro sempre.
- Pronto para RTL: use `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end` (nunca `left`/`right` fixos) e ícones direcionais espelháveis.
- Todo texto em pt-BR e inglês; teste telas com textos em inglês (costumam ser mais longos ou mais curtos).
- Na live: overlays e bottom sheets, texto claro sobre gradiente, nunca cobrir os controles principais.
- Antes de qualquer gasto: preço, saldo e consequência visíveis.
- Acessibilidade: alvo ≥ 48dp, contraste AA, `Semantics` com rótulo, funciona com fonte grande e com "reduzir animações".
- Nunca reproduzir layout, ícones, cores ou textos do concorrente.
- Tela nova ou mudada de forma relevante → peça revisão do subagente `revisor-ux`.
