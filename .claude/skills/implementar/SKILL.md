---
name: implementar
description: Implementa um plano aprovado de docs/planos/, passo a passo, com testes primeiro, commits pequenos e documentação sincronizada.
argument-hint: [caminho do plano]
---

Implementar: $ARGUMENTS (se vazio, o plano mais recente com passos pendentes).

## Antes
- Confirme que o plano tem `Status: aprovado pelo usuário`. Se não tiver, pare e peça aprovação.
- Leia o plano inteiro, os itens da especificação e os contratos citados.
- Confirme a branch de trabalho (crie `feat/<fase-ou-modulo>` se estiver na `main`).

## Para cada passo
1. Escreva os testes do comportamento esperado (contrato no mock-server, unitário/widget no app).
2. Implemente o mínimo para passar, seguindo as regras de `.claude/rules/`.
3. Rode lint, tipos e testes da parte alterada. Mostre a saída resumida.
4. Mantenha documentos em dia: `docs/API.md`/`EVENTOS` (status `no mock`, seção Detalhes), `docs/DATABASE.md` (status `em uso no mock`, Histórico).
5. Commit Conventional Commits citando o ID (ex.: `feat(ENT04): envio e verificação de código`).
6. Marque o passo como feito no plano.

Se algo do plano estiver errado, incompleto ou depender de uma decisão não tomada: **pare, explique e pergunte**. Não improvise regra de negócio.
Notou algo para melhorar fora do escopo? Registre em `docs/MELHORIAS.md` e siga.

## Ao final do plano
1. Suíte completa do que foi tocado + fluxos E2E dos itens (`maestro test e2e/<ID>.yaml`).
2. Em paralelo: subagentes `revisor`, `revisor-ux` (se teve tela), `revisor-seguranca` (se tocou dinheiro/auth/dados pessoais/moderação/menores) e `guardiao-dados`.
3. Corrija o que for problema real; o que for sugestão vai para `docs/MELHORIAS.md`.
4. Subagente `verificador-spec` para os IDs do plano. Só marque `[x]` o que ele confirmar.
5. Atualize `docs/ESPECIFICACAO.md`, `docs/ROADMAP.md`, `docs/PROGRESSO.md` (com linha `dados:`).
6. Resumo para o usuário: o que foi feito, como testar no celular (passo a passo), o que ficou pendente e por quê, decisões que você tomou sozinho.
