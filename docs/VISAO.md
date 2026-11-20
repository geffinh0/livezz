# Visão do produto

> Documento vivo. Mudou de ideia sobre o produto? Atualize aqui primeiro e depois `docs/ESPECIFICACAO.md`.

## O que é
Uma **plataforma completa de live streaming social monetizada**, vendida como **white-label**.
O cliente compra, recebe o app com a marca dele publicado na Google Play (Android primeiro, iOS depois), um painel web para administrar tudo e um portal web onde os usuários fazem saques, recargas e assinaturas.

O produto cobre o que o mercado espera de um app desse tipo (lives com presentes, batalhas PK, convidados no palco, chamadas privadas, mensagens, feed, VIP, famílias, agências, rankings e saques), com **identidade, nomes, contratos e visual próprios**.

## Para quem
- **Cliente (comprador do white-label):** empreendedores e agências no Brasil que querem lançar o próprio app de lives.
- **Usuário final do app:** adultos (18+) que assistem, transmitem, interagem e gastam ou ganham dentro do app.

## Perfis de usuário dentro do app
| Perfil | O que faz |
| --- | --- |
| Visitante | Navega sem conta; precisa entrar para interagir |
| Espectador | Assiste, conversa, segue, compra moedas, envia presentes |
| Streamer (host) | Transmite, recebe diamantes, saca, faz PK, convida pessoas ao palco |
| Convidado / palestrante | Sobe ao palco de uma live individual ou em grupo |
| Moderador da live | Nomeado pelo host; silencia e expulsa |
| Líder / gerente de família | Administra um grupo de usuários |
| Gerente de agência | Agrupa streamers e recebe comissão |
| Revendedor de moedas | Conta autorizada a transferir moedas a outros usuários |
| Equipe do cliente (painel) | Admin, moderador, financeiro, suporte |

## Diferenciais
- **Feito para o Brasil:** pt-BR nativo, Pix na recarga e no saque, LGPD e ECA Digital tratados desde o primeiro dia, suporte no fuso daqui, contrato em reais.
- **Custo de vídeo transparente:** cada cliente usa a própria conta de vídeo (ver ADR 0001).
- **Segurança e moderação de fábrica:** verificação de idade confiável, denúncia em um toque, moderação em tempo real, ledger auditável.
- **Tudo configurável pelo comprador:** taxas, conversões, preços, promoções, níveis, limites e até os provedores (pagamento, SMS, verificação de idade, tradução, moderação) mudam pelo painel, sem nova versão do app.
- **Português e inglês**, com interface preparada para idiomas da direita para a esquerda.

## Modelo de negócio (do nosso lado)
- Setup/licença: instalação, customização de marca e publicação.
- Mensalidade: suporte, atualizações e hospedagem do backend.
- Vídeo (Agora): o cliente paga direto ao provedor.

## Escopo
**Decisão do usuário (2026-11-20): todo o produto descrito em `docs/ESPECIFICACAO.md` faz parte do MVP.** Nada é vendido antes de tudo estar pronto e verificado. A ordem de construção está em `docs/ROADMAP.md`.

### Fora do produto (decisão do usuário)
- **Jogos de qualquer tipo** (com ou sem aposta). Não especificar, não implementar.

### Fora do produto (decisão técnica/ética, ver ADR 0006)
- **Chamada privada simulada que se passa por real.** Enganar o usuário para gerar gasto não entra. Em seu lugar existe um tutorial de chamada claramente rotulado como demonstração (CHA11).

### Dentro, com trava jurídica (ver ADR 0006)
- Presente da sorte (retorno variável), cobrança por minuto em lives privadas e chamadas, revenda de moedas, comissões de agência e indicação. Ficam implementados atrás de *feature flags* desligadas por padrão até o cliente ter parecer jurídico.

## Ordem de construção (decisões do usuário, 2026-11-20)
1. **Aplicativo primeiro**, falando com um **servidor fake local** (`mock-server/`) que segue o contrato da API.
2. **Vídeo simulado primeiro**; o provedor de vídeo real (Agora) entra depois.
3. **Android primeiro**; iOS depois com o mesmo código.
4. **Um aparelho por conta**; saque, dados de recebimento, recarga web e assinatura de criador no **portal web**.
5. **Banco de dados depois**: tudo o que o app precisa guardar vai sendo registrado em `docs/DATABASE.md`, que é a base para construir o banco quando ele for escolhido.
