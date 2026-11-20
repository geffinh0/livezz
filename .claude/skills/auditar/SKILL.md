---
name: auditar
description: Confere tela por tela e funcionalidade por funcionalidade da especificação contra o código e os testes reais, corrige os status e lista o que falta.
argument-hint: [opcional: módulo ou IDs, ex. "ECO" ou "PK01 PK06"]
disable-model-invocation: true
---

Auditar: $ARGUMENTS (se vazio, a fase atual do roadmap; "tudo" para o produto inteiro).

1. Divida os itens por módulo e delegue cada módulo a um subagente `verificador-spec`, em paralelo (no máximo 5 ao mesmo tempo).
2. Em paralelo, peça ao `guardiao-dados` a conferência de DATABASE.md, API.md e EVENTOS contra o código.
3. Junte os resultados e atualize os status em `docs/ESPECIFICACAO.md` conforme o verificado (inclusive rebaixando `[x]` que não cumpre a Definição de pronto).
4. Atualize `docs/PROGRESSO.md`.
5. Entregue ao usuário:
   - placar por módulo (prontos / em andamento / não iniciados);
   - divergências (o que estava marcado errado);
   - lacunas: critérios que nenhum plano cobre, telas sem E2E, dados sem registro;
   - riscos encontrados (registre em `docs/MELHORIAS.md`);
   - os 3 próximos itens recomendados, na ordem, com o motivo.
