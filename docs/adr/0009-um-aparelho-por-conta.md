# ADR 0009: Um aparelho por conta

- Status: aceita
- Data: 2026-11-20

## Contexto
O usuário sugeriu reutilizar o mesmo token em vários aparelhos, com logout em um derrubando todos. Isso impede revogar um aparelho comprometido isoladamente e conflita com uma conexão em tempo real por conta. Após conversa, o usuário decidiu por um aparelho por conta.

## Decisão
- Uma sessão ativa por conta; cada login cria sessão nova com refresh token próprio e revoga a anterior.
- O aparelho antigo recebe `session.replaced`, tem a conexão em tempo real fechada e volta ao login com aviso.
- Uma conexão em tempo real por conta.

## Consequências
- Simplifica presença, live e chamadas (sem conflito entre aparelhos).
- O usuário não consegue assistir no celular e no tablet ao mesmo tempo; se isso virar pedido de clientes, revisar com nova ADR.
- Login em outro aparelho é um sinal antifraude útil (alerta de novo aparelho).
