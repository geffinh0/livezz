# ADR 0001: Agora por cliente e backend single-tenant

- Status: aceita
- Data: 2026-11-20

## Contexto
O produto é vendido como white-label. O vídeo ao vivo é o maior custo variável e cresce com a audiência.
Os dados de cada cliente (usuários, saldos, saques) são sensíveis.

## Opções consideradas
1. Uma conta Agora nossa para todos, repassando custo: risco de calote e de ficarmos no prejuízo com picos de audiência.
2. Cada cliente com conta Agora própria: o cliente paga direto e cada conta tem 10.000 minutos grátis por mês para testes.
3. Backend multi-tenant compartilhado: mais barato de hospedar, porém mais complexo e com risco de vazamento entre clientes.
4. Um backend + banco por cliente: isolamento total, mais simples de raciocinar.

## Decisão
Opções 2 e 4. Cada cliente tem a própria conta Agora e o próprio deploy de backend e banco. O código é único.

> Nota (2026-11-20): pela ADR 0002 o backend só é construído na Fase 11; até lá o app usa o mock-server. Esta decisão vale para o backend real.

## Consequências
- O vídeo precisa de uma camada `VideoProvider` para não ficarmos presos à Agora.
- O onboarding do cliente inclui criar a conta Agora e pedir ao suporte deles a ativação do relay entre canais (PK).
- O deploy precisa ser automatizado (script/infra como código) para escalar o número de clientes.
