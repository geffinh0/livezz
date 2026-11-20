---
name: comecar
description: Ponto de partida de qualquer sessão de trabalho no app. Use quando o usuário disser "começa", "comece a fazer o aplicativo", "continua", "bora", "o que falta?" ou abrir a sessão sem tarefa específica.
when_to_use: começar o projeto, continuar de onde parou, retomar o trabalho, próximo passo
---

Você vai retomar o projeto como desenvolvedor líder. Siga na ordem e **não escreva código nesta etapa**.

## 1. Entender onde estamos
Leia: `docs/PROGRESSO.md`, `docs/ROADMAP.md`, `docs/QUESTOES-ABERTAS.md`, `docs/MELHORIAS.md` (itens `crítica`/`alta` abertos) e `git log --oneline -10` + `git status`.
Se existir um plano em `docs/planos/` com passos não concluídos, ele é o trabalho em andamento.

## 2. Checagem de saúde (rápida)
- Mudanças não commitadas? Pergunte o que fazer com elas antes de seguir.
- O último item marcado `[x]` na especificação tem fluxo E2E e testes? Se tiver dúvida, sugira `/auditar` daquele módulo.
- `docs/DATABASE.md` / `docs/API.md` parecem desatualizados em relação ao código (mudanças recentes em `domain/`, `data/`, `mock-server/` sem histórico no DATABASE.md)? Sugira `/sincronizar-dados`.
- Há melhoria `crítica` aberta? Ela vem antes de qualquer coisa nova: avise.

## 3. Decidir o próximo trabalho
- Trabalho em andamento → continue o plano (vá para `/implementar` com ele).
- Senão → próximo item não concluído da fase atual do `docs/ROADMAP.md`. Agrupe itens pequenos e relacionados (ex.: ENT04–ENT07) num mesmo plano; nunca mais que um módulo por plano.

## 4. Questões que bloqueiam
Liste as questões de `docs/QUESTOES-ABERTAS.md` cuja coluna "Bloqueia" inclui os itens escolhidos. Se houver, **pergunte agora** (ferramenta de perguntas: até 4 por vez, com opções, prós e contras e sua recomendação). Registre as respostas no documento e aplique em REGRAS/ESPECIFICACAO/DATABASE. Se o usuário preferir adiar, siga com o valor provisório configurável e anote.

## 5. Apresentar ao usuário
Em poucas linhas, em pt-BR simples:
- onde o projeto está (fase, itens prontos/total da fase);
- o que você propõe fazer agora e por quê;
- o que precisa dele (respostas, aprovar o plano, instalar algo).
Depois, com o "ok" dele, siga para `/planejar` com os itens escolhidos.

## Primeira vez (sem código ainda)
Se `apps/`, `mock-server/` ainda não existem: a proposta é a **Fase 0**. Antes de planejar, verifique o ambiente da máquina (Flutter, Android SDK, Node, Git, jq, Maestro) com comandos de versão e diga exatamente o que falta instalar. A Fase 0 depende da Q-02 (identidade visual): pergunte.
