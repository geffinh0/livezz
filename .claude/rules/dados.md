---
paths:
  - "apps/mobile/lib/features/**/domain/**"
  - "apps/mobile/lib/features/**/data/**"
  - "apps/admin/**/api/**"
  - "apps/admin/**/types/**"
  - "apps/portal/**/api/**"
  - "apps/portal/**/types/**"
  - "mock-server/src/**"
  - "mock-server/fixtures/**"
  - "backend/**"
  - "docs/DATABASE.md"
  - "docs/API.md"
  - "docs/EVENTOS-TEMPO-REAL.md"
---

# Regra de sincronização de dados e contratos

O banco ainda não existe. `docs/DATABASE.md` é a memória de tudo que precisa ser guardado; ele vira o banco na Fase 11. Por isso:

1. **Mudou um modelo, DTO, fixture ou estrutura em memória?** Atualize a entidade correspondente em `docs/DATABASE.md` na mesma tarefa: campos, tipos, regras, 🔒 para dado pessoal, "Usada por" com IDs e endpoints, e o status (`proposta` → `em uso no mock` → `validada`).
2. **Mudou ou criou endpoint/evento?** Atualize `docs/API.md` / `docs/EVENTOS-TEMPO-REAL.md` antes do código, e preencha a seção "Detalhes" do endpoint na primeira implementação.
3. **Registre no Histórico** do DATABASE.md (data, mudança, motivo).
4. No `docs/PROGRESSO.md`, escreva a linha `dados:` dizendo o que mudou ou `dados: sem impacto`.
5. Campo que nenhuma tela usa, ou tela que precisa de campo que não existe: aponte e pergunte.
6. Dúvida sobre o que guardar, por quanto tempo ou quem pode ver → `docs/QUESTOES-ABERTAS.md`.
7. Nomes de entidades/campos no código (inglês) e no DATABASE.md (pt-BR) devem ter correspondência clara; mantenha uma coluna ou nota com o nome no código quando forem diferentes.
