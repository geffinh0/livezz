# ADR 0005: Comando por REST, estado por WebSocket com envelope versionado

- Status: aceita
- Data: 2026-11-20

## Contexto
Lives têm muito estado mudando ao mesmo tempo (chat, presentes, placar de PK, espectadores, moderação, saldo). Apps do mercado usam um único canal de eventos que propaga estado, com poucas ações de comando.

## Opções consideradas
1. Tudo por WebSocket (comandos e eventos): menos requisições, porém validação, idempotência, erros e autenticação ficam mais difíceis de testar.
2. Comandos por REST e estado por WebSocket: cada ação tem resposta clara e testável; o estado chega para todos na sala pelo mesmo caminho.

## Decisão
Opção 2. Envelope `{ v, id, type, ts, data }` em JSON. Tipos nomeados `dominio.evento` (ex.: `live.gift.sent`). Começamos com JSON; migração para formato binário (ex.: Protobuf) fica como melhoria se o volume justificar.

## Consequências
- Catálogo único em `docs/EVENTOS-TEMPO-REAL.md`.
- Clientes ignoram tipos desconhecidos (compatibilidade para frente) e respeitam `v`.
- O servidor pode empurrar estado de UI (ofertas, avisos), o que evita lançar versões novas para mudar promoções.
