# ADR 0006: Mecânicas de alto risco

- Status: aceita
- Data: 2026-11-20

## Contexto
O mercado de apps de live usa mecânicas com risco jurídico e de dano ao usuário. O usuário decidiu: excluir jogos com aposta e manter o resto, com o ajuste jurídico feito depois.

## Decisão
| Mecânica | Decisão |
| --- | --- |
| Jogos com aposta (moedas/diamantes em jogos de sorte) | **Fora** (decisão do usuário) |
| Chamada privada simulada que se passa por real | **Fora** (decisão técnica: engana o usuário para gerar gasto). Substituída por tutorial rotulado como demonstração (CHA11). |
| Presente da sorte (retorno variável ao remetente) | Dentro, atrás de flag `lucky_gift` **desligada por padrão**, exige parecer jurídico do cliente para ligar |
| Cobrança por minuto (live privada e chamada paga) | Dentro, com preço visível antes de começar, consentimento explícito, contador de custo visível e reembolso automático nos primeiros segundos; flag `paid_per_minute` |
| Revenda de moedas | Dentro, flag `coin_reseller` desligada por padrão; só contas aprovadas no painel; tudo no ledger |
| Comissões de agência e de indicação | Dentro, flags `agencies` e `referrals`; percentuais configuráveis e exibidos com transparência |

## Consequências
- O painel admin mostra, ao ligar cada flag com risco, um aviso de que é necessária avaliação jurídica, e registra quem ligou e quando (log de auditoria).
- Toda mecânica com risco tem teste de que a flag desligada realmente esconde a funcionalidade no app e bloqueia o endpoint no servidor.
- A revisão jurídica faz parte da Fase 13.
