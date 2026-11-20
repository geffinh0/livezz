---
name: decidir
description: Conduz o usuário pelas questões abertas de docs/QUESTOES-ABERTAS.md, uma rodada por vez, e aplica as decisões nos documentos.
argument-hint: [opcional: IDs ou fase, ex. "Q-03 Q-04" ou "fase 4"]
disable-model-invocation: true
---

Questões a decidir: $ARGUMENTS (se vazio: as que bloqueiam a fase atual; se não houver, as mais antigas).

1. Leia `docs/QUESTOES-ABERTAS.md` e o contexto de cada questão nos documentos citados (REGRAS, ESPECIFICACAO, ARQUITETURA).
2. Se a questão depende de informação atual de fora (política da Google Play, provedores, preços, lei), use o subagente `pesquisador` antes e traga fontes.
3. Pergunte em rodadas de até 4 questões com a ferramenta de perguntas: cada uma com contexto curto, 2–4 opções com prós e contras e a sua recomendação marcada.
4. Para cada resposta:
   - mova a linha para "Respondidas" com data;
   - substitua o valor provisório em `docs/REGRAS-DE-NEGOCIO.md` / tire o **[DECIDIR]**;
   - ajuste `docs/ESPECIFICACAO.md`, `docs/DATABASE.md`, `docs/ARQUITETURA.md` se afetar;
   - se for decisão de arquitetura, crie a ADR (`/adr`);
   - se o código já usa o valor provisório, registre a mudança necessária em `docs/MELHORIAS.md` ou aplique se for só configuração.
5. Mostre um resumo do que foi decidido e o que mudou em cada documento.
