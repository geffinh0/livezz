---
name: revisar
description: Revisão completa das mudanças atuais (qualidade, arquitetura, UX, segurança e dados) antes de commit ou merge.
disable-model-invocation: true
---

Revise as mudanças ainda não integradas (`git diff` e `git diff main...HEAD`).

1. Rode lint, tipos e testes das partes alteradas; reporte falhas.
2. Delegue em paralelo:
   - `revisor`: qualidade, legibilidade, testes, aderência a `CLAUDE.md` e `.claude/rules/`
   - `revisor-seguranca`: usando `docs/SEGURANCA.md`
   - `revisor-ux`: se há mudanças em telas/componentes
   - `guardiao-dados`: DATABASE.md, API.md e EVENTOS em dia com o código
3. Junte tudo numa lista única do mais grave ao menos grave, com arquivo e linha.
4. Separe "precisa corrigir" de "sugestão". Não corrija nada sem o usuário pedir; sugestões vão para `docs/MELHORIAS.md`.
