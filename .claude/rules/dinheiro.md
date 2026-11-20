---
paths:
  - "**/*wallet*/**"
  - "**/*gift*/**"
  - "**/*payout*/**"
  - "**/*store*/**"
  - "**/*ledger*/**"
  - "**/*economy*/**"
  - "**/*pk*/**"
  - "**/*call*/**"
  - "**/*vip*/**"
  - "**/*subscription*/**"
  - "**/*reseller*/**"
  - "**/*referral*/**"
  - "**/*agency*/**"
  - "apps/portal/**"
  - "**/*charge*/**"
  - "**/*connector*/**"
---

# Regras de dinheiro (moedas, diamantes, saques, cobranças)

Este código mexe com dinheiro real. Erro aqui é prejuízo do cliente e problema jurídico.

- Valores sempre inteiros (moedas, diamantes, centavos). Nunca ponto flutuante.
- Todo movimento é uma `TransacaoLedger` com lançamentos que somam zero (RN-26). Saldo é derivado; nunca "saldo = saldo - x" solto.
- Toda operação de valor exige `Idempotency-Key`. A mesma chave devolve o mesmo resultado sem novo efeito.
- O servidor valida tudo: item existe e está ativo, preço é o do catálogo (ignorar preço enviado pelo cliente), saldo suficiente, flag ligada, usuário não sancionado, limites (RN-21, SEG05).
- Pontos de PK, XP, rankings e comissões só a partir de transações confirmadas.
- Reembolsos e estornos são novas transações com motivo; nada é apagado.
- Cobrança por minuto: é um presente do menu de cobrança da streamer (RN-53); preço e consentimento antes, envio no início de cada minuto, aviso de saldo baixo, reembolso inicial (RN-50).
- Moedas pagas × grátis e diamantes normais × bônus sempre separados no ledger (RN-30, RN-32).
- Testes obrigatórios: saldo insuficiente, mesma chave de idempotência repetida, dois envios concorrentes, flag desligada, usuário sancionado, soma zero do ledger.
- Mudança no modelo do ledger ou nas fórmulas → ADR + `revisor-seguranca` + atualizar `docs/REGRAS-DE-NEGOCIO.md` e `docs/DATABASE.md`.
- Valor de negócio não decidido (taxa, conversão, mínimo) → nunca invente: use o provisório configurável e confira `docs/QUESTOES-ABERTAS.md`.
