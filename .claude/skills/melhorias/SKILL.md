---
name: melhorias
description: Varre o código e os documentos procurando o que melhorar (segurança, dívida técnica, desempenho, UX, testes, lacunas da especificação) e organiza o backlog em docs/MELHORIAS.md.
argument-hint: [opcional: área, ex. "app", "mock-server", "segurança", "ECO"]
disable-model-invocation: true
---

Área: $ARGUMENTS (se vazio, tudo que mudou desde a última revisão de melhorias).

1. Em paralelo: `revisor` (dívida técnica, duplicação, testes fracos), `revisor-seguranca` (riscos), `revisor-ux` (consistência e acessibilidade), `arquiteto` (acoplamento, decisões que viraram dívida).
2. Compare também `docs/ESPECIFICACAO.md` com `docs/referencias/relatorio-concorrente.md` só para achar **lacunas de domínio** (nunca copiar): algo que um produto maduro tem e a gente não especificou.
3. Registre cada achado em `docs/MELHORIAS.md` (ID, data, tipo, prioridade, descrição, onde). Não duplique itens já existentes; atualize os antigos se mudaram.
4. Apresente ao usuário as 5 mais importantes com recomendação (fazer agora, na próxima fase, ou descartar) e peça decisão. Itens `crítica` sempre aparecem primeiro.
5. Lacunas de produto aprovadas pelo usuário viram itens novos em `docs/ESPECIFICACAO.md` (com ID novo no módulo certo).
