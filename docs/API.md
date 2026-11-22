# API.md — Contrato REST

> Contrato único usado pelo app, pelo painel, pelo mock-server e (depois) pelo backend real.
> **Regra:** endpoint novo ou alterado é escrito aqui **antes** de ser implementado, com status. Mudança que quebra compatibilidade exige ADR.
> Status: `proposto` · `no mock` · `no backend`. Detalhes de request/response são preenchidos quando o endpoint é implementado pela primeira vez (seção "Detalhes").

## Convenções
- Base: `{apiBaseUrl}/v1`. JSON UTF-8. Campos em `camelCase` no JSON.
- **Autenticação:** `Authorization: Bearer <accessToken>` (15 min, configurável de 5 a 60); `POST /v1/auth/refresh` com refresh token rotativo. Modelo completo na ADR 0012. Access vencido → `401 token_expirado`; sessão revogada → `401 sessao_substituida | sessao_revogada | sessao_expirada`; conta bloqueada → `403 conta_suspensa | conta_banida | menor_de_idade` (esta com `details.protocol`). Token com assinatura inválida ou sessão desconhecida → `401 nao_autenticado`. Aparelho sem segredo certo em login/refresh → `401 dispositivo_invalido`. A sessão é checada **antes** da validade do access: access vencido de sessão revogada responde `sessao_*`, não `token_expirado`.
- **Termos pendentes:** com aceite pendente, rotas autenticadas (exceto `GET /me`, `POST /me/terms/accept`, `POST /auth/logout`; o cadastro inicial e dados pessoais só depois do aceite, LGPD) respondem `403 termos_pendentes`.
- **Anti-bot (RN-85, SEG06):** headers `X-Antibot-Provider` (`appcheck`, `recaptcha`, `turnstile`) e `X-Antibot-Token`. Quando o servidor exige e falta/é inválido → `428 desafio_necessario` com `details.providers`. Vale em `POST /devices`, `/auth/code/send`, `/auth/email/signup`, `/auth/email/login`, `/auth/password/reset`. Token de uso único por rota. O servidor só exige com algum provedor ligado por flag (`antibotAppCheck`, `antibotRecaptcha`, `antibotTurnstile`) e quando avalia risco (no mock: cenário `exigir-desafio`, que liga o App Check); `details.providers` lista os provedores ligados. Ordem: anti-bot, depois limite por IP e demais validações. `/auth/code/verify`, `/auth/google` e `/auth/refresh` não têm anti-bot. No mock: token válido = `fake-ok-<8 a 64 caracteres [A-Za-z0-9_-]>`.
- **Idempotência:** toda operação que mexe em valor ou cria recurso aceita `Idempotency-Key: <uuid>` e devolve o mesmo resultado se repetida.
- **Paginação:** por cursor: `?cursor=...&limit=20` → `{ "items": [...], "nextCursor": "..." | null }`.
- **Erros:** status HTTP adequado + corpo:
  ```json
  { "error": { "code": "saldo_insuficiente", "message": "Texto seguro para o usuário", "details": { }, "requestId": "..." } }
  ```
  Códigos de erro são estáveis e listados em "Catálogo de erros". O app traduz por `code`, nunca por `message`.
- **Datas:** ISO-8601 UTC. **Dinheiro:** inteiros (moedas, diamantes, centavos).
- **Idioma:** header `Accept-Language` (`pt-BR` ou `en`); textos vindos do servidor (nomes de presentes, motivos, banners) respeitam o idioma.
- **Sessão única:** login em um novo aparelho revoga a sessão anterior (RN-06); requisições do aparelho antigo recebem `401` com `code: sessao_substituida`.
- **Versão do app:** header `X-App-Version` (semver `x.y.z`); resposta `426` com `code: atualizacao_obrigatoria` quando abaixo da mínima.
- **Manutenção:** resposta `503` com `code: manutencao` e `Retry-After` (segundos) enquanto a manutenção estiver ativa.
- **Região (ENT18):** fora dos países permitidos (`ConfigApp.regioes_permitidas`), toda rota `/v1/*` responde `403` com `code: regiao_bloqueada` e `details.country`. O país é detectado pelo servidor (nunca informado pelo app).
- **Exceções:** `GET /config` e o upgrade de `/v1/realtime` nunca respondem `426`, `503` nem `403 regiao_bloqueada` (o app precisa ler a config para mostrar as telas de atualização e manutenção); rotas `/__mock/*` também não. Sem header `X-App-Version` o `426` não é aplicado. Detalhe do `426`: `details.minAppVersion`. `Retry-After` padrão: 60 s.
- **Rate limit:** `429` com `Retry-After`.
- **Admin:** rotas `/v1/admin/*` exigem token de admin com papel; toda escrita gera `LogAuditoria`.
- **Mock-only:** rotas `/__mock/*` existem apenas no mock-server.
- **CORS (mock):** liberado só para origens `http://localhost:*` e `http://127.0.0.1:*` (app web de teste, painel e portal em dev). Headers aceitos: Content-Type, Authorization, Accept-Language, X-App-Version, Idempotency-Key, X-Mock-Country (só mock), X-Antibot-Provider, X-Antibot-Token; métodos GET, POST, PUT, PATCH, DELETE, OPTIONS; preflight `204` com `Max-Age: 600`; exposto: Retry-After.

## Catálogo de erros (inicial)
`nao_autenticado`, `token_expirado`, `sessao_substituida`, `verificacao_idade_necessaria`, `sem_permissao`, `nao_encontrado`, `validacao`, `conflito`, `limite_excedido`, `saldo_insuficiente`, `idade_nao_verificada`, `menor_de_idade`, `conta_suspensa`, `conta_banida`, `regiao_bloqueada`, `atualizacao_obrigatoria`, `manutencao`, `codigo_invalido`, `codigo_expirado`, `username_indisponivel`, `live_encerrada`, `expulso_da_live`, `silenciado`, `convite_expirado`, `funcionalidade_desligada`, `pagamento_pendente`, `pagamento_falhou`, `saque_abaixo_minimo`, `dados_recebimento_incompletos`, `credenciais_invalidas`, `email_nao_confirmado`, `desafio_necessario`, `sessao_revogada`, `sessao_expirada`, `termos_pendentes`, `dispositivo_invalido`, `cadastro_pendente`, `erro_interno`.

Detalhes por código: `menor_de_idade` → `{ protocol }`; `username_indisponivel` → `{ reason: ocupado|reservado }`; `conflito` → `{ reason: data_imutavel|ja_definido }` ou `{ currentVersion }` (termos); `validacao` → `{ field, reason?, rules? }`.

## Endpoints

### Sistema e configuração
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET | /config | Config pública do app (flags, versão mínima, abas, limites, textos legais) | ENT01, TRV04 | no mock |
| POST | /devices | Registrar/atualizar dispositivo e token de push | ENT01, TRV05 | no mock |

### Autenticação e conta
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| POST | /auth/code/send | Enviar código (telefone/e-mail; canal sms/whatsapp/email) | ENT04, ENT05, ENT07 | no mock |
| POST | /auth/code/verify | Verificar código → tokens (cria a conta de telefone se não existir; confirma o cadastro por e-mail) | ENT04, ENT05 | no mock |
| POST | /auth/email/signup | Cadastro por e-mail e senha | ENT05 | no mock |
| POST | /auth/email/login | Login por e-mail e senha | ENT05 | no mock |
| POST | /auth/google | Login/cadastro com Google | ENT06 | no mock |
| POST | /auth/password/reset | Definir nova senha com código | ENT07 | no mock |
| POST | /auth/refresh | Renovar tokens | ENT19 | no mock |
| POST | /auth/logout | Sair (sessão atual ou todas) | CFG02 | no mock |
| GET | /me | Meu perfil completo e situação da conta | ENT01, PER01 | no mock |
| PATCH | /me | Editar perfil, preferências e privacidade | ENT08, PER02, CFG03, CFG04 | no mock (cadastro e idioma) |
| POST | /me/username | Definir/trocar @ | ENT11, PER02 | no mock (primeira definição) |
| GET | /usernames/{u}/availability | Disponibilidade de @ | ENT11 | no mock |
| GET | /me/login-methods · POST · DELETE /me/login-methods/{id} | Métodos vinculados | ENT15 | proposto |
| GET | /me/sessions · DELETE /me/sessions/{id} | Sessões ativas | ENT19, CFG02 | proposto |
| POST | /me/terms/accept | Aceitar versão de termo/política/regras | ENT16, TRA01 | no mock |
| POST | /me/age-verification | Iniciar verificação de idade | ENT09 | proposto |
| GET | /me/age-verification | Situação da verificação | ENT09 | proposto |
| POST | /me/interests | Salvar interesses | ENT12 | no mock |
| GET | /interests | Categorias de interesse (no idioma) | ENT12 | no mock |
| POST | /me/tutorials/{key}/seen | Marcar tutorial visto | NAV04 | proposto |
| POST | /me/export | Pedir exportação de dados (LGPD) | CFG12 | proposto |
| POST | /me/delete | Agendar exclusão de conta | CFG12 | proposto |
| POST | /me/delete/cancel | Cancelar exclusão | CFG12 | proposto |
| POST | /media/uploads | Pedir URL de upload (tipo, tamanho) | PER02, MSG09, FEED02 | proposto |
| POST | /media/{id}/complete | Confirmar upload (dispara moderação) | idem | proposto |

### Usuários e social
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET | /users/{id} | Perfil público | PER03, ASS07 | proposto |
| POST · DELETE | /users/{id}/follow | Seguir / deixar de seguir | ASS05, PER03 | proposto |
| GET | /users/{id}/followers · /following | Listas | PER04 | proposto |
| POST · DELETE | /users/{id}/block | Bloquear / desbloquear | MSG08, CFG05 | proposto |
| GET | /me/blocked | Bloqueados | CFG05 | proposto |
| GET | /me/visitors | Quem visitou | PER05 | proposto |
| GET | /search?q=&type= | Busca de usuários e lives | DES05 | proposto |
| GET | /rankings?type=&period=&country= | Rankings | DES07 | proposto |
| GET | /me/level · /me/badges | Nível, XP e selos | PER06, PER07 | proposto |
| POST | /me/verification-badge | Solicitar selo de verificado | PER08 | proposto |

### Descoberta e notificações
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET | /discover/tabs | Abas ativas | DES01 | proposto |
| GET | /discover/lives?tab=&country=&cursor= | Lista de lives | DES01–DES04 | proposto |
| GET | /discover/suggestions | Sugestões | DES06 | proposto |
| GET | /following/live | Quem sigo ao vivo | DES09 | proposto |
| GET | /banners?position= | Banners | NAV03 | proposto |
| GET | /notifications · POST /notifications/read | Central | DES08 | proposto |

### Live
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET | /lives/eligibility | Pré-requisitos para transmitir | TRA01 | proposto |
| POST | /lives | Criar/iniciar live (tipo, título, capa, preço) | TRA02 | proposto |
| GET | /lives/{id} | Estado completo da live | ASS01, TRA04 | proposto |
| PATCH | /lives/{id} | Editar título, tipo, meta | TRA09, ASS15, TRA14 | proposto |
| POST | /lives/{id}/end | Encerrar | TRA10 | proposto |
| POST | /lives/{id}/resume | Retomar após queda | TRA12 | proposto |
| GET | /lives/{id}/summary | Resumo pós-live | TRA11 | proposto |
| POST | /lives/{id}/join | Entrar como espectador (modo normal/sussurro/incógnito; aceita preço se privada) | ASS01, ASS12, ASS13, TRA14 | proposto |
| POST | /lives/{id}/leave | Sair | ASS01 | proposto |
| GET | /lives/{id}/viewers · /top-senders | Espectadores e top doadores | ASS06 | proposto |
| POST | /lives/{id}/chat | Enviar mensagem | ASS02 | proposto |
| POST | /lives/{id}/chat/{msgId}/translate | Traduzir | ASS03 | proposto |
| POST | /lives/{id}/likes | Enviar curtidas agrupadas | ASS04 | proposto |
| POST | /lives/{id}/share | Compartilhar | ASS08 | proposto |
| POST | /lives/{id}/stage/requests | Pedir palco / convidar | ASS09, TRA07 | proposto |
| POST | /lives/{id}/stage/requests/{reqId}/{accept|reject|cancel} | Responder pedido | TRA07 | proposto |
| DELETE | /lives/{id}/stage/{userId} | Remover do palco | TRA07 | proposto |
| PATCH | /lives/{id}/stage/{userId} | Mutar/posição | TRA07, TRA08 | proposto |
| POST | /lives/{id}/moderation/{mute|kick|unmute|unkick} | Moderação na live | TRA06 | proposto |
| POST · DELETE | /lives/{id}/moderators/{userId} | Moderadores da live | TRA06 | proposto |
| PUT | /lives/{id}/media-state | Microfone, câmera, pausa | TRA05 | proposto |
| POST | /lives/{id}/detections | Resultado da detecção no aparelho (rosto ausente / conteúdo proibido); servidor aplica RN-48 | TRA13 | proposto |
| POST | /lives/{id}/private-invites | Convidar para live privada | TRA15 | proposto |
| GET · PUT | /me/tip-menu | Menu de gorjetas | PRE09 | proposto |
| GET · PUT | /me/charge-menu | Menu de cobrança por minuto (presentes de voz, vídeo, live privada) | PRE12, CHA01, TRA14 | proposto |
| GET · PUT | /me/wheel | Roleta de pedidos | PRE08 | proposto |
| POST | /lives/{id}/wheel/spin | Girar roleta | PRE08 | proposto |
| POST | /lives/{id}/sticker-goal | Definir sticker com meta | PRE07 | proposto |
| GET | /video/token?liveId=&role= | Token do provedor de vídeo (backend real) | TRV02 | proposto |

### Presentes
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET | /gifts/catalog | Catálogo com versão (cache) | PRE01 | proposto |
| POST | /gifts/send | Enviar presente (contexto, destinatário, quantidade, combo) — idempotente | PRE01–PRE11, PK06, CHA05, MSG02 | proposto |
| POST | /tips/send | Pedir item do menu de gorjetas | PRE09 | proposto |

### PK
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET · PUT | /me/pk-settings | Preferências de PK | PK01 | proposto |
| GET | /pk/available-hosts | Hosts disponíveis | PK02 | proposto |
| POST | /pk/invites | Convidar (direto ou aleatório) | PK02 | proposto |
| POST | /pk/invites/{id}/{accept|reject|cancel} | Responder | PK03, PK04 | proposto |
| GET | /pk/{id} | Estado da PK | PK06 | proposto |
| POST | /pk/{id}/leave | Sair da PK | PK10 | proposto |

### Chamadas
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET · PUT | /me/call-settings | Configurar chamadas | CHA01, CHA10 | proposto |
| POST | /calls | Iniciar chamada (tipo, receptor, aceite do preço) | CHA02 | proposto |
| POST | /calls/{id}/{accept|reject|cancel|end} | Ações | CHA03–CHA07 | proposto |
| PUT | /calls/{id}/media-state | Câmera/microfone | CHA05 | proposto |
| GET | /calls/{id} | Estado e resumo | CHA05, CHA07 | proposto |

### Mensagens
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET | /conversations?tab= | Caixa de entrada | MSG01 | proposto |
| POST | /conversations | Abrir conversa com usuário (aceita custo) | MSG02, MSG03 | proposto |
| GET | /conversations/{id}/messages?cursor= | Mensagens | MSG02 | proposto |
| POST | /conversations/{id}/messages | Enviar (texto, mídia, mídia paga, compartilhamento) | MSG02, MSG04 | proposto |
| POST | /conversations/{id}/read | Marcar lida | MSG07 | proposto |
| PATCH | /conversations/{id} | Fixar, silenciar, apagar | MSG07 | proposto |
| POST | /messages/{id}/unlock | Desbloquear mídia paga | MSG04 | proposto |
| GET · PUT | /me/auto-messages | Boas-vindas e modelos | MSG05, MSG06 | proposto |
| POST | /messages/broadcast | Envio para vários (limitado) | MSG12 | proposto |

### Feed
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET | /feed?tab= | Feed | FEED01 | proposto |
| POST | /posts | Criar post | FEED02 | proposto |
| GET · DELETE | /posts/{id} | Detalhe / apagar | FEED03, FEED06 | proposto |
| POST · DELETE | /posts/{id}/like | Curtir | FEED04 | proposto |
| GET | /posts/{id}/likes | Quem curtiu | FEED04 | proposto |
| GET · POST | /posts/{id}/comments | Comentários | FEED04 | proposto |
| DELETE | /comments/{id} | Apagar comentário | FEED04 | proposto |

### Economia
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET | /wallet | Saldos | ECO01 | proposto |
| GET | /wallet/statement?type=&from=&to=&cursor= | Extrato | ECO06 | proposto |
| GET | /store/packages · /store/offers | Pacotes e ofertas | ECO02, ECO04, PRE10 | proposto |
| POST | /store/play/verify | Validar compra da Google Play e creditar | ECO02 | proposto |
| POST | /store/alternative/verify | Validar compra pelo provedor alternativo configurado | ECO02 | proposto |
| POST | /portal/links | Gerar link de uso único para o portal (`saque`, `dados_recebimento`, `recarga`, `assinatura`) | POR01, ECO08, SUB02 | proposto |
| POST | /portal/session | Trocar o link de uso único por sessão do portal | POR01 | proposto |
| POST | /store/web/charges | Criar cobrança de recarga no portal (Pix/cartão via provedor) | POR04 | proposto |
| GET | /store/web/charges/{id} | Situação da cobrança | POR04 | proposto |
| POST | /webhooks/payments/{provider} | Confirmação do provedor de pagamento (assinatura verificada) | POR04, POR05, ECO02 | proposto |
| POST | /rewards/claim | Resgatar moedas grátis/bônus | ECO05, ENT13, ENT14 | proposto |
| GET · PUT | /me/payout-details | Dados de recebimento (só no portal) | POR03 | proposto |
| GET | /payouts/quote?diamonds= | Simular saque (só no portal) | POR02 | proposto |
| POST · GET | /payouts | Solicitar / listar saques (só no portal) | POR02, POR06, EST06 | proposto |
| POST | /reseller/transfers | Revenda de moedas 🚩 | ECO10 | proposto |
| GET | /me/referrals | Indicações 🚩 | ECO11 | proposto |

### VIP, loja e assinaturas
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET | /vip/levels · /me/vip | Níveis VIP, benefícios e meu status (gasto em 7 dias, progresso) | VIP01, VIP03 | proposto |
| POST | /vip/rewards/claim | Resgatar recompensas | VIP04 | proposto |
| GET | /shop/items | Loja VIP | VIP05 | proposto |
| POST | /shop/purchase | Comprar item (para mim ou presente) | VIP05 | proposto |
| GET | /me/bag · POST /me/bag/{itemId}/equip | Bolsa de itens | VIP06 | proposto |
| GET · PUT | /me/creator-plan | Plano de assinatura do criador | SUB01 | proposto |
| POST | /creators/{id}/subscriptions/checkout | Iniciar checkout web (devolve link do portal) | SUB02, POR05 | proposto |
| POST | /me/subscriptions/{id}/cancel | Cancelar assinatura de criador | SUB03, POR05 | proposto |
| GET | /me/subscriptions · /me/subscribers | Minhas assinaturas / assinantes | SUB01, SUB03 | proposto |

### Famílias e agências
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| POST · GET | /families · /families/{id} | Criar / ver | FAM01, FAM02 | proposto |
| PATCH · DELETE | /families/{id} | Editar / dissolver | FAM04 | proposto |
| POST | /families/{id}/requests | Pedir para entrar / convidar | FAM03 | proposto |
| POST | /families/{id}/requests/{reqId}/{accept|reject} | Responder | FAM03 | proposto |
| PATCH · DELETE | /families/{id}/members/{userId} | Cargo, silenciar, expulsar, transferir | FAM04 | proposto |
| GET · POST | /agencies/{id} · /agencies/{id}/invites | Agência e convites 🚩 | AGE01, AGE02 | proposto |
| GET | /agencies/{id}/report | Relatório 🚩 | AGE03 | proposto |
| POST | /me/agency/leave | Sair da agência 🚩 | AGE04 | proposto |

### Estatísticas, suporte e denúncias
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| GET | /me/stats/{performance|earnings|duration|viewers|followers|payouts} | Estatísticas | EST01–EST06 | proposto |
| GET | /reports/reasons?target= | Motivos | SEG01 | proposto |
| POST | /reports | Denunciar | ASS11, CHA08, MSG08, FEED06 | proposto |
| GET | /me/sanctions · POST /me/sanctions/{id}/appeal | Sanções e apelação | SEG03 | proposto |
| GET | /support/faq | Perguntas frequentes | CFG10 | proposto |
| POST · GET | /support/tickets | Abrir / listar chamados | CFG10 | proposto |
| POST | /support/tickets/{id}/rating | Avaliar | CFG10 | proposto |

### Admin (`/v1/admin/*`)
| Método | Caminho | Descrição | Usado por | Status |
| --- | --- | --- | --- | --- |
| POST | /admin/auth/login · /admin/auth/2fa | Login e 2FA | ADM01 | proposto |
| GET | /admin/dashboard | Indicadores | ADM02 | proposto |
| GET · PATCH | /admin/users · /admin/users/{id} | Usuários | ADM03 | proposto |
| POST | /admin/users/{id}/sanctions · /balance-adjustments | Sanções e ajuste de saldo | ADM03 | proposto |
| GET · POST | /admin/lives · /admin/lives/{id}/{end|warn} | Lives | ADM04 | proposto |
| GET · PATCH | /admin/reports · /admin/reports/{id} | Denúncias | ADM05 | proposto |
| CRUD | /admin/gifts · /admin/gift-categories | Presentes | ADM06 | proposto |
| CRUD | /admin/packages · /admin/offers | Pacotes e ofertas | ADM07 | proposto |
| GET · POST | /admin/payouts · /admin/payouts/{id}/{approve|reject|mark-paid} | Saques | ADM08 | proposto |
| CRUD | /admin/shop-items | Loja VIP (itens em moedas) | ADM09 | proposto |
| CRUD | /admin/families · /admin/agencies · /admin/resellers | Comunidade e revenda | ADM10, ADM11 | proposto |
| CRUD | /admin/banners · POST /admin/push | Comunicação | ADM12 | proposto |
| GET · PUT | /admin/economy-config · /admin/app-config | Configurações | ADM13, ADM14 | proposto |
| CRUD | /admin/team | Equipe | ADM15 | proposto |
| GET · POST | /admin/support/tickets | Suporte | ADM16 | proposto |
| GET | /admin/reports/financial?from=&to=&format=csv | Financeiro | ADM17 | proposto |
| GET | /admin/audit-logs | Auditoria | ADM18 | proposto |
| GET · PUT | /admin/integrations · /admin/integrations/{type} | Provedores configuráveis (credenciais só de escrita) | ADM19 | proposto |
| POST | /admin/integrations/{type}/test | Testar conexão com o provedor | ADM19 | proposto |
| GET · PUT | /admin/progression-config | XP, níveis, famílias, bônus | ADM20 | proposto |
| GET · PUT | /admin/guidelines · /admin/detection-config | Diretrizes e detecção | ADM21 | proposto |
| CRUD | /admin/vip-levels | Limiares e benefícios VIP | ADM09 | proposto |

### Mock-only (`/__mock/*`)
| Método | Caminho | Descrição |
| --- | --- | --- |
| POST | /__mock/reset | Volta aos dados iniciais e desliga todos os cenários (no mock) |
| POST | /__mock/scenario/{nome} | Aplica cenário (ex.: `saldo-zero`, `pk-recebida`, `ban`, `live-encerrada-admin`, `pagamento-falha`, `rede-lenta`, `erro-500`). No mock: `erro-500`, `rede-lenta`, `manutencao`, `versao-minima`, `regiao-bloqueada`, `entrada-desligada`, `exigir-desafio`, `token-expira-rapido`, `termos-novos` |
| GET | /__mock/outbox?destination= | Último código enviado (`{ code }`); sem código → `404 nao_encontrado` (no mock) |
| GET | /__mock/ping-autenticado | Rota autenticada qualquer, para provar o bloqueio por `termos_pendentes` → `{ ok: true, at: <configVersion> }` (no mock) |
| POST | /__mock/minor/unfreeze | Libera conta congelada por menor (`{ userId }` → `204`; `404 nao_encontrado` se não estiver congelada). Zera aparelho e identificadores reservados (no mock) |
| POST | /__mock/emit | Emite um evento de tempo real do catálogo (para testes) (no mock) |
| POST | /__mock/bots/{start|stop} | Liga/desliga bots de chat e presentes (proposto, Fase 3) |

## Detalhes
> Preencher por endpoint quando for implementado: request, response, erros possíveis, regras aplicadas (RN), eventos emitidos, entidades do DATABASE.md tocadas.

### GET /v1/config — no mock (TRV04, ENT01)
- Auth: não exige (lida antes do login). Header `Accept-Language` escolhe o idioma dos textos.
- Nunca responde `426`/`503` (ver Convenções).
- Resposta `200`:
  ```json
  {
    "configVersion": 1,
    "minAppVersion": "0.1.0",
    "maintenance": { "active": false, "retryAfterSeconds": null },
    "flags": { "loginPhone": true, "loginSms": true, "loginWhatsapp": false, "loginEmail": true,
               "loginGoogle": true, "antibotAppCheck": false, "antibotRecaptcha": false,
               "antibotTurnstile": false, "pk": true, "groupLive": true,
               "paidPerMinute": false, "luckyGift": false, "coinReseller": false, "referrals": false,
               "agencies": false, "facePresence": true, "ageVerification": true },
    "limits": { "chatMaxLength": 200, "chatMessagesPerSecond": 1, "pkInviteTtlSeconds": 15,
                "stageInviteTtlSeconds": 15, "callInviteTtlSeconds": 30 },
    "discoverTabs": ["popular", "nearby", "new", "pk", "multi", "calls"],
    "legalTexts": { "terms": { "version": 1, "url": "…" }, "privacy": { "version": 1, "url": "…" },
                    "guidelines": { "version": 1, "url": "…" } },
    "allowedRegions": ["BR"],
    "region": { "country": "BR", "allowed": true }
  }
  ```
- `loginPhone` só liga o telefone com `loginSms` ou `loginWhatsapp` também ligada.
- `region` é **calculado por requisição** (país detectado pelo servidor × `allowedRegions`). Não faz parte do cache local nem do `config.updated`. Mock: país do header `X-Mock-Country` (só do mock; o app nunca envia), padrão `BR`; o cenário `regiao-bloqueada` força um país fora da lista.
- Regras: valores vêm de `ConfigApp` (editável pelo comprador, ADR 0007); `configVersion` cresce a cada alteração. Flag desconhecida pelo app é ignorada; flag ausente = desligada.
- Erros: `500 erro_interno`; `429` (rate limit) no backend real (o mock não limita).
- Eventos relacionados: `config.updated` (só para conexões autenticadas; sem login o app rebusca ao abrir e ao voltar do segundo plano, ADR 0011).
- Entidades: ConfigApp.

### POST /__mock/reset — no mock
- Corpo vazio. Recarrega fixtures, zera cenários, fecha conexões de tempo real (código `1001`). Apaga também aparelhos, sessões, códigos, falhas, avisos e aceites criados (as contas de `fixtures/auth.json` voltam); o app precisa registrar o aparelho de novo. `configVersion` continua crescendo (não volta a 1), para o app não ignorar a config nova. Resposta `204`.

### POST /__mock/scenario/{nome} — no mock
- Corpo opcional `{ "active": true|false }` (padrão `true`). Resposta `200 { "scenario": nome, "active": bool }`; nome desconhecido → `404 nao_encontrado`.
- Cenários da Fase 0:
  | nome | efeito |
  | --- | --- |
  | `erro-500` | toda rota `/v1/*` responde `500 erro_interno` |
  | `rede-lenta` | toda rota `/v1/*` atrasa 3 s |
  | `manutencao` | `ConfigApp.manutencao` ativa (`retryAfterSeconds: 300`): rotas `/v1/*` (exceto `/config`) → `503 manutencao`; `configVersion` sobe e `config.updated` é emitido |
  | `versao-minima` | `minAppVersion` = `99.0.0`: rotas `/v1/*` (exceto `/config`) com `X-App-Version` menor → `426`; `configVersion` sobe e `config.updated` é emitido |
  | `entrada-desligada` | flags `loginPhone`, `loginEmail` e `loginGoogle` desligadas; `configVersion` sobe e `config.updated` é emitido |
  | `exigir-desafio` | liga a flag `antibotAppCheck` (`config.updated`) e o servidor passa a exigir anti-bot em `/devices`, `/auth/code/send`, `/auth/email/signup`, `/auth/email/login`, `/auth/password/reset` (sem token válido → `428`) |
  | `token-expira-rapido` | access token vale 5 s; não altera `configVersion` |
  | `termos-novos` | `terms.version` passa a 2 (`privacy` continua 1); `configVersion` sobe e `config.updated` é emitido; ao desligar volta a 1 |
  | `regiao-bloqueada` | país detectado passa a ser `XX` (fora da lista): `/config` mostra `region.allowed = false` e as demais rotas `/v1/*` → `403 regiao_bloqueada` |

### POST /__mock/emit — no mock
- Corpo `{ "type": "...", "data": { }, "target": { "room": "live:123" } | { "userId": "u1" } | { "all": true } }`.
- `type` precisa existir no catálogo de `docs/EVENTOS-TEMPO-REAL.md` (servidor → cliente); senão `400 validacao`. Resposta `200 { "delivered": n }`.

### POST /v1/devices — no mock (ENT01, Fase 1b)
- Sem autenticação. Corpo (sem campos extras): `{ "deviceId"?: string, "deviceSecret"?: string (≤128), "platform": "android"|"ios"|"web", "appVersion": "x.y.z", "locale": "pt-BR"|"en", "model"?: string (≤80) }` (`web` só no build de teste).
- Criação `201 { deviceId, deviceSecret, blocked: false }` (o servidor gera os dois; guarda só o hash do segredo). Atualização `200 { deviceId, blocked }` só com `deviceId` + `deviceSecret` certos; id ausente, desconhecido, forjado ou segredo errado → cria outro aparelho (`201`), nunca adota o id enviado.
- Erros: `400 validacao`; `428 desafio_necessario` (anti-bot); `429 limite_excedido` + `Retry-After` (60 por IP por hora no mock).
- O login grava o usuário no aparelho (`Dispositivo.usuario_id`). Entidades: Dispositivo. Base da sessão única (RN-06).

### Autenticação (Fase 1b) — no mock
Todas as rotas de login recebem `deviceId` + `deviceSecret` (segredo errado → `401 dispositivo_invalido`) e respondem, quando entram, com:
```json
{ "accessToken": "...", "refreshToken": "...", "expiresIn": 900, "user": { "id": "u_...", "needsProfile": true } }
```
- **POST /auth/code/send** `{ channel: "sms"|"whatsapp"|"email", destination, purpose: "login"|"signup"|"reset" }` → `200 { expiresInSeconds, resendInSeconds }`. Mesma resposta exista ou não a conta/cadastro pendente. Limites RN-02 (configuráveis no servidor): 5 envios por destino por hora, reenvio só após `resendInSeconds` e 60 por IP por hora → `429 limite_excedido` + `Retry-After`. Canal desligado → `403 funcionalidade_desligada` (e-mail exige `loginEmail`; telefone exige `loginPhone` e `loginSms`/`loginWhatsapp`). Por e-mail só `signup` (depois de `/auth/email/signup`) e `reset` (conta confirmada) entregam código; `purpose: "login"` com e-mail → `400 validacao` (`field: purpose`), porque e-mail entra com senha; `reset` com telefone → `400 validacao`. Outros erros: `400 validacao` (`details.field`), `428 desafio_necessario`. Código novo invalida o anterior.
- **POST /auth/code/verify** `{ destination, code (6 dígitos), purpose: "login"|"signup", deviceId, deviceSecret, password? }` → tokens. Telefone sem conta cria a conta (`needsProfile: true`). `password` é **obrigatório no cadastro por e-mail** (a mesma senha de `/auth/email/signup`, contra sequestro de cadastro); senha errada → `400 codigo_invalido` e o código é consumido. Erros: `400 codigo_invalido` (conta tentativa; na 5ª o código morre), `400 codigo_expirado`, `401 dispositivo_invalido`, `403 conta_banida|conta_suspensa|menor_de_idade`, `429 limite_excedido` + `Retry-After` (5 falhas por destino+aparelho; 50 por IP).
- **POST /auth/email/signup** `{ email, password }` → `202 { expiresInSeconds, resendInSeconds }` (código enviado com `purpose: "signup"`; confirmar com `code/verify`). Senha fraca → `400 validacao` com `details.field = password` e `details.rules` ⊂ [`min_length`, `letters`, `numbers`, `common`]. Outros erros: `400 validacao` (`field: email`), `403 funcionalidade_desligada` (flag `loginEmail`), `428`, `429` (mesmas regras do `code/send`). E-mail com conta confirmada: mesma resposta `202`, e o mock registra o aviso `ja_tem_conta` (DATABASE.md AvisoConta; envio real na Fase 8) em vez de mandar código. Cadastro não confirmado não trava o e-mail (novo cadastro confirmado substitui).
- **POST /auth/email/login** `{ email, password, deviceId, deviceSecret }` → tokens. Erro único `401 credenciais_invalidas` (e-mail inexistente leva o mesmo tempo). Senha certa com e-mail não confirmado → `403 email_nao_confirmado`. Falhas por conta+aparelho (5, bloqueio de 60 s dobrando) e por IP (50) → `429 limite_excedido` + `Retry-After`, igual exista ou não a conta. Outros erros: `401 dispositivo_invalido`, `428`, `403 conta_banida|conta_suspensa|menor_de_idade`.
- **POST /auth/google** `{ idToken, deviceId, deviceSecret }` → tokens. Liga a conta de e-mail existente só com `email_verified`. **Só no mock:** `idToken = "mock-google:<email>"` (verificado) e `"mock-google:erro"` → `401 credenciais_invalidas`. Erros: `403 funcionalidade_desligada` (flag `loginGoogle`), `401 dispositivo_invalido`, `403 conta_banida|conta_suspensa|menor_de_idade`. Sem anti-bot e sem contagem de falhas (conector real na Fase 12).
- **POST /auth/password/reset** `{ email, code, newPassword }` → `204`; revoga todas as sessões da conta com motivo `senha_trocada` (RN-04); não zera o bloqueio por falhas de login. Código pedido antes com `code/send` `purpose: "reset"`. Erros: `400 validacao` (`field: newPassword`, `details.rules`), `400 codigo_invalido|codigo_expirado`, `428`, `429` (por e-mail+IP e por IP).
- **POST /auth/refresh** `{ refreshToken, deviceId, deviceSecret }` → tokens novos (rotativo). A tolerância de 10 s vale **uma única vez** por troca; o segundo uso do refresh anterior, ou o uso depois de 10 s, revoga a sessão (`reuso_refresh`) e gera aviso `sessao_revogada`. Erros: `401 dispositivo_invalido` (aparelho diferente do da sessão), `401 sessao_substituida|sessao_revogada|sessao_expirada` (conforme o motivo da revogação), `401 sessao_revogada` (token desconhecido), `401 sessao_expirada` (30 dias sem uso ou 180 desde o login), `403 conta_banida|conta_suspensa|menor_de_idade` (revoga com `conta_bloqueada`).
- **POST /auth/logout** `{ refreshToken? }` → sempre `204` (mesmo sem sessão correspondente). Não exige autenticação; aceita `Authorization: Bearer` mesmo vencido e/ou `refreshToken`; revoga a sessão e fecha o tempo real.
- **Limites de força bruta:** login por e-mail = conta+aparelho e IP; verify de código = destino+aparelho e IP; reset = e-mail+IP e IP. Limite 5 por chave de conta/destino (bloqueio de 60 s dobrando a cada falha extra) e 50 por IP (alto por causa de CGNAT). Bloqueado → `429 limite_excedido` + `Retry-After`, igual exista ou não a conta.
- **GET /me** → formato completo na seção "Cadastro inicial (plano 1c)" abaixo. `pendingTerms: [{ document, version, url }]` lista `terms`, `privacy` e `guidelines` ainda não aceitos na versão atual (os três obrigatórios, Q-55). Erros: `401 nao_autenticado|token_expirado|sessao_*`, `403 conta_banida|conta_suspensa|menor_de_idade`.
- **POST /me/terms/accept** `{ document: "terms"|"privacy"|"guidelines", version }` → `204`. Versão diferente da atual → `409 conflito` com `details.currentVersion`; aceitar de novo a mesma versão → `204`.
- **Logs:** o servidor nunca registra `password`, `newPassword`, `code`, `refreshToken`, `deviceSecret`, `idToken`, `destination`, `email`, `authorization` nem `X-Antibot-Token`.

### Cadastro inicial (plano 1c) — no mock
- **Portão de cadastro:** com `pendingSteps` contendo `profile`, rotas autenticadas (exceto `GET /me`, `PATCH /me`, `POST /me/terms/accept`, `GET /usernames/{u}/availability`, `POST /auth/logout`) → `403 cadastro_pendente`. `PATCH /me` e a consulta de @ exigem os termos aceitos (`termos_pendentes` vem antes de `cadastro_pendente`). Exigem nome e data: `POST /me/username`, `GET /interests`, `POST /me/interests` e as demais. O app, ao receber `termos_pendentes` ou `cadastro_pendente`, recarrega o `/me`.
- **GET /me** → `{ id, needsProfile, pendingSteps, accountStatus, ageStatus, displayName, username, gender, birthDateSet, language, pendingTerms }`. `ageStatus`: `nao_verificada`, `pendente`, `verificada`, `reprovada`, `menor_bloqueado`; `pendingSteps`: `profile`, `username`, `interests`. `gender` só aparece aqui (privado, Q-59); a data de nascimento nunca é devolvida, só `birthDateSet`. `needsProfile` = `pendingSteps` não vazio (compatível com a 1b). Liberado com termos e cadastro pendentes.
- **PATCH /me** `{ displayName?, birthDate? (AAAA-MM-DD), gender? ("mulher"|"homem"|"nao_binario"|"prefiro_nao_dizer"|null), language? ("pt-BR"|"en"), storeAgeSignal? { status: "shared"|"not_shared"|"verification_required"|"unavailable", ageLower?, ageUpper? } }` → `200` com o `/me`. Campos fora da lista são ignorados (nunca alteram nada; compatível com versões futuras do app). `birthDate` só uma vez (`409 conflito`, `details.reason = "data_imutavel"`), não futura, ≤ 120 anos. Nome: 2–30 caracteres depois de aparar (RN-05), senão `400 validacao` (`field: displayName`, `reason: tamanho`); com palavra bloqueada (sem acento, com dígitos trocados) `reason: proibido`. A idade só é avaliada quando chegam `birthDate` ou `storeAgeSignal` (trocar o idioma não reavalia) e nunca depois de a equipe liberar a conta. Idade < 18 (só datas, fuso do tenant) ou sinal compartilhado com `ageUpper < 18` ou `ageLower < 18` → `403 menor_de_idade` (`details.protocol`, ex.: `P-1A2B3C4D`, para a pessoa informar ao suporte; Q-68): conta congelada, sessões revogadas, aparelho marcado (a data e o sinal ficam gravados, o nome não). O sinal só restringe.
- **Conta congelada / aparelho marcado:** login, refresh, rotas autenticadas e `auth` do tempo real → `403 menor_de_idade` (WS: a conexão aberta recebe `session.invalid { reason: "conta_bloqueada" }` + `4001`; uma conexão nova é recusada com `4001`). `POST /devices`: criação `201 { deviceId, deviceSecret, blocked: false }`; atualização `200 { deviceId, blocked, protocol? }` (`blocked: true` + `protocol` para aparelho marcado). O app atualiza o aparelho a cada abertura. Todo `403 menor_de_idade` traz `details.protocol`. Aparelho marcado em login/cadastro → `403 menor_de_idade` antes de criar conta. Telefone, e-mail e Google da conta congelada ficam reservados (`IdentificadorBloqueado`).
- **GET /usernames/{u}/availability** (`u` com 1–40 caracteres, senão `400 validacao`; autenticada, termos aceitos, liberada antes do cadastro; 30 por conta/minuto e 600 por IP/hora → `429 limite_excedido`) → `{ available, reason?: "formato"|"ocupado"|"reservado", suggestions: string[] }`. Formato inválido responde `200` com `reason: "formato"`; o próprio @ da conta aparece como disponível. Sugestões: até 3, só disponíveis (base do nome, ou `usuario` se o nome tiver termo reservado).
- **POST /me/username** `{ username }` (minúsculas aplicadas pelo servidor) → `200 { username }` (o mesmo @ já definido é aceito); mesmos limites da consulta; quem já tem @ recebe sempre `409 conflito` (`ja_definido`) sem revelar se o outro está ocupado; `400 validacao` (formato); `409 username_indisponivel` (`details.reason`: `ocupado`, `reservado`); `409 conflito` (`ja_definido`: a troca é do PER02). Reservados: lista do comprador + id e nome do tenant, também com variações (`adm1n`, `liveapp.oficial`).
- **GET /interests** → `{ items: [{ id, name }] }` no idioma do `Accept-Language`; só categorias ativas (inativa também é recusada no POST). **POST /me/interests** `{ ids: string[] (0–10, existentes, sem repetição) }` → `204` (lista vazia = pulou).
- **Logs:** nunca registram `birthDate`, `gender`, `storeAgeSignal`, `ageLower`, `ageUpper`.
- Mock-only: `POST /__mock/minor/unfreeze { userId }` (a equipe libera depois da revisão; no real, pelo painel).

### Mock-only (Fase 1b)
- `GET /__mock/outbox?destination=...` → `{ code }` do último código enviado (para E2E). Nunca usado pelo app.
- Cenários: `exigir-desafio` (anti-bot exigido em todas as rotas da lista), `token-expira-rapido` (access de 5 s), `termos-novos` (termos passam para a versão 2: quem aceitou a 1 precisa aceitar de novo).

