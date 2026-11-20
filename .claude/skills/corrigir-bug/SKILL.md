---
name: corrigir-bug
description: Investiga e corrige um bug começando por um teste que reproduz o problema.
argument-hint: [descrição do bug, passos ou log de erro]
---

Bug: $ARGUMENTS

1. Reproduza: entenda os passos; se possível, crie um cenário no mock-server (`/__mock/scenario/*`) que provoca o problema.
2. Encontre a causa raiz antes de mudar qualquer coisa. Explique em 2–3 frases simples.
3. Escreva um teste que falha por causa do bug (unitário, widget, contrato ou E2E, o mais barato que pegue o problema).
4. Corrija com a menor mudança correta e confirme que o teste passa.
5. Procure o mesmo padrão de erro em outros lugares; registre em `docs/MELHORIAS.md` se achar.
6. Se o bug revela uma regra faltando ou ambígua, proponha a correção em `docs/ESPECIFICACAO.md`/`REGRAS` (pergunte se mudar comportamento).
7. Rode a suíte da parte afetada, atualize `docs/PROGRESSO.md` e faça um commit `fix(<ID>): ...`.
