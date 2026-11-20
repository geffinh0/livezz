# ADR 0007: Provedores e regras configuráveis pelo comprador

- Status: aceita
- Data: 2026-11-20

## Contexto
O usuário quer que o comprador do white-label consiga, sozinho e pelo painel web, trocar provedores (pagamento, SMS/WhatsApp, verificação de idade, tradução, moderação, anti-bot) e ajustar valores de negócio (taxas, conversões, níveis, limites), sem depender da nossa equipe nem de nova versão.

## Opções consideradas
1. Provedores fixos no código, trocados por nós a pedido: simples, mas cria dependência e custo de suporte.
2. Conectores no servidor com interface por tipo de provedor, escolhidos e configurados no painel: mais trabalho inicial, mas o comprador fica autônomo.

## Decisão
Opção 2.
- No servidor, cada tipo de provedor tem uma interface de conector (`pagamento_loja_alternativa`, `pagamento_web`, `repasse_saque`, `sms_whatsapp`, `verificacao_idade`, `traducao`, `moderacao_midia`, `antibot`, `push`, `analytics`).
- O mock-server tem conectores fake para todos; os reais entram na Fase 12, começando pelos padrões escolhidos (ex.: Yoti para idade).
- O painel (ADM19) lista os conectores disponíveis, recebe as credenciais (gravadas criptografadas, só de escrita), testa a conexão e liga/desliga. A verificação de idade pode ser desligada.
- Valores de negócio ficam em configurações versionadas (`ConfigEconomia`, `ConfigProgressao`, `ConfigApp`, `NivelVip`) editáveis no painel (ADM13, ADM20, ADM21, ADM09).

## Consequências
- Nenhum valor de negócio ou provedor fixo no código.
- Novo provedor = nova implementação do conector + opção no painel, sem mudar app nem contratos.
- Cada conector real precisa de testes com o fake e com o ambiente de testes do provedor.
- Responsabilidade jurídica e comercial com cada provedor é do comprador; documentar no guia de onboarding.
