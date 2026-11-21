# Regras de negócio

> Regras numeradas citadas na especificação (`RN-xx`). Aplicadas **no servidor** (mock-server agora, backend depois); o app só exibe.
> **Todo valor numérico, limite, taxa e provedor aqui é configurável pelo comprador do app no painel admin** (decisão do usuário). Os números abaixo são o **padrão inicial** do tenant demo `liveapp`.
> Valores marcados **[DECIDIR Q-xx]** ainda dependem do usuário: o Claude não escolhe sozinho.
> Taxas, conversões e mínimos de saque **não aparecem no app**; aparecem só no portal web de saque quando necessário (ADR 0008).

## Conta e identidade
- **RN-01 Idade.** Produto 18+. Data de nascimento informada no cadastro e imutável depois. No cadastro, o app usa o **sinal de idade/faixa etária da loja** (Play Age Signals no Android) e bloqueia automaticamente quem for menor. **Verificação forte** (estimativa facial ou documento) é obrigatória para **transmitir** e para **sacar**, quando a verificação estiver ligada pelo comprador (padrão: ligada). Provedor escolhido pelo comprador via conector (ADR 0007). Menor detectado por qualquer meio: conta bloqueada (ENT10). Validação jurídica deste modelo: **[DECIDIR Q-41]**. Cálculo dos 18 anos: compara só datas (sem hora), no fuso do tenant (`tenant.json` → `timezone`); faz 18 no dia do aniversário.
- **RN-02 Código de verificação.** 6 dígitos; **validade de 60 s**; reenvio liberado após 60 s; máximo 5 envios por número por hora e 5 tentativas por código. Canal SMS ou WhatsApp.
- **RN-03 Senha.** Mínimo 8 caracteres com letras e números; recusar senhas muito comuns; só hash forte no servidor.
- **RN-04 Troca de senha** encerra a sessão ativa e exige novo login.
- **RN-05 Nomes.** Nome de exibição de 2 a 30 caracteres, filtrado. @ de 3 a 20 caracteres `[a-z0-9._]`, único, sem palavras reservadas; troca de @ no máximo a cada 30 dias.
- **RN-06 Um aparelho por conta.** Cada conta tem **uma única sessão ativa**. Entrar em outro aparelho encerra a sessão anterior: o aparelho antigo recebe aviso (`session.replaced`), é desconectado do tempo real e volta para o login. Sair (logout) encerra a sessão. Uma conexão em tempo real por conta (ADR 0009).
- **RN-07 Idiomas.** Português (pt-BR, padrão) e inglês (en). Interface preparada para idiomas da direita para a esquerda (RTL), sem idioma RTL ativo por enquanto.

## Economia
- **RN-20 Compras.** Moedas só são creditadas após validação do pagamento no servidor (recibo da Google Play ou confirmação do provedor alternativo/Pix configurado pelo comprador). Idempotência pelo identificador da compra.
- **RN-21 Confirmação de envio.** Envio acima de 10.000 moedas pede confirmação.
- **RN-22 Super presente.** Custo mínimo para ser "super" definido no catálogo; intervalo global mínimo de 60 s entre anúncios; fila quando houver mais de um.
- **RN-23 Presente → diamantes.** `diamantes = piso(moedas_gastas × (1 − taxa_plataforma))`. Taxa padrão **50%**, configurável pelo comprador (inclusive por tipo de origem: presente, chamada, live privada, mídia paga). A diferença vai para a receita da plataforma; comissões de agência e indicação saem da parte da plataforma.
- **RN-24 Estornos.** Estorno de pagamento debita as moedas correspondentes; sem saldo, a conta fica com saldo negativo bloqueando gastos e é sinalizada para análise.
- **RN-25 Saque.** Feito no **portal web** (ADR 0008). `reais = diamantes_sacaveis × taxa_conversao − taxa_fixa`. Conversão, mínimo, taxa fixa, limite por período, prazo de pagamento e retenção de diamantes recém-recebidos: configuráveis pelo comprador (padrões provisórios definidos na Fase 4 e revisados com o usuário). Exige verificação forte (RN-01) e dados de recebimento completos (RN-82). Diamantes ficam reservados enquanto o saque estiver pendente.
- **RN-26 Ledger.** Todo movimento é um conjunto de lançamentos que soma zero entre contas; imutável; correções por lançamento inverso com motivo e autor.
- **RN-27 Indicação.** Comissão padrão 5% sobre compras dos indicados por 90 dias, configurável. Flag `referrals`.
- **RN-28 Agência.** Comissão padrão 10% sobre os diamantes dos streamers vinculados (paga da parte da plataforma); carência de 30 dias para trocar de agência; configuráveis. Flag `agencies`.
- **RN-29 Moeda e tempo.** Reais em centavos (inteiro). Horários em UTC no servidor; exibição e períodos em `America/Sao_Paulo`.
- **RN-30 Moedas grátis e diamantes bônus.** Moedas de origem grátis (boas-vindas, resgates periódicos, recompensas) são marcadas no ledger. Presentes pagos com elas geram **diamantes bônus**, separados dos diamantes normais. O comprador configura: se diamantes bônus são sacáveis, em que proporção, com que limite por período e por usuário. Padrão: bônus **não sacáveis** e limitados a 10% do saldo de diamantes do mês.
- **RN-31 Anti-abuso de bônus.** Bônus uma vez por pessoa: verificado por aparelho, telefone e verificação de idade.
- **RN-32 Ordem de gasto.** Ao gastar, o servidor consome primeiro as moedas grátis e depois as pagas (configurável), e registra a proporção em cada transação para calcular diamantes normais e bônus.

## Live e interação
- **RN-40 Chat.** Máximo 200 caracteres; no máximo 1 mensagem por segundo por usuário; flood silencia automaticamente por 5 min.
- **RN-41 Curtidas.** Enviadas em lote a cada 3 s; limite por usuário por minuto no servidor.
- **RN-42 Compartilhamentos.** Limite diário de 50 compartilhamentos internos por usuário.
- **RN-43 Efeito de entrada.** Máximo 3 s; fila; nunca cobre controles.
- **RN-44 Expulsão.** Expulso não volta à mesma live até ela terminar (o host pode desfazer).
- **RN-45 Reembolso por expulsão.** Expulsão devolve o que foi cobrado pela entrada/minuto em andamento da live privada.
- **RN-46 Pausa e queda do host.** Em segundo plano, o público vê "host em pausa"; a live encerra após 60 s. Após queda, o host pode retomar em até 3 min.
- **RN-47 Vagas e qualidade.** Número de vagas no palco (convidados e live em grupo) e qualidade de vídeo são configurados **juntos** por modo (ex.: até 3 convidados em HD; até 8 no grupo em qualidade menor). Padrões provisórios: 3 convidados, 8 no grupo.
- **RN-48 Detecção de presença e conteúdo.** Detecção de rosto/corpo **no aparelho** durante a live (ADR 0010):
  - **Rosto/corpo ausente** por 30 s → aviso com contagem de 15 s → a live vira **privada automaticamente** (não encerra). Volta a pública quando o host reaparecer ou decidir. Configurável (flag `face_presence`, tempos).
  - **Conteúdo proibido detectado** (nudez, violência e o resto da RN-83) → a live é **encerrada** na hora, uma denúncia automática com evidência vai para a fila de moderação (prioridade alta) e o host recebe aviso. **Nunca** converte em live privada ou paga.
- **RN-49 Diretrizes.** Ver RN-83.

## Cobranças por tempo, PK e chamadas
- **RN-50 Reembolso inicial.** Live privada e chamada paga: se terminar nos primeiros **10 s** (configurável), tudo é reembolsado automaticamente.
- **RN-51 Privada → pública.** O host pode tornar pública a qualquer momento; quem pagou o minuto corrente não é cobrado de novo.
- **RN-52 Bônus do streamer.** Programa de bônus por tempo e metas, configurável no painel; créditos como diamantes bônus ou normais, conforme configuração.
- **RN-53 Preço por minuto = presente.** A streamer escolhe, num **menu de cobrança próprio**, qual presente é cobrado a cada minuto em: chamada de voz, chamada de vídeo e live privada. O menu mostra só os presentes que o comprador marcou como elegíveis para cobrança. O presente é enviado automaticamente no início de cada minuto, com aviso quando o saldo cobrir menos de 2 minutos.
- **RN-54 Chamada gratuita.** Entre seguidores mútuos; limite diário de 10 minutos.
- **RN-55 Convites.** Convite de PK e de palco expira em 15 s; convite de chamada em 30 s.
- **RN-56 Placar de PK.** Pontos = moedas dos presentes confirmados no ledger para aquele lado durante a batalha. Modos: 1x1, 4 participantes (todos contra todos) e por times. Durações: lista configurável (padrão 3, 5, 10 min).
- **RN-57 Desistência na PK.** Host que sai ou não reconecta em 30 s perde por desistência.

## Mensagens e social
- **RN-58 Custo para iniciar conversa.** Mecanismo vindo do servidor; **10 moedas** para mandar a primeira mensagem a quem não segue de volta; **desligado por padrão**; configurável.
- **RN-59 Limites de mensagens.** Até 3 conversas fixadas; mensagens automáticas e envio para vários com limite de 100 destinatários/dia, sempre identificados como automáticos.
- **RN-60 Rankings.** Períodos dia/semana/mês no fuso `America/Sao_Paulo`; anonimato como benefício configurável.
- **RN-61 Experiência e níveis (1 a 100).**
  - XP ganho: 1 XP por moeda gasta; 1 XP por minuto assistindo (máx. 60/dia); 2 XP por minuto transmitindo (máx. 240/dia). Pesos configuráveis.
  - XP para ir do nível `n` ao `n+1`: `xp(n) = arredonda(50 × n^2,2)`. Exemplos: nível 1→2: 50 XP; 5→6: ~1.700; 10→11: ~7.900; 30→31: ~89.000; 50→51: ~272.000; 99→100: ~1,2 milhão. Total até o 100: ~39 milhões de XP. Fácil no começo, muito difícil no fim.
  - Curva (constante e expoente) e recompensas por nível configuráveis no painel.
- **RN-62 Assinatura de criador.** Paga em **reais por checkout web** (ADR 0008). Preço mensal entre R$ 9,90 e R$ 99,90 (padrão); divisão de receita padrão 70% criador / 30% plataforma, antes das taxas do provedor de pagamento; configuráveis.
- **RN-63 Famílias.** Requisitos para criar: nível mínimo (padrão 10) e custo em moedas (padrão 10.000); limite de membros (padrão 50, cresce com o nível da família); tudo configurável no painel.

## VIP
- **RN-70 Níveis VIP por gasto.** O VIP **não é comprado**: é calculado pelas **moedas gastas nos últimos 7 dias** (janela móvel), recalculado a cada gasto e diariamente. Limiares padrão (configuráveis):
  | Nível | Moedas gastas em 7 dias |
  | --- | --- |
  | Bronze | 1.000 |
  | Prata | 5.000 |
  | Ouro | 20.000 |
  | Platina | 60.000 |
  | Diamante | 150.000 |
  | Desafiante | 400.000 |
  Benefícios por nível configuráveis no painel (efeitos, molduras, privacidade, sussurro, incógnito, intocável, anonimato no ranking, presentes exclusivos). O nível cai quando o gasto da janela fica abaixo do limiar (aviso 1 dia antes, configurável).
- **RN-71 Privacidade VIP em listas.** Quem ativou ocultação aparece anônimo em espectadores, visitas e rankings, mas é sempre identificável pela moderação.
- **RN-72 Sussurro.** Mensagens e presentes de quem está em sussurro só aparecem para o host; para os demais, o presente conta no total sem identificar o remetente.
- **RN-73 Intocável.** VIP a partir de **Diamante** (configurável) não pode ser silenciado/expulso pelo host ou moderador da live, exceto em modo incógnito. A moderação da plataforma sempre pode agir.
- **RN-74 Loja VIP.** Itens comprados com **moedas**; alguns exigem nível VIP mínimo.

## Privacidade, conteúdo e provedores
- **RN-80 Exclusão de conta.** Carência de 30 dias para desistir; depois, dados pessoais apagados ou anonimizados; registros financeiros e de moderação retidos pelo prazo legal. **[DECIDIR Q-33]** com jurídico.
- **RN-81 Moderação de mídia.** Fotos, vídeos e capas passam por moderação automática antes de ficarem públicos; provedor configurável (padrão: o mais acessível, Q-39).
- **RN-82 Dados pessoais.** CPF, documento, data de nascimento, telefone e chave Pix são dados pessoais: criptografados em repouso, mascarados em telas e logs, acessíveis no painel só por papéis autorizados com auditoria. Saque exige chave Pix do tipo CPF do próprio titular verificado.
- **RN-83 Diretrizes de conteúdo.** Proibido: nudez, violência, discurso de ódio, transmitir dirigindo e participação de menores de 18 anos. Texto completo das diretrizes editável pelo comprador; versão aceita registrada (ENT16, TRA01).
- **RN-84 Provedores configuráveis.** Pagamentos (loja alternativa, Pix, checkout web), SMS/WhatsApp, verificação de idade, tradução, moderação de mídia, anti-bot e push são escolhidos e configurados pelo comprador no painel (ADM19), via conectores do servidor (ADR 0007). Credenciais nunca chegam ao app.
- **RN-85 Anti-bot.** App Check (integridade do app), reCAPTCHA Enterprise e Turnstile, cada um ligado por flag; o servidor decide quando exigir desafio.
