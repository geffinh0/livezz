# ADR 0004: Android primeiro

- Status: aceita
- Data: 2026-11-20

## Contexto
O usuário vai desenvolver e testar primeiro no Android.

## Decisão
O app é Flutter (pronto para iOS), mas toda configuração, teste, build e publicação mira Android até o fim da Fase 13.

## Consequências
- Evitar pacotes só-Android quando existir alternativa multiplataforma equivalente; quando não existir, isolar atrás de interface.
- Pagamento na loja: Google Play Billing (moedas e VIP são bens digitais e exigem o sistema de faturamento da loja).
- Quando o iOS entrar: revisar pagamentos (App Store), regras de template da Apple (cada cliente publica na própria conta), notificações e permissões.
