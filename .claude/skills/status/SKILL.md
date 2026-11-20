---
name: status
description: Relatório rápido do estado do projeto (fase, placar da especificação, questões abertas, melhorias, git). Use quando o usuário perguntar "como estamos?", "quanto falta?", "status".
---

Monte um relatório curto, sem alterar nada:

1. **Fase atual** (de `docs/ROADMAP.md`) e próximo passo (`docs/PROGRESSO.md`).
2. **Placar por módulo** de `docs/ESPECIFICACAO.md`: conte `[x]`, `[~]`, `[ ]` por prefixo (ENT, NAV, DES, ASS, PRE, TRA, PK, CHA, MSG, FEED, PER, ECO, VIP, SUB, FAM, AGE, EST, CFG, SEG, ADM, TRV). Use um comando de shell (`grep`) para contar, não estime.
3. **Questões abertas**: quantas, e quais bloqueiam a fase atual.
4. **Melhorias** abertas por prioridade; destaque `crítica`.
5. **Dados**: quantas entidades do `docs/DATABASE.md` estão `proposta` / `em uso no mock` / `validada`.
6. **Git**: branch, últimos 5 commits, mudanças não commitadas.

Termine com uma recomendação de próxima ação em uma linha.
