# Especificação completa do produto

> **Fonte da verdade** do que o produto precisa ter. Todo o conteúdo é MVP (decisão do usuário).
> Documento vivo: quando o usuário decidir algo novo, atualize aqui (e registre a decisão em `docs/QUESTOES-ABERTAS.md`).
> Status: `[ ]` não iniciado · `[~]` em andamento · `[x]` pronto (cumpre a Definição de pronto) · `[-]` removido por decisão do usuário (manter o motivo)
> Flags: itens marcados 🚩`flag` só aparecem quando a feature flag está ligada (padrão desligada quando indicado).
> Regras numeradas (`RN-xx`) estão em `docs/REGRAS-DE-NEGOCIO.md`. Dados em `docs/DATABASE.md`. Endpoints em `docs/API.md`. Eventos em `docs/EVENTOS-TEMPO-REAL.md`.

## Definição de pronto (vale para todo item)
1. Todos os critérios de aceite funcionando contra o mock-server (e depois contra o backend real).
2. Estados de **carregando, vazio, erro, sem conexão e sem permissão** tratados na tela.
3. Textos em pt-BR via arquivo de tradução; marca, cores e nome vindos do tenant.
4. Acessibilidade básica: rótulos para leitor de tela, alvo de toque ≥ 48dp, contraste AA, funciona com fonte grande.
5. Testes: unitários de regra/estado, widget da tela, contrato no mock-server para os endpoints usados.
6. Fluxo E2E cobrindo o caminho principal e ao menos um erro (itens de tela): no navegador (`apps/mobile/e2e/web/<ID>.cjs`, Playwright) para itens sem recurso nativo; no Android (`apps/mobile/e2e/<ID>.yaml`, Maestro) quando o item usa câmera, permissões, vídeo nativo, push ou compra na loja (Q-44).
7. Dados e contratos usados registrados em `docs/DATABASE.md`, `docs/API.md` e `docs/EVENTOS-TEMPO-REAL.md`.
8. Revisado pelo subagente `revisor`; e pelo `revisor-seguranca` se toca em dinheiro, auth, dados pessoais, moderação ou menores.
9. Eventos de analytics do item disparados (quando houver).

---

## ENT · Entrada, conta e identidade

- [ ] **ENT01 Splash e inicialização**
  - Aceite: carrega config do tenant e do servidor (flags, textos legais, versão mínima); registra o dispositivo; restaura sessão; decide entre Home, Boas-vindas, Atualização obrigatória ou Manutenção; tempo máximo de espera com tela de erro e "tentar de novo".
  - Dados: Dispositivo, ConfigApp · Depende: TRV03, TRV04
- [ ] **ENT02 Boas-vindas e modo visitante**
  - Aceite: marca do tenant; botões Entrar, Criar conta e "Explorar sem conta"; visitante navega e assiste, mas qualquer interação abre ENT17.
- [ ] **ENT03 Escolha do método de entrada**
  - Aceite: telefone, e-mail e Google (métodos ativos vêm das flags); link para termos e política; aviso 18+.
- [ ] **ENT04 Telefone + código (SMS/WhatsApp)**
  - Aceite: seletor de país (Brasil padrão), máscara, código de 6 dígitos com validade de 60 s (RN-02) e reenvio com contagem regressiva; limite de tentativas; preenchimento automático do código no Android; canal SMS ou WhatsApp conforme flag; provedor de envio configurado pelo comprador (RN-84).
  - Dados: Usuario, MetodoLogin, CodigoVerificacao
- [ ] **ENT05 E-mail + senha**
  - Aceite: cadastro e login; força mínima da senha (RN-03); confirmação de e-mail por código; mensagens de erro que não revelam se o e-mail existe.
- [ ] **ENT06 Login com Google**
  - Aceite: conta nova cai em ENT08; conta existente entra direto; erro e cancelamento tratados.
- [ ] **ENT07 Recuperar senha**
  - Aceite: código por e-mail → nova senha → encerra outras sessões (RN-04).
- [ ] **ENT08 Dados iniciais**
  - Aceite: nome de exibição (RN-05), data de nascimento (não editável depois, RN-01), gênero opcional; o app consulta o sinal de idade/faixa etária da loja (Play Age Signals) e, se indicar menor, ou se a data indicar menor, vai para ENT10.
- [ ] **ENT09 Verificação forte de idade**
  - Aceite: exigida para transmitir e para sacar (RN-01) quando ligada pelo comprador (padrão ligada); métodos estimativa facial e documento; provedor escolhido pelo comprador via conector (padrão Yoti); estados pendente/aprovado/reprovado/expirado; reprovado não transmite nem saca; menor detectado vai para ENT10; resultado chega por evento. Desligada pelo comprador: o fluxo some e TRA01 não exige.
  - Dados: VerificacaoIdade · Depende: TRV13, ADM19 · Jurídico: Q-41
- [ ] **ENT10 Bloqueio de menor de idade**
  - Aceite: tela explicativa, sem acesso ao app; conta marcada e dados mínimos retidos conforme RN-01; sem como "voltar e mudar a data".
- [ ] **ENT11 Criar @ (nome de usuário)**
  - Aceite: validação em tempo real de disponibilidade e formato (RN-05); sugestões.
- [ ] **ENT12 Escolher interesses**
  - Aceite: categorias do servidor; pular permitido; usadas na descoberta.
- [ ] **ENT13 Bônus de boas-vindas**
  - Aceite: overlay com moedas iniciais quando ativo (RN-30); crédito via ledger; uma vez por pessoa (anti-abuso, RN-31).
- [ ] **ENT14 Vincular telefone com recompensa**
  - Aceite: oferecido a quem entrou por e-mail/Google; recompensa configurável; uma vez por número.
- [ ] **ENT15 Contas vinculadas**
  - Aceite: ver e vincular/desvincular métodos; não permite remover o último método.
- [ ] **ENT16 Aceite de termos e política**
  - Aceite: aceite registrado com versão e data; nova versão exige novo aceite antes de continuar.
  - Dados: AceiteTermos
- [ ] **ENT17 Login exigido (bottom sheet)**
  - Aceite: aparece quando visitante tenta interagir; após entrar, retoma a ação que ele tentou.
- [ ] **ENT18 Restrição regional**
  - Aceite: países permitidos configuráveis pelo cliente; fora da região mostra tela informativa (detecção por servidor).
- [ ] **ENT19 Sessão e dispositivos**
  - Aceite: um aparelho por conta (RN-06): entrar em outro aparelho encerra a sessão do anterior, que recebe aviso "sua conta entrou em outro aparelho" e volta ao login; renovação automática do token; sessão expirada leva ao login sem perder o contexto da navegação.

## NAV · Navegação e estrutura

- [ ] **NAV01 Navegação principal**
  - Aceite: barra inferior com Descobrir, Seguindo, botão central "Ao vivo", Mensagens (com contador), Perfil; estado preservado por aba; voltar do Android com comportamento previsível.
- [ ] **NAV02 Links diretos (deep links)**
  - Aceite: abrir live, perfil, post, convite de família/agência e indicação por link; funciona com app fechado e aberto; visitante cai em ENT17 quando preciso.
- [ ] **NAV03 Banners e avisos do servidor**
  - Aceite: banners na Descobrir e overlays promocionais enviados pelo servidor (com frequência máxima); destino por deep link.
- [ ] **NAV04 Tutoriais de primeira vez**
  - Aceite: dicas curtas em presentes, PK, chamadas, convidados etc.; mostradas uma vez por conta (persistido no servidor).
- [ ] **NAV05 Janela flutuante (Picture-in-Picture)**
  - Aceite: ao sair da live, continua em janela flutuante (configurável); tocar volta para a live; encerra se a live acabar.

## DES · Descoberta

- [ ] **DES01 Descobrir com abas**
  - Aceite: abas Popular, Perto de você/País, Novos, PK ao vivo, Multi (lives em grupo), Chamadas (streamers disponíveis); ordem e abas ativas vindas do servidor; puxar para atualizar; paginação infinita.
- [ ] **DES02 Filtro de país/região**
  - Aceite: seletor de país; persistido; afeta Popular e Ranking.
- [ ] **DES03 Card de live**
  - Aceite: capa, título, nome, espectadores, selos (PK, privada, multi, VIP, novo); prévia animada opcional.
- [ ] **DES04 Deslizar entre lives**
  - Aceite: na live, deslizar para cima/baixo troca de live seguindo a lista de origem; pré-carrega a próxima.
- [ ] **DES05 Busca**
  - Aceite: por nome, @ e ID numérico; usuários e lives; histórico local apagável; debounce; estado vazio útil.
- [ ] **DES06 Sugestões**
  - Aceite: streamers sugeridos na aba Seguindo vazia e ao fim de uma live.
- [ ] **DES07 Rankings**
  - Aceite: streamers (diamantes), doadores (moedas), famílias; períodos dia/semana/mês; filtro por país; posição do próprio usuário; quem escolheu anonimato aparece como anônimo (RN-60).
- [ ] **DES08 Central de notificações**
  - Aceite: lista paginada por tipo (seguidor, live começou, presente, sistema, financeiro); marcar como lida; deep link de cada item.
- [ ] **DES09 Seguindo**
  - Aceite: quem eu sigo e está ao vivo agora no topo; depois postagens/atividade; estado vazio com sugestões.

## ASS · Assistir live (espectador)

- [ ] **ASS01 Tela da live (espectador)**
  - Aceite: vídeo em tela cheia; topo com host, seguir, espectadores, ranking da live; rodapé com chat, presente, compartilhar, curtir; estados conectando/reconectando/sem vídeo/host em pausa; sair com um toque.
  - Eventos: live.*, chat.*, gift.*
- [ ] **ASS02 Chat da live**
  - Aceite: mensagens em tempo real com nível/selo do autor; @menção; emoji; limite de tamanho e frequência (RN-40); filtro de palavras do servidor; mensagens do sistema (entrou, seguiu, presente); rolar sem perder novas.
- [ ] **ASS03 Traduzir mensagem**
  - Aceite: toque longo → traduzir para pt-BR; mostra original e tradução.
- [ ] **ASS04 Curtidas**
  - Aceite: tocar na tela gera corações; envio agrupado ao servidor (RN-41); contador da live.
- [ ] **ASS05 Seguir o host**
  - Aceite: botão no topo e sugestão após N minutos assistindo; sistema avisa na live.
- [ ] **ASS06 Espectadores e top doadores**
  - Aceite: lista de quem assiste (ordenada por contribuição/nível) e top doadores da live; VIP com privacidade aparece conforme RN-71.
- [ ] **ASS07 Perfil rápido (bottom sheet)**
  - Aceite: foto, nome, nível, seguidores; seguir, mensagem, perfil completo, denunciar; para host/moderador: silenciar, expulsar, tornar moderador.
- [ ] **ASS08 Compartilhar live**
  - Aceite: link externo e envio para conversas do app; limite de compartilhamentos (RN-42).
- [ ] **ASS09 Pedir para subir ao palco**
  - Aceite: pedido ao host; status aguardando/aceito/recusado; ao aceitar abre prévia de câmera e entra como convidado (TRA07).
- [ ] **ASS10 Live encerrada**
  - Aceite: aviso de fim, duração, seguir host, sugestões de outras lives.
- [ ] **ASS11 Denunciar**
  - Aceite: denunciar live, usuário ou mensagem com motivos do servidor (SEG01); "possível menor de idade" com prioridade máxima; confirmação.
- [ ] **ASS12 Modo sussurro (VIP)**
  - Aceite: entrar discretamente; só o host vê mensagens e presentes do usuário (RN-72); aviso claro ao ligar.
- [ ] **ASS13 Modo incógnito (VIP)**
  - Aceite: aparece como anônimo na live; perde proteção de "intocável" (RN-73).
- [ ] **ASS14 Entrada com efeito**
  - Aceite: animação de entrada para quem tem item/VIP equipado; respeita fila e não cobre o vídeo por mais que RN-43.
- [ ] **ASS15 Barra de meta da live**
  - Aceite: título, progresso e prazo definidos pelo host; atualiza em tempo real; comemoração ao bater.
- [ ] **ASS16 Expulso, silenciado ou bloqueado**
  - Aceite: feedback claro (expulso não volta por RN-44; silenciado vê aviso ao tentar escrever); reembolso de entrada paga quando expulso (RN-45).

## PRE · Presentes e interações pagas na live

- [ ] **PRE01 Painel de presentes**
  - Aceite: categorias e abas do servidor; preço em moedas; saldo visível; quantidade (1, 10, 99, personalizado); presentes bloqueados por VIP/nível com cadeado e explicação; destinatário (host ou convidado do palco).
- [ ] **PRE02 Envio em lote e combo**
  - Aceite: combo por toques seguidos com contador; aviso de confirmação acima do valor de RN-21; idempotência por envio.
- [ ] **PRE03 Animações de presentes**
  - Aceite: comuns na lateral (empilháveis), grandes em tela cheia, fila com prioridade por valor; formatos Lottie e vídeo; pré-download do catálogo; nunca trava o chat.
- [ ] **PRE04 Super presente**
  - Aceite: anúncio em todas as lives (faixa clicável que leva à live); opção do usuário ocultar anúncios; intervalo mínimo entre anúncios (RN-22).
- [ ] **PRE05 Presente da sorte** 🚩`lucky_gift` (desligada por padrão, trava jurídica, ADR 0006)
  - Aceite: regras e probabilidades exibidas antes do envio; retorno calculado só no servidor e registrado no ledger; limite diário por usuário.
- [ ] **PRE06 Presentes exclusivos**
  - Aceite: presentes que exigem VIP ou nível mínimo; servidor valida.
- [ ] **PRE07 Sticker com meta**
  - Aceite: host fixa um sticker com meta de presente; progresso em tempo real.
- [ ] **PRE08 Roleta de pedidos do host**
  - Aceite: host cria roleta com opções (ex.: cantar, dançar); espectador gira enviando presente definido; resultado sorteado no servidor e mostrado a todos; o resultado é uma ação do host, nunca dinheiro.
- [ ] **PRE09 Menu de gorjetas**
  - Aceite: host define itens com preço (ex.: "mandar um oi"); espectador escolhe e confirma; aparece no chat em destaque.
- [ ] **PRE10 Saldo insuficiente**
  - Aceite: ao faltar moedas, oferece o pacote mais adequado (sugerido pelo servidor) sem sair da live; após compra, conclui o envio pendente se o usuário confirmar.
- [ ] **PRE11 Pacote de presentes**
  - Aceite: pacotes promocionais (ex.: compra que dá presentes na bolsa); tela de parabéns; itens vão para VIP06.
- [ ] **PRE12 Menu de cobrança da streamer**
  - Aceite: a streamer escolhe qual presente é cobrado por minuto em chamada de voz, chamada de vídeo e live privada, entre os presentes que o comprador marcou como elegíveis; prévia do valor por minuto; mudança vale para a próxima chamada/live (RN-53).

## TRA · Transmitir (host)

- [ ] **TRA01 Pré-requisitos para transmitir**
  - Aceite: verificação forte de idade aprovada (ENT09, se ligada), foto de perfil, aceite das diretrizes de conteúdo (RN-83, versão registrada), conta sem bloqueio; cada pendência mostra o que fazer.
- [ ] **TRA02 Preparar live**
  - Aceite: prévia da câmera; título, capa, categoria; tipo (pública, privada paga, em grupo); trocar câmera; permissões de câmera e microfone com explicação e caminho para configurações (CFG13).
- [ ] **TRA03 Filtros de beleza**
  - Aceite: beleza básica do provedor de vídeo (Agora): suavizar, clarear, nitidez; valores lembrados; desempenho estável. Com vídeo simulado, controles funcionam sem efeito visual.
  - Depende: TRV02
- [ ] **TRA04 Tela do host**
  - Aceite: vídeo, chat, presentes recebidos com total de diamantes da live, espectadores, meta (ASS15), botões de controle, convites pendentes (palco, PK) com contador.
- [ ] **TRA05 Controles de mídia**
  - Aceite: ligar/desligar microfone e câmera, trocar e espelhar câmera; ao ir para segundo plano o público vê "host em pausa" e a live encerra após RN-46.
- [ ] **TRA06 Moderação pelo host**
  - Aceite: silenciar (tempo definido), expulsar (com reembolso de entrada paga, RN-45), nomear/remover moderadores da live, palavras bloqueadas próprias; VIP intocável respeitado (RN-73).
- [ ] **TRA07 Convidados no palco**
  - Aceite: aceitar/recusar pedidos, convidar espectador, remover, mutar áudio do convidado; limite de vagas (RN-47); layout se ajusta à quantidade.
- [ ] **TRA08 Live em grupo (multi-host)**
  - Aceite: vagas configuráveis (RN-47); fila de espera; convites; trocar posição; presentes podem ir para qualquer participante.
- [ ] **TRA09 Editar título ao vivo**
  - Aceite: muda para todos em tempo real; passa pelo filtro de palavras.
- [ ] **TRA10 Encerrar live**
  - Aceite: confirmação; encerra PK/convidados com aviso a todos; vai para TRA11.
- [ ] **TRA11 Resumo pós-live**
  - Aceite: duração, pico e total de espectadores, novos seguidores, diamantes, top doadores; compartilhar resultado.
- [ ] **TRA12 Retomar após queda**
  - Aceite: se o app fechar ou a rede cair, ao voltar em até RN-46 oferece continuar a mesma live.
- [ ] **TRA13 Detecção de presença e de conteúdo**
  - Aceite: detecção no aparelho (RN-48, ADR 0010). Rosto/corpo ausente: aviso com contagem e conversão automática da live em **privada**, com aviso ao host e ao público; volta a pública quando o host reaparecer. Conteúdo proibido detectado: live **encerrada**, denúncia automática com evidência para a moderação, aviso ao host. Tempos e ações configuráveis no painel (ADM21).
- [ ] **TRA14 Live privada paga** 🚩`paid_per_minute`
  - Aceite: o preço por minuto é o presente que o host escolheu no menu de cobrança (PRE12, RN-53); espectador vê o presente, o valor em moedas e o saldo e confirma; contador de custo visível; cobrança periódica no servidor; reembolso automático se sair nos primeiros RN-50; saldo acabando avisa antes e remove ao zerar; host pode tornar pública (RN-51).
- [ ] **TRA15 Convidar para live privada**
  - Aceite: host convida espectadores específicos; convite com preço; aceitar leva ao fluxo de TRA14.
- [ ] **TRA16 Programa de bônus do streamer**
  - Aceite: bônus por tempo de live e metas (RN-52) visíveis para o host; crédito via ledger.

## PK · Batalhas

- [ ] **PK01 Configurações de PK**
  - Aceite: modo preferido (1x1, 4 participantes, times) e duração escolhida da lista configurável (RN-56); aceitar convites aleatórios; aceitar só de quem sigo.
- [ ] **PK02 Convidar para PK**
  - Aceite: lista de hosts ao vivo disponíveis com busca; convite direto ou "PK aleatória" (pareamento pelo servidor).
- [ ] **PK03 Convite enviado**
  - Aceite: aguardando com contagem regressiva (RN-55); cancelar.
- [ ] **PK04 Convite recebido**
  - Aceite: aceitar/recusar; expira; não interrompe o vídeo.
- [ ] **PK05 Conectando**
  - Aceite: estado de conexão; falha devolve os dois à live normal com aviso.
- [ ] **PK06 Tela de PK 1x1**
  - Aceite: tela dividida; barra de placar em tempo real (só presentes confirmados no ledger, RN-56); cronômetro; top 3 doadores de cada lado; espectadores enviam presentes para qualquer lado; áudio do outro lado ajustável.
- [ ] **PK07 PK em times / até 4 participantes**
  - Aceite: 2x2 ou todos contra todos (modos do servidor); placar por time.
- [ ] **PK08 Resultado**
  - Aceite: vencedor/empate, placar, MVP doador de cada lado; tempo de "castigo/brincadeira" opcional do perdedor; volta para live normal.
- [ ] **PK09 Espectadores dos dois lados**
  - Aceite: espectadores de cada live veem a batalha completa; seguir o outro host com um toque.
- [ ] **PK10 Fim antecipado e queda**
  - Aceite: um host sai ou cai → o outro vence por desistência após RN-57; placar mantido; ninguém perde presentes enviados.

## CHA · Chamadas privadas

- [ ] **CHA01 Configurar chamadas (streamer)**
  - Aceite: aceitar chamadas de voz/vídeo; presente cobrado por minuto em cada uma vindo do menu de cobrança (PRE12, RN-53); disponibilidade (online/horários); só de quem segue opcional.
- [ ] **CHA02 Iniciar chamada**
  - Aceite: prévia com o presente cobrado por minuto e seu valor em moedas, saldo e estimativa de minutos; consentimento explícito; sem saldo leva a PRE10/ECO02.
- [ ] **CHA03 Chamada recebida**
  - Aceite: tela cheia com app aberto e notificação com app fechado; aceitar/recusar; expira.
- [ ] **CHA04 Conectando**
  - Aceite: estados chamando/conectando/falha/ocupado/sem resposta.
- [ ] **CHA05 Chamada em andamento**
  - Aceite: vídeo/voz; tempo e custo acumulado visíveis; enviar presente; câmera e microfone; trocar câmera; aviso antes do saldo acabar.
- [ ] **CHA06 Cobrança e reembolso** 🚩`paid_per_minute`
  - Aceite: presente do menu de cobrança enviado automaticamente a cada minuto pelo servidor; reembolso automático se a chamada terminar nos primeiros 10 s (RN-50, configurável); registros no ledger.
- [ ] **CHA07 Fim da chamada**
  - Aceite: resumo (duração, custo/ganho); avaliar; seguir.
- [ ] **CHA08 Denunciar chamada**
  - Aceite: durante e depois; motivo; encerra a chamada se o usuário quiser.
- [ ] **CHA09 Chamada gratuita**
  - Aceite: entre seguidores mútuos quando ativo; limite diário (RN-54).
- [ ] **CHA10 Não perturbe**
  - Aceite: silenciar chamadas recebidas por período.
- [ ] **CHA11 Tutorial de chamada (demonstração)**
  - Aceite: tela de demonstração **rotulada como tutorial**, sem cobrança, explicando preço, consentimento e reembolso. Nunca se apresenta como chamada real (ADR 0006).

## MSG · Mensagens

- [ ] **MSG01 Caixa de entrada**
  - Aceite: abas (Amigos, Outros, Sistema, Suporte); não lidas; fixadas no topo; busca; online.
- [ ] **MSG02 Conversa 1:1**
  - Aceite: texto, foto, vídeo, áudio, presente, perfil e live compartilhados; status enviado/entregue/visto; digitando; paginação para trás; reenvio em falha.
- [ ] **MSG03 Custo para iniciar conversa**
  - Aceite: quando ligado pelo comprador (desligado por padrão), aviso de custo (padrão 10 moedas, RN-58) antes da primeira mensagem para quem não segue de volta.
- [ ] **MSG04 Mídia paga (álbum premium)**
  - Aceite: criador envia foto/vídeo bloqueado com preço; prévia borrada; desbloqueio com moedas via ledger; conteúdo passa por moderação.
- [ ] **MSG05 Mensagem de boas-vindas**
  - Aceite: streamer define mensagem automática para novos seguidores.
- [ ] **MSG06 Mensagens automáticas**
  - Aceite: modelos com limite diário e anti-spam (RN-59); sempre identificadas como automáticas para quem recebe.
- [ ] **MSG07 Gerenciar conversas**
  - Aceite: fixar (limite RN-59), silenciar, apagar, marcar como lida/não lida.
- [ ] **MSG08 Bloquear e denunciar na conversa**
  - Aceite: bloqueio impede mensagens e chamadas; denúncia anexa as últimas mensagens.
- [ ] **MSG09 Mídia: visualizar, cortar, enviar**
  - Aceite: galeria e câmera; corte; compressão; progresso de upload e falha com repetir.
- [ ] **MSG10 Chat de família**
  - Aceite: conversa em grupo da família; mensagem fixada; permissão de "só líderes postam".
- [ ] **MSG11 Presença e leitura**
  - Aceite: online/visto por último respeitando privacidade (VIP07).
- [ ] **MSG12 Envio para vários**
  - Aceite: criador envia uma mídia/mensagem para vários contatos com limite (RN-59) e opção do destinatário de bloquear.

## FEED · Feed de posts

- [ ] **FEED01 Feed**
  - Aceite: posts de quem sigo e descobrir; paginação; pré-carregamento de mídia.
- [ ] **FEED02 Criar post**
  - Aceite: texto, até N fotos ou um vídeo; upload com progresso; falha/cancelamento tratados; visibilidade (todos, seguidores, assinantes).
- [ ] **FEED03 Detalhe do post**
- [ ] **FEED04 Curtir e comentar**
  - Aceite: curtir, lista de quem curtiu, comentários com respostas, apagar o próprio.
- [ ] **FEED05 Post para assinantes**
  - Aceite: bloqueado para quem não assina (SUB02) com chamada para assinar.
- [ ] **FEED06 Denunciar e apagar post**

## PER · Perfil

- [ ] **PER01 Meu perfil**
  - Aceite: fotos, nome, @, ID, nível, selos, seguidores, seguindo, diamantes; atalhos para carteira, VIP, estatísticas, família, configurações.
- [ ] **PER02 Editar perfil**
  - Aceite: até N fotos com corte e moderação; nome; bio; gênero; região; troca de @ com intervalo mínimo (RN-05).
- [ ] **PER03 Perfil de outro usuário**
  - Aceite: seguir, mensagem, chamada (se disponível), assinar (SUB02), entrar na live se ao vivo, posts, presentes recebidos em destaque, bloquear, denunciar.
- [ ] **PER04 Seguidores e seguindo**
  - Aceite: listas paginadas; seguir de volta; ocultáveis por privacidade (VIP07).
- [ ] **PER05 Quem visitou meu perfil**
  - Aceite: lista com data; visitantes com privacidade VIP aparecem anônimos.
- [ ] **PER06 Nível e experiência**
  - Aceite: nível de 1 a 100 com a curva da RN-61; progresso e XP que falta; como ganhar experiência; recompensas por nível; aviso ao subir de nível.
- [ ] **PER07 Selos**
  - Aceite: selos conquistados com explicação.
- [ ] **PER08 Selo de verificado**
  - Aceite: solicitação e status; concedido pelo painel.
- [ ] **PER09 @ especial**
  - Aceite: @ curto/raro adquirido na loja VIP; regras de exclusividade.

## ECO · Economia

- [ ] **ECO01 Carteira**
  - Aceite: saldo de moedas e de diamantes (normais e bônus, separados) atualizado em tempo real; atalhos comprar, sacar (abre o portal, ECO08), extrato. Taxas e conversões não aparecem no app.
- [ ] **ECO02 Loja de moedas (Google Play)**
  - Aceite: pacotes do servidor com etiquetas (primeira compra, super, mega…) e bônus crescente, editáveis pelo comprador; compra pela Google Play e, quando o comprador configurar, pelo provedor alternativo de pagamento (escolha do usuário, Q-37); crédito só após validação no servidor (RN-20); compra pendente e falha tratadas; restauração de compras não consumidas.
- [-] **ECO03 Recarga web via Pix** — movida para o portal web (POR04), decisão do usuário 2026-11-20.
- [ ] **ECO04 Ofertas especiais**
  - Aceite: desconto de primeira compra e pacotes especiais empurrados pelo servidor, com tempo limite e regra de elegibilidade.
- [ ] **ECO05 Moedas grátis periódicas**
  - Aceite: resgate a cada período; algumas exigem telefone verificado; moedas grátis marcadas como tal (RN-30): presentes pagos com elas geram diamantes bônus.
- [ ] **ECO06 Extrato**
  - Aceite: compras, presentes enviados/recebidos, desbloqueios, chamadas, reembolsos, saques, bônus; filtros por tipo e período; cada linha com ID para suporte.
- [ ] **ECO07 Reembolsos**
  - Aceite: automáticos (expulsão, live/chamada encerrada cedo) e manuais (pelo painel) visíveis no extrato com motivo; estorno da loja (chargeback) desconta saldo e pode bloquear a conta (RN-24).
- [ ] **ECO08 Atalho para saque**
  - Aceite: botão "Sacar" na carteira abre o portal web já autenticado (POR01) na página de saque (POR02); o app não mostra conversão nem taxas.
- [-] **ECO09 Dados de recebimento** — movidos para o portal web (POR03), decisão do usuário 2026-11-20.
- [ ] **ECO10 Revenda de moedas** 🚩`coin_reseller` (desligada por padrão)
  - Aceite: revendedor aprovado transfere moedas do próprio saldo para um ID; confirmação dupla; limites; tudo no ledger e visível no painel.
- [ ] **ECO11 Indicação** 🚩`referrals`
  - Aceite: link/código de convite; lista de indicados; comissão exibida (RN-27) e creditada via ledger.
- [ ] **ECO12 Avisos de ganhos**
  - Aceite: aviso quando ganhos podem ser retidos/reduzidos (ex.: suspeita de fraude, denúncias) com explicação e contato.

## VIP · VIP, loja e itens

- [ ] **VIP01 Meu VIP**
  - Aceite: nível atual (bronze, prata, ouro, platina, diamante, desafiante) calculado pelas moedas gastas nos últimos 7 dias (RN-70); progresso e quanto falta para o próximo; quanto precisa manter para não cair; benefícios de cada nível comparados; aviso antes de cair de nível.
- [-] **VIP02 Assinar VIP** — removido: VIP é conquistado por gasto, não comprado (decisão do usuário 2026-11-20).
- [ ] **VIP03 Privilégios**
  - Aceite: lista e detalhe de cada privilégio com como funciona.
- [ ] **VIP04 Recompensas VIP**
  - Aceite: recompensas diárias/mensais resgatáveis.
- [ ] **VIP05 Loja VIP**
  - Aceite: efeitos de entrada, molduras de avatar, balões de chat, destaque de perfil na Descobrir, @ especial; prévia do item; compra com moedas; presentear para outro usuário.
- [ ] **VIP06 Bolsa de itens**
  - Aceite: ativos, expirados; equipar/desequipar; validade; itens recebidos de presente.
- [ ] **VIP07 Privacidade VIP**
  - Aceite: ocultar online, localização, visitas, diamantes, moedas enviadas, seguidores/seguindo.
- [ ] **VIP08 VIP intocável**
  - Aceite: regras de RN-73 aplicadas no servidor e explicadas ao usuário; nunca impede moderação da plataforma.

## SUB · Assinatura de criador

- [ ] **SUB01 Central do criador**
  - Aceite: ligar assinatura; preço mensal em reais dentro dos limites da RN-62; benefícios; desconto do primeiro mês; lista de assinantes; ganhos (repasse conforme Q-38).
- [ ] **SUB02 Assinar criador**
  - Aceite: no perfil; preço em reais e benefícios; botão abre o checkout web (POR05); confirmação chega por evento; selo de assinante.
- [ ] **SUB03 Gerenciar assinaturas**
  - Aceite: minhas assinaturas, próxima cobrança, cancelar (pelo portal, POR05) com pesquisa.
- [ ] **SUB04 Conteúdo exclusivo**
  - Aceite: posts, mídia e lives só para assinantes quando o criador escolher.

## FAM · Famílias

- [ ] **FAM01 Criar família**
  - Aceite: requisitos de nível mínimo e custo em moedas e limite de membros, configurados pelo comprador (RN-63); nome, emblema, descrição; nome único e moderado.
- [ ] **FAM02 Perfil da família**
  - Aceite: membros, cargos, ranking, nível da família, entrar/sair.
- [ ] **FAM03 Convites e pedidos**
  - Aceite: convidar, pedir para entrar, aprovar/recusar; limite de membros.
- [ ] **FAM04 Gestão**
  - Aceite: promover gerentes, expulsar, silenciar no chat, transferir liderança com confirmação, dissolver.
- [ ] **FAM05 Ranking de famílias**
- [ ] **FAM06 Chat da família**
  - Aceite: ver MSG10.

## AGE · Agências 🚩`agencies`

- [ ] **AGE01 Página da agência**
  - Aceite: streamers vinculados, desempenho e ganhos agregados, comissão.
- [ ] **AGE02 Convidar streamer**
  - Aceite: convite com termos da comissão visíveis; streamer aceita ou recusa.
- [ ] **AGE03 Comissão e relatório**
  - Aceite: percentual (RN-28); relatório por período; crédito via ledger.
- [ ] **AGE04 Sair ou trocar de agência**
  - Aceite: regras de carência (RN-28); aviso das consequências.

## EST · Estatísticas do streamer

- [ ] **EST01 Painel de desempenho** (resumo de lives, horas, diamantes, seguidores)
- [ ] **EST02 Ganhos** (por dia/semana/mês, por origem: presentes, chamadas, privadas, assinaturas, bônus)
- [ ] **EST03 Duração das lives**
- [ ] **EST04 Espectadores** (pico, médio, únicos)
- [ ] **EST05 Seguidores** (ganhos e perdas)
- [ ] **EST06 Histórico de saques** (gráfico e lista)

## CFG · Configurações e suporte

- [ ] **CFG01 Configurações** (hub)
- [ ] **CFG02 Conta**
  - Aceite: telefone, e-mail, senha, métodos vinculados, sessões ativas, sair de todos, excluir conta (CFG12).
- [ ] **CFG03 Privacidade**
  - Aceite: quem pode mandar mensagem e ligar; ocultar seguidores; opções VIP (VIP07).
- [ ] **CFG04 Notificações**
  - Aceite: por tipo (lives de quem sigo, mensagens, chamadas, promoções); horário silencioso.
- [ ] **CFG05 Bloqueados** (lista e desbloquear)
- [ ] **CFG06 Meus moderadores** (moderadores permanentes das minhas lives)
- [ ] **CFG07 Conteúdo sensível**
  - Aceite: borrar mídia sinalizada como sensível (ligado por padrão).
- [ ] **CFG08 Tema** (claro, escuro, sistema)
- [ ] **CFG09 Sobre e textos legais** (termos, privacidade, diretrizes, licenças, versão)
- [ ] **CFG10 Suporte**
  - Aceite: perguntas frequentes; abrir chamado com categoria e anexos; conversa com o suporte na aba Suporte de MSG01; avaliar atendimento.
- [ ] **CFG11 Avaliar o app** (pedido de avaliação na loja em momento adequado, com limite)
- [ ] **CFG12 LGPD: exportar e excluir**
  - Aceite: pedir cópia dos dados (entregue por e-mail/arquivo); excluir conta com confirmação, carência (RN-80) e aviso do que é mantido por obrigação legal (ex.: registros financeiros).
- [ ] **CFG13 Permissões negadas**
  - Aceite: explicação antes de pedir; se negada para sempre, atalho para as configurações do Android.
- [ ] **CFG14 Idioma**
  - Aceite: português (padrão) ou inglês; segue o idioma do aparelho na primeira vez; troca sem reiniciar o app.

## SEG · Segurança, moderação e proteção

- [ ] **SEG01 Denúncias**
  - Aceite: motivos configuráveis por tipo (live, usuário, mensagem, chamada, post, família), cobrindo as diretrizes da RN-83 (nudez, violência, discurso de ódio, transmitir dirigindo, menor de idade); "menor de idade" e "exploração" com prioridade máxima e alerta imediato à moderação; anexos automáticos (trecho do chat, captura do frame quando possível).
- [ ] **SEG02 Moderação em tempo real**
  - Aceite: fila no painel; ações refletem no app na hora (encerrar live, banir, silenciar).
- [ ] **SEG03 Sanções**
  - Aceite: aviso, silenciamento, suspensão temporária, banimento, congelamento de saldo; tela explicando a sanção e prazo; pedido de revisão (apelação).
- [ ] **SEG04 Filtros de texto**
  - Aceite: palavras e links bloqueados globais (painel) e por host; aplicados no servidor.
- [ ] **SEG05 Antifraude**
  - Aceite: limites de envio/compra/saque; contas múltiplas no mesmo dispositivo (RN-31); estorno bloqueia; padrões suspeitos geram alerta no painel.
- [ ] **SEG06 Anti-bot no login**
  - Aceite: integridade do app (App Check), reCAPTCHA Enterprise e Turnstile, cada um ligado por flag (RN-85); o servidor decide quando exigir o desafio.
- [ ] **SEG07 Proteção de menores (ECA Digital)**
  - Aceite: verificação de idade confiável (ENT09), bloqueio de menores (ENT10), denúncia prioritária, preservação de evidências e fluxo de comunicação às autoridades definido com o jurídico do cliente.
- [ ] **SEG08 Auditoria**
  - Aceite: toda ação administrativa e financeira registrada com quem, quando, o quê e antes/depois.

## ADM · Painel administrativo (web)

- [ ] **ADM01 Login com 2FA e papéis**
- [ ] **ADM02 Dashboard** (lives agora, usuários ativos, receita em moedas e reais, saques pendentes, denúncias abertas)
- [ ] **ADM03 Usuários** (busca, detalhe, histórico, sanções, ajuste de saldo com motivo via ledger, verificação, selo)
- [ ] **ADM04 Lives ao vivo** (ver, entrar como moderador invisível, avisar, encerrar)
- [ ] **ADM05 Denúncias** (fila priorizada, evidências, ações, histórico)
- [ ] **ADM06 Presentes** (criar, editar, preço, diamantes, animação, categorias, ativar, exclusividade)
- [ ] **ADM07 Pacotes de moedas e ofertas** (IDs da Play, preços, etiquetas, ofertas e elegibilidade)
- [ ] **ADM08 Saques** (fila, verificação, aprovar, recusar com motivo, marcar como pago, exportar)
- [ ] **ADM09 VIP e loja** (limiares dos níveis VIP, benefícios por nível, itens da loja e preços em moedas)
- [ ] **ADM10 Famílias e agências** (aprovar, comissões, relatórios)
- [ ] **ADM11 Revendedores** (aprovar, limites, transferências)
- [ ] **ADM12 Comunicação** (banners, push segmentado, avisos dentro do app)
- [ ] **ADM13 Economia** (taxas por origem, conversão diamante → real, saque mínimo, taxa fixa, retenção, regras de diamantes bônus e moedas grátis, ordem de gasto, limites, bônus, custo de iniciar conversa, presentes elegíveis para cobrança por minuto, janela de reembolso)
- [ ] **ADM14 Configurações gerais** (flags com aviso jurídico, regiões, filtros de texto, motivos de denúncia, textos legais, versão mínima)
- [ ] **ADM15 Equipe e papéis**
- [ ] **ADM16 Suporte** (chamados, conversas, respostas prontas)
- [ ] **ADM17 Relatórios financeiros** (receita, saques, reembolsos, estornos; CSV)
- [ ] **ADM18 Logs de auditoria**
- [ ] **ADM19 Integrações e provedores**
  - Aceite: o comprador escolhe e configura sozinho cada provedor (pagamento na loja alternativa, Pix/checkout web, repasse/saque, SMS/WhatsApp, verificação de idade com liga/desliga, tradução, moderação de mídia, anti-bot, push, analytics); credenciais gravadas criptografadas no servidor e nunca exibidas de volta por inteiro; botão "testar conexão"; histórico de alterações na auditoria (ADR 0007).
- [ ] **ADM20 Progressão**
  - Aceite: curva de XP (constante, expoente, pesos de cada origem), recompensas por nível, requisitos e limites de famílias, programa de bônus do streamer.
- [ ] **ADM21 Diretrizes e detecção**
  - Aceite: texto das diretrizes (com versão), tempos e ações da detecção de presença (RN-48), sensibilidade da detecção de conteúdo, motivos de denúncia.

## POR · Portal web do usuário (`apps/portal`, ADR 0008)

- [ ] **POR01 Acesso ao portal a partir do app**
  - Aceite: o app pede ao servidor um link de uso único e curta duração (POR) e abre no navegador; o portal autentica com ele sem pedir senha; link expirado ou reutilizado é recusado; sessão do portal curta; também é possível entrar no portal com login normal.
- [ ] **POR02 Saque**
  - Aceite: saldo de diamantes normais e bônus; quanto é sacável (RN-25, RN-30); simulação com conversão, taxa e valor líquido; mínimo; exige verificação forte de idade e POR03 completo; confirmação; status pendente/em análise/aprovado/pago/recusado com motivo; histórico.
- [ ] **POR03 Dados de recebimento**
  - Aceite: nome completo, CPF validado e chave Pix do tipo CPF do mesmo titular (RN-82); alteração exige reautenticação e gera aviso no app; dados mascarados depois de salvos.
- [ ] **POR04 Recarga de moedas na web**
  - Aceite: pacotes do servidor; pagamento pelo provedor configurado pelo comprador (Pix com QR Code e copia-e-cola, cartão, conforme provedor); crédito só após confirmação; aparece no extrato do app.
- [ ] **POR05 Checkout de assinatura de criador**
  - Aceite: preço em reais, benefícios, pagamento recorrente pelo provedor configurado; confirmação volta ao app por evento; gerenciar e cancelar assinatura.
- [ ] **POR06 Ganhos e comprovantes**
  - Aceite: extrato de diamantes e saques com comprovantes para o streamer; exportação.
- [ ] **POR07 Base do portal**
  - Aceite: marca e cores do tenant; pt-BR e inglês; responsivo para celular; acessível; mesmas regras de segurança do painel.

## TRV · Transversais técnicos

- [x] **TRV01 Cliente de tempo real** (envelope versionado, reconexão exponencial, heartbeat, re-entrada em salas, ignorar tipos desconhecidos)
- [~] **TRV02 Camada de vídeo** (`VideoProvider` com fake completo; Agora na Fase 12)
- [~] **TRV03 Camada de dados** (repositórios por feature, erros padronizados, paginação por cursor, idempotência)
- [x] **TRV04 Config remota e flags** (lidas no início e atualizadas por evento)
- [ ] **TRV05 Push** (tipos, deep link, permissão no Android 13+)
- [ ] **TRV06 Analytics e crash** (eventos do funil: cadastro, primeira live assistida, primeira compra, primeiro presente, primeira live transmitida)
- [x] **TRV07 Internacionalização** (pt-BR e inglês completos; layout preparado para RTL; nenhum texto fixo no código)
- [~] **TRV08 White-label** (tenant por configuração; script de novo cliente)
- [~] **TRV09 Erros e conexão** (mensagens amigáveis, offline, tentar de novo, versão mínima)
- [ ] **TRV10 Acessibilidade** (leitor de tela, fonte grande, contraste, reduzir animações)
- [ ] **TRV11 Desempenho** (rolagem suave, inicialização rápida, consumo de dados e bateria, tamanho do APK)
- [ ] **TRV12 Logs e diagnóstico** (logs sem dados pessoais, envio de diagnóstico pelo suporte)
- [~] **TRV13 Conectores de provedores** (no servidor: interface por tipo de provedor, implementação fake no mock-server, registro de conectores configuráveis pelo ADM19; o app nunca fala direto com provedores que exigem segredo)
- [ ] **TRV14 Detecção no aparelho** (`DetectionProvider` para rosto/corpo e conteúdo durante a live; fake no início; modelo no aparelho na Fase 12)
