---
name: retro
description: Retrospectiva ao fim de cada fase. Avalia o que funcionou e o que falhou e propõe melhorias no próprio kit (CLAUDE.md, regras, skills, agentes, hooks) e no processo.
argument-hint: [fase, ex. "fase 3"]
disable-model-invocation: true
---

Retrospectiva: $ARGUMENTS

1. **Fatos:** leia os planos da fase em `docs/planos/`, o `git log` da fase, `docs/PROGRESSO.md`, `docs/MELHORIAS.md` e o resultado do último `/auditar`. Liste:
   - bugs encontrados depois de um item ser marcado pronto;
   - correções que o usuário precisou fazer em você;
   - passos de plano que deram errado ou foram refeitos;
   - perguntas que você deveria ter feito antes;
   - documentos que ficaram desatualizados.
2. **Causas:** para cada problema, por que aconteceu (regra faltando, regra ambígua, skill pulando um passo, teste que não pegou, falta de contexto).
3. **Propostas de evolução do kit**, cada uma com o texto exato da mudança:
   - nova regra ou ajuste em `CLAUDE.md` ou `.claude/rules/*.md`;
   - passo novo ou alterado em uma skill;
   - agente novo ou instrução nova em um agente;
   - hook novo ou ajuste (com script);
   - novo cenário `/__mock` ou teste padrão.
4. Apresente ao usuário e aplique **só o que ele aprovar**. Registre as mudanças em `docs/PROGRESSO.md` e, se forem estruturais, numa ADR.
5. Atualize `docs/ROADMAP.md` (fase concluída) e proponha o começo da próxima fase com `/comecar`.
