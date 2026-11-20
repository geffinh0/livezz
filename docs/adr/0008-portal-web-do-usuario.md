# ADR 0008: Portal web do usuário para saque, recarga e assinaturas

- Status: aceita
- Data: 2026-11-20

## Contexto
O usuário decidiu que saque e dados de recebimento são páginas web, não telas do app; que a assinatura de criador é paga em reais por checkout web; e que recargas fora da loja passam por página web ou intermediador. Isso também mantém taxas e conversões fora do app.

## Opções consideradas
1. Telas nativas no app para tudo: experiência integrada, mas mistura pagamentos fora da loja dentro do app e expõe regras financeiras na interface do app.
2. Portal web separado (`apps/portal`), aberto a partir do app com link de uso único: fluxo financeiro isolado, mais fácil de adaptar a provedores e às regras das lojas.

## Decisão
Opção 2. Portal Next.js com: saque (POR02), dados de recebimento (POR03), recarga (POR04), checkout e gestão de assinatura de criador (POR05), ganhos e comprovantes (POR06). Entrada pelo app via `POST /portal/links` → `POST /portal/session`.

## Consequências
- O app mostra saldos, mas não conversão nem taxas; botões abrem o portal.
- Segurança web específica (CSP, CSRF, cookies, link de uso único) passa a ser obrigatória (`.claude/rules/portal.md`).
- Confirmações de pagamento só por webhook no servidor.
- Conferir as regras de cada loja sobre links para pagamento externo antes de publicar (Q-37).
