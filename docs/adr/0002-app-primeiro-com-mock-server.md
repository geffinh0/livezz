# ADR 0002: App primeiro, com servidor fake local

- Status: aceita
- Data: 2026-11-20

## Contexto
O usuário quer construir o aplicativo antes de escolher e construir o banco de dados. O app precisa de dados, erros e eventos em tempo real realistas para ser construído e testado corretamente.

## Opções consideradas
1. Dados falsos dentro do app (repositórios fake): rápido, mas não exercita HTTP, erros de rede nem WebSocket; na troca pela API real aparecem bugs escondidos.
2. Servidor fake local (`mock-server/`) seguindo o contrato da API: um pouco mais de trabalho, mas o app fala HTTP e WebSocket de verdade desde o primeiro dia.

## Decisão
Opção 2 (escolha do usuário). O mock-server implementa `docs/API.md` e `docs/EVENTOS-TEMPO-REAL.md` com dados em memória e rotas de cenário `/__mock/*`.

## Consequências
- Todo endpoint/evento precisa estar documentado antes de ser implementado.
- Todo dado que o mock-server guarda em memória precisa estar em `docs/DATABASE.md`; esse documento vira a base do banco real.
- O mock-server deve aplicar as regras de negócio essenciais (saldo, idempotência, permissões) para o app não ser construído em cima de comportamento errado.
- O backend real terá de passar nos mesmos testes de contrato do mock-server.
