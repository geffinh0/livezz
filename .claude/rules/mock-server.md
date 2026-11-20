---
paths:
  - "mock-server/**/*"
---

# Regras do mock-server

- Node + TypeScript estrito, Fastify (REST) e `ws` (WebSocket). Dados em memória, semeados de `mock-server/fixtures/`.
- Implementa **exatamente** `docs/API.md` e `docs/EVENTOS-TEMPO-REAL.md`: mesmos caminhos, campos, códigos de erro, paginação, idempotência e envelope. Se precisar de algo que não está no contrato, atualize o contrato primeiro.
- Cada entidade guardada em memória corresponde a uma entidade de `docs/DATABASE.md` com os mesmos campos. Mudou a estrutura? Atualize o DATABASE.md na mesma tarefa e marque o status `em uso no mock`.
- Aplica as regras de `docs/REGRAS-DE-NEGOCIO.md` (saldo, ledger em memória com soma zero, limites, permissões, flags). Valores provisórios vêm de uma config central editável, nunca espalhados.
- Validação de entrada com schema em todo endpoint; resposta de erro no formato do contrato.
- Rotas `/__mock/*` só para cenários de teste; nunca usadas pelo app em produção.
- Simuladores (bots de chat/presentes, PK, chamadas) desligáveis e determinísticos com semente, para testes repetíveis.
- Fixtures realistas em pt-BR, sem dados de pessoas reais e sem conteúdo de terceiros.
- Teste de contrato para cada endpoint e evento (caminho feliz + erros principais). Esses testes serão reaproveitados no backend real.
- Antes de terminar: `npm run lint && npm run typecheck && npm test`.
