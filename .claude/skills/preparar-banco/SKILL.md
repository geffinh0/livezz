---
name: preparar-banco
description: Fase 11. Ajuda o usuário a escolher o banco e o backend e gera o schema a partir de docs/DATABASE.md, sem perder nada que o app já usa.
disable-model-invocation: true
---

Só comece se a Fase 10 do `docs/ROADMAP.md` estiver concluída. Se não estiver, diga o que falta.

1. **Sincronizar:** rode o fluxo de `/sincronizar-dados`. O DATABASE.md precisa estar 100% fiel ao mock-server e ao app.
2. **Levantar requisitos** a partir do DATABASE.md, REGRAS e ESPECIFICACAO: volume esperado por entidade, consistência transacional (ledger, saques), consultas principais (feed de lives, ranking, extrato, chat), tempo real (presença, placar), retenção, criptografia de campos 🔒, backups, custo de hospedagem.
3. **Apresentar opções** ao usuário (pesquise preços e limites atuais com o `pesquisador`): 2–3 combinações de banco principal + cache/fila + hospedagem, com prós, contras, custo estimado e sua recomendação. Pergunte também o framework do backend (Q-26). **Espere a decisão.**
4. Registre as decisões em ADR e em `docs/QUESTOES-ABERTAS.md` (Q-26, Q-27).
5. **Gerar o schema:** traduza cada entidade (tipos, chaves, unicidades, índices de "Notas para o banco", restrições, criptografia) para o banco escolhido. Ledger com garantias de integridade. Migrations versionadas.
6. **Plano da Fase 11** via `/planejar`: backend implementando `docs/API.md` e `docs/EVENTOS-TEMPO-REAL.md`, reaproveitando os testes de contrato do mock-server, seeds a partir das fixtures, troca do `apiBaseUrl` do app.
7. Atualize o DATABASE.md: seção "Notas para o banco" preenchida e status das entidades.
