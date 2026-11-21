# Questões abertas (decisões do usuário)

> O Claude **não decide** estes pontos sozinho. Quando uma tarefa depender de uma questão aberta:
> 1. pergunte ao usuário (com opções, prós e contras e uma recomendação);
> 2. registre a resposta aqui (data e decisão) e mova a linha para "Respondidas";
> 3. aplique a decisão em `docs/REGRAS-DE-NEGOCIO.md`, `docs/ESPECIFICACAO.md`, `docs/DATABASE.md` e no código.
> Enquanto não houver resposta, use o valor provisório e deixe-o configurável.
> Novas dúvidas descobertas durante o trabalho entram aqui com o próximo número.
> **Princípio geral (decisão do usuário, 2026-11-20):** tudo que é valor de negócio, limite ou provedor deve ser **configurável pelo comprador do app no painel admin**, sem depender de nós.

## Abertas

| ID | Questão | Bloqueia | Sugestão inicial do Claude |
| --- | --- | --- | --- |
| Q-26 | Framework do backend real | Fase 11 | NestJS + TypeScript |
| Q-27 | Banco de dados | Fase 11 | Decidir com base no `docs/DATABASE.md` pronto (relacional recomendado pela natureza financeira) |
| Q-33 | Exclusão de conta: carência e retenção (RN-80) | CFG12 | 30 dias; retenção definida pelo jurídico |
| Q-35 | Verificação de idade: comparar preço e conformidade de Yoti e provedores brasileiros (ProtegeID, VerifiqueID) | ENT09 (Fase 12) | Pesquisa do `pesquisador` + proposta comercial dos provedores |
| Q-36 | Verificação de idade no iOS (recursos de idade da Apple) | iOS | Planejar quando o iOS entrar |
| Q-37 | Confirmar em fonte oficial se o Brasil está no programa de escolha de faturamento do Google e as condições (taxa, exigências) | ECO02, POR04 (Fase 12) | Pesquisa do `pesquisador` + jurídico |
| Q-38 | Repasse aos criadores: sub-contas por criador num PSP licenciado ou intermediador que já resolve | POR02, POR05 (Fase 12) | Confirmar com PSP/jurídico; intermediador pode dispensar sub-contas |
| Q-39 | Provedor de moderação de mídia "mais acessível do mercado" | RN-81 (Fase 12) | Pesquisa de preço por imagem/minuto |
| Q-40 | Provedor de tradução gratuito (no servidor ou no aparelho) | ASS03 (Fase 12) | Avaliar tradução no aparelho (sem custo) vs. API gratuita com limites |
| Q-41 | Validar com advogado o modelo de idade da Q-08 (autodeclaração + sinal da loja no cadastro; verificação forte só para transmitir e sacar) diante do ECA Digital | publicação | Jurídico antes da Fase 13 |
| Q-47 | Detecção de país no backend real (ENT18): base de geolocalização por IP (ex.: MaxMind GeoLite2 grátis, ou serviço pago) | ENT18 (Fase 11/12) | Base local GeoLite2 no servidor (sem custo por consulta); revisar com o jurídico se precisa de algo mais forte |

## Respondidas

| ID | Questão | Decisão | Data |
| --- | --- | --- | --- |
| Q-00a | Mecânicas de risco | Jogos com aposta fora; o resto fica (ajuste jurídico depois). Chamada simulada que se passa por real fica fora (ADR 0006). | 2026-11-20 |
| Q-00b | Dados antes do backend | Servidor fake local (`mock-server/`) | 2026-11-20 |
| Q-00c | Vídeo antes do backend | Vídeo simulado primeiro | 2026-11-20 |
| Q-00d | Escopo | Todo o produto dentro do MVP | 2026-11-20 |
| Q-00e | Plataforma inicial | Só Android primeiro | 2026-11-20 |
| Q-01 | Nome do tenant de demonstração | `liveapp` | 2026-11-20 |
| Q-02 | Identidade visual | Tema claro e escuro; layout preparado para RTL. Cores/fonte do demo seguem em Q-42. | 2026-11-20 |
| Q-03 | Taxa da plataforma | Não aparece no app; configurável pelo comprador no painel (todas as taxas de retorno); provisório 50% | 2026-11-20 |
| Q-04 | Conversão e saque | Não aparecem no app; configuráveis no painel. Diamante **normal** separado de diamante **bônus** no ledger. Saque e dados de recebimento são **páginas web** (portal), não telas do app (ADR 0008) | 2026-11-20 |
| Q-05 | Pacotes de moedas | Vêm do servidor com etiquetas (primeira compra, super, mega…); preços não aparecem fixos; faixas com bônus crescente; tudo editável pelo comprador | 2026-11-20 |
| Q-06 | Moedas grátis geram diamantes? | Geram diamantes **bônus**, com limites e regras de saque configuráveis pelo comprador | 2026-11-20 |
| Q-07 | Verificação de idade | Yoti (estimativa facial + documento) + Play Age Signals como base. Verificação **ligável/desligável** pelo comprador e com **provedor escolhido por ele** via conector (ADR 0007). Comparação de preço/conformidade em Q-35; Apple em Q-36 | 2026-11-20 |
| Q-08 | Momento da verificação | Cadastro com data autodeclarada + sinal de idade/faixa etária da loja bloqueando menores automaticamente; verificação forte obrigatória só para **transmitir** (e para sacar). Validação jurídica em Q-41 | 2026-11-20 |
| Q-09 | Códigos SMS/WhatsApp | SMS e WhatsApp, validade de 60 s; provedor configurável pelo comprador via conector | 2026-11-20 |
| Q-10 | Filtros de beleza | Beleza básica da Agora | 2026-11-20 |
| Q-11 | Tradução | No servidor; melhor provedor gratuito; pode ser fora do servidor se não pesar (provedor em Q-40) | 2026-11-20 |
| Q-12 | Pagamentos fora da Play | Via intermediador de pagamento ou página web, com provedor configurável pelo comprador via conector. Confirmação oficial do programa do Google em Q-37 | 2026-11-20 |
| Q-13 | Saque e titularidade | Chave Pix do tipo CPF do próprio titular verificado; repasse por sub-contas ou intermediador (Q-38) | 2026-11-20 |
| Q-14 | Forma de pagamento | Assinatura de criador em **dinheiro real por checkout web**; loja VIP com moedas; VIP **não** é assinatura (ver item 1) | 2026-11-20 |
| Q-15 | Limites ao vivo | PK 1x1, de 4 e por times; durações em lista configurável; vagas e qualidade de vídeo configuráveis juntas; tudo vindo do servidor | 2026-11-20 |
| Q-16 | Anti-bot | App Check (integridade), reCAPTCHA Enterprise e Turnstile, cada um ligado por flag do servidor | 2026-11-20 |
| Q-17 | Dispositivos | **Um aparelho por conta.** Entrar em outro aparelho encerra a sessão do anterior (ADR 0009) | 2026-11-20 |
| Q-18 | Jogos | Sem jogos no app, de nenhum tipo | 2026-11-20 |
| Q-19 | Diretrizes de conteúdo | Proibido: nudez, violência, discurso de ódio, transmitir dirigindo, menores de 18 | 2026-11-20 |
| Q-20 | Detecção automática | Rosto/corpo detectados no aparelho durante a live. Rosto ausente → live vira privada automaticamente. Conteúdo proibido (nudez etc.) → live encerrada e enviada à moderação (ADR 0010). Provedor de moderação de mídia: o mais acessível (Q-39) | 2026-11-20 |
| Q-21 | Experiência e níveis | Teto no nível 100; muito fácil no começo, muito difícil no fim (curva em RN-61, configurável) | 2026-11-20 |
| Q-22 | VIP | Níveis bronze, prata, ouro, platina, diamante e desafiante, calculados por **moedas gastas nos últimos 7 dias**. Limiares sugeridos em RN-70, alteráveis pelo comprador. Assinatura VIP pela loja removida | 2026-11-20 |
| Q-23 | Custo para iniciar conversa | Mecanismo existe, vindo do servidor; 10 moedas; desligado por padrão; alterável | 2026-11-20 |
| Q-24 | Cobrança por minuto | O preço por minuto de chamadas e lives privadas é um **presente escolhido pela streamer** num menu próprio de cobrança; janela de reembolso configurável, padrão 10 s | 2026-11-20 |
| Q-25 | Comissões de agência e indicação | Sugestão do Claude adotada: configuráveis pelo comprador no painel; valores iniciais em RN-27/RN-28 | 2026-11-20 |
| Q-28 | Analytics e falhas | Sugestão do Claude adotada: Firebase Analytics + Crashlytics, atrás de `AnalyticsProvider` | 2026-11-20 |
| Q-29 | Regiões | Sugestão do Claude adotada: só Brasil no demo; configurável pelo comprador | 2026-11-20 |
| Q-30 | Idiomas | Português (pt-BR) e inglês (en); estrutura pronta para RTL | 2026-11-20 |
| Q-31 | Famílias | Nível mínimo + custo em moedas + limite de membros, configuráveis pelo comprador no painel | 2026-11-20 |
| Q-32 | Assinatura de criador: limites e divisão | Sugestão do Claude adotada: configuráveis pelo comprador no painel; valores iniciais em RN-62 | 2026-11-20 |
| Q-34 | Confirmação de envio e super presente | Sugestão do Claude adotada: confirmação acima de 10.000 moedas; intervalo de 60 s entre anúncios; configuráveis | 2026-11-20 |
| Q-42 | Cores, fonte e ícones do tenant demo `liveapp` | Paleta Magenta + Laranja: marca `#E91E8C`, ação com texto branco `#D6157E` (4,92:1, AA), secundária `#FF9100` sempre com texto escuro `#0E0E12` (8,5:1). Fonte Plus Jakarta Sans. Ícones Material Symbols. Valores em `tenants/liveapp/tenant.json` | 2026-11-20 |
| Q-43 | Como o app sabe de mudanças de config antes do login (sem token não há tempo real) | Rebuscar `GET /v1/config` ao abrir e ao voltar do segundo plano; logado, `config.updated` pelo tempo real. Sem conexão anônima (ADR 0011) | 2026-11-20 |
| Q-44 | Como validar E2E de itens sem dependência nativa do Android | Fluxo no navegador (Flutter web + Playwright, `apps/mobile/e2e/web/`) vale como E2E. Maestro no Android (celular ou emulador no CI) passa a ser exigido quando o item depender de recurso nativo (câmera, permissões, vídeo nativo, push, compra na loja). Itens TRV da fundação podem compartilhar um fluxo único | 2026-11-21 |
| Q-45 | Visual da tela de boas-vindas (ENT02) | Simples e limpa: fundo do tema (claro/escuro), nome/logo do tenant e botões | 2026-11-21 |
| Q-46 | Onde abrir termos e política (ENT03, ENT16) | Tela do app com WebView (`webview_flutter`) carregando a página do portal; navegação travada no domínio do portal | 2026-11-21 |
| Q-48 | Botão voltar na barra principal (NAV01) | Dentro da aba volta na pilha; na raiz de outra aba vai para Descobrir; em Descobrir pede "toque de novo para sair" (2 s) | 2026-11-21 |
| Q-49 | Aba Seguindo para visitante | Tela vazia com convite ("Entre para ver quem você segue" + Entrar), sem abrir o pedido de login | 2026-11-21 |
| Q-50 | Validade da sessão (refresh token) | 30 dias sem uso, configurável pelo comprador; token de acesso de 15 min renova sozinho | 2026-11-21 |
| Q-51 | Preenchimento automático do código SMS no Android (ENT04) | Fica para quando o SMS real entrar (Fase 12); até lá o mock mostra o código para teste e ENT04 fica `[~]` | 2026-11-21 |
| Q-52 | Cadastro inicial (ENT08) no plano 1b? | Não: plano 1c logo depois; na 1b conta nova vai para "complete seu cadastro (em breve)" | 2026-11-21 |
| Q-53 | Login com Google antes da Fase 12 | Contas de teste do mock (nova/existente/erro/cancelar) seguindo o mesmo contrato do Google real | 2026-11-21 |
| Q-54 | Validade máxima absoluta da sessão | 180 dias desde o login, mesmo com uso diário; configurável pelo comprador (além dos 30 dias sem uso da Q-50) | 2026-11-21 |
| Q-55 | Diretrizes da comunidade obrigatórias? | Sim: termos, privacidade e diretrizes são aceitos por todos ao entrar; nova versão de qualquer um exige novo aceite (ENT16) | 2026-11-21 |
| Q-56 | Bônus de boas-vindas e recompensa de telefone: ledger agora ou na Fase 4? | Ledger mínimo (dupla entrada, idempotente) já no plano 1c, só para créditos de bônus; a Fase 4 amplia | 2026-11-21 |
| Q-57 | ENT09 (verificação forte de idade): quando construir? | Agora (plano 1c) com o conector fake; provedor real na Fase 12 (Q-35) | 2026-11-21 |
| Q-58 | ENT10: o que guardar de quem é bloqueado por ser menor | A conta fica congelada inteira (sem acesso), para revisão da equipe | 2026-11-21 |
| Q-59 | ENT08: gênero | Opcional, 4 opções (Mulher, Homem, Não-binário, Prefiro não dizer); privado: só a própria pessoa vê | 2026-11-21 |
| Q-60 | ENT13: valor padrão do bônus de boas-vindas | Desligado por padrão; o comprador liga e define o valor no painel | 2026-11-21 |
| Q-61 | ENT14: recompensa padrão por vincular telefone | Desligada por padrão; o comprador liga e define o valor no painel | 2026-11-21 |
| Q-62 | RN-31: quando creditar o bônus de quem entrou sem telefone | Só depois de ter telefone (quem entrou por telefone recebe ao terminar o cadastro; e-mail/Google ao vincular o telefone); uma vez por aparelho, telefone e verificação de idade | 2026-11-21 |
| Q-63 | ENT10: quem desfaz o congelamento e por quanto tempo guardar | Revisão da equipe (pedido pelo suporte); liberar só com verificação forte de idade aprovada; sem prazo de exclusão automática (confirmar com o jurídico, Q-41) | 2026-11-21 |
| Q-64 | ENT08: sinal de idade da Play Store (Play Age Signals) | Interface `AgeSignalProvider` + fake no plano 1c; plugin nativo próprio com a biblioteca oficial na Fase 12 (API em beta; só testável com o app na loja) | 2026-11-21 |
| Q-65 | ENT10: bloquear também o aparelho de quem foi congelado por ser menor? | Sim: o aparelho fica marcado; login ou cadastro nele vai para a tela de bloqueio até a revisão da equipe, que pode liberar o aparelho | 2026-11-21 |
