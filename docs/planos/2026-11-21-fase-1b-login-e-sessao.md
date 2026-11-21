# Plano: Fase 1b — Login, senha, termos e sessão única

- Data: 2026-11-21 · Branch: `claude/funny-darwin-w671g8`
- Itens: **ENT04, ENT05, ENT06, ENT07, ENT16, ENT19** (módulo ENT) + **SEG06** (anti-bot no login; entra junto porque é parte do mesmo fluxo de login e do mesmo contrato).
- Fecha também o que ficou `[~]` na 1a por falta de login: ENT01 (restaurar sessão) e ENT17 (retomar a ação após entrar de verdade).
- Decisões usadas: Q-50 (sessão 30 dias sem uso, configurável), Q-51 (autopreenchimento do SMS na Fase 12), Q-52 (cadastro ENT08 na 1c), Q-53 (Google por contas de teste do mock), RN-02 (código), RN-03 (senha), RN-04 (troca de senha derruba sessões), RN-06/ADR 0009 (um aparelho por conta), RN-85 (anti-bot).
- Fora daqui: dados iniciais e idade (ENT08–ENT10, plano 1c), @ (ENT11), contas vinculadas (ENT15), Google e SMS reais (Fase 12).

## 1. Como cada critério será atendido
| Item | Critério | Como |
| --- | --- | --- |
| ENT04 | país (Brasil padrão), máscara | seletor com os países de `allowedRegions` (hoje só BR) e máscara `(11) 91234-5678` própria (sem pacote novo); envia E.164 |
| | código de 6 dígitos, 60 s, reenvio com contagem | `POST /auth/code/send` → `{ expiresInSeconds: 60, resendInSeconds: 60 }`; tela de código com 6 caixas e contagem regressiva; reenviar só depois de 60 s |
| | limite de tentativas | servidor: 5 envios/número/hora e 5 tentativas/código (RN-02) → `429 limite_excedido` / `codigo_invalido`; app mostra o texto e trava o botão |
| | autopreenchimento no Android | **adiado para a Fase 12** (Q-51) → ENT04 fica `[~]` |
| | SMS ou WhatsApp conforme flag | flags `loginSms` / `loginWhatsapp` (padrão: SMS ligado, WhatsApp desligado); com as duas, a pessoa escolhe |
| | provedor configurado pelo comprador | conector `sms_whatsapp` (fake já existe, TRV13) |
| ENT05 | cadastro e login | `POST /auth/email/signup` e `/auth/email/login` |
| | força mínima (RN-03) | 8+ caracteres com letras e números, recusa lista de senhas comuns; validado no app (ajuda) e no servidor (regra) |
| | confirmação por código | cadastro envia código por e-mail (`purpose: "signup"`); conta só entra depois de confirmar |
| | erros que não revelam se o e-mail existe | login errado = `401 credenciais_invalidas` sempre; cadastro com e-mail já usado responde igual a um cadastro novo ("enviamos um código") |
| ENT06 | conta nova → ENT08; existente entra; erro e cancelamento | `POST /auth/google { idToken }`. Fake: o botão abre uma lista de contas de teste (nova, existente, que falha); cancelar volta sem erro. Conta nova → "complete seu cadastro (em breve)" até a 1c (Q-52) |
| ENT07 | código por e-mail → nova senha → encerra sessões | `code/send` com `purpose: "reset"` (mesma resposta exista ou não o e-mail) + `POST /auth/password/reset` → revoga todas as sessões (RN-04) e pede novo login |
| ENT16 | aceite com versão e data; nova versão exige novo aceite | `GET /me` traz `pendingTerms` (documentos com versão nova); se houver, tela de aceite antes de continuar; `POST /me/terms/accept` registra `AceiteTermos` |
| ENT19 | um aparelho por conta | login novo revoga a sessão anterior: o aparelho antigo recebe `session.replaced` no tempo real e `401 sessao_substituida` na próxima chamada → volta ao login com o aviso "sua conta entrou em outro aparelho" |
| | renovação automática do token | interceptor: em `401 token_expirado` faz **um** `POST /auth/refresh` (fila única para chamadas simultâneas) e repete a requisição; refresh rotativo com detecção de reuso (reuso → revoga a sessão) |
| | sessão expirada volta ao login sem perder o contexto | guarda a rota atual; depois do login volta para ela (mesmo mecanismo do ENT17) |
| SEG06 | App Check, reCAPTCHA, Turnstile por flag; servidor decide | interface `AntiBotProvider` no app (fake devolve token de teste); servidor responde `428 desafio_necessario` quando a flag do provedor está ligada e a requisição não trouxe token válido; app obtém o token e repete. Reais na Fase 12 |
| ENT01 (fecha) | restaura sessão | tokens no armazenamento seguro; na abertura, `GET /me` valida; falhou com 401 → limpa e vai para boas-vindas |
| ENT17 (fecha) | retoma a ação após entrar | ação pendente roda quando a sessão real aparece (já testado com sessão falsa; E2E com login real) |

## 2. Contratos (antes do código) — todos em `docs/API.md` / `EVENTOS-TEMPO-REAL.md`
- **Aparelho com segredo** (revisão de segurança, M-026): `POST /devices` passa a devolver `deviceSecret` na criação (servidor guarda só o hash). Atualizar um aparelho e todas as rotas de login exigem `deviceId` + `deviceSecret`. App guarda o segredo no armazenamento seguro.
- `POST /auth/code/send` `{ channel: sms|whatsapp|email, destination, purpose: login|signup|reset }` → `200 { expiresInSeconds, resendInSeconds }`. Erros: `validacao`, `limite_excedido` (429 + `Retry-After`), `desafio_necessario` (428), `funcionalidade_desligada`.
- `POST /auth/code/verify` `{ destination, code, purpose, deviceId, deviceSecret }` → `200 { accessToken, refreshToken, expiresIn, user: { id, needsProfile } }`. Erros: `codigo_invalido`, `codigo_expirado`, `limite_excedido`.
- `POST /auth/email/signup` `{ email, password }` → `202` (código enviado). `POST /auth/email/login` `{ email, password, deviceId, deviceSecret }` → tokens. Erros: `credenciais_invalidas`, `email_nao_confirmado` (só com senha certa), `validacao` (senha fraca, com `details.rules`).
- `POST /auth/google` `{ idToken, deviceId, deviceSecret }` → tokens. Mock: `idToken` = `mock-google:<email>`; `mock-google:erro` → `401 credenciais_invalidas`.
- `POST /auth/password/reset` `{ email, code, newPassword }` → `204`; revoga todas as sessões.
- `POST /auth/refresh` `{ refreshToken }` → novos tokens (rotativo). Reuso de refresh já trocado → revoga a sessão → `401 sessao_substituida`.
- `POST /auth/logout` → `204`.
- `GET /me` (mínimo) → `{ id, needsProfile, accountStatus, pendingTerms: [{ document, version, url }] }`.
- `POST /me/terms/accept` `{ document, version }` → `204`.
- Novos códigos no catálogo: `credenciais_invalidas`, `email_nao_confirmado`, `desafio_necessario`.
- Flags novas: `loginSms`, `loginWhatsapp`; anti-bot: `antibotAppCheck`, `antibotRecaptcha`, `antibotTurnstile` (todas desligadas por padrão).
- Config nova (configurável pelo comprador): `limits.sessionIdleDays: 30` (Q-50), `limits.accessTokenMinutes: 15`.
- Mock-only: `GET /__mock/outbox?destination=…` devolve o último código "enviado" (para E2E); cenários `exigir-desafio`, `codigo-expira-rapido`.
- Eventos: `session.replaced` (já existe) passa a ser emitido no login em outro aparelho.

## 3. Dados (`docs/DATABASE.md`)
`Usuario` (id, situacao_conta, criado_em; o resto do perfil na 1c), `MetodoLogin`, `CodigoVerificacao` (só hash do código), `Sessao` (refresh só como hash, família de rotação para detectar reuso, `motivo_revogacao`), `AceiteTermos`, `Dispositivo.segredo_hash` → `em uso no mock`. App: `TokensLocais` e segredo do aparelho no armazenamento seguro (Keystore).

## 4. Mudanças por camada
- **mock-server:** `src/auth/` (códigos, senhas com hash forte — scrypt do Node, sem pacote novo —, tokens assinados, sessões com rotação, sessão única + `session.replaced`, anti-bot fake por flag), rotas `/auth/*` e `/me`, outbox, cenários, testes de contrato de cada rota e erro.
- **app:** `core/auth/` (TokenStore com `flutter_secure_storage` — já previsto na ARQUITETURA —, SessionController real, interceptor de refresh com fila única, tratamento de `sessao_substituida`/`session.replaced`), `core/antibot/` (interface + fake), `features/auth/` (telefone, código, e-mail login/cadastro/confirmar, recuperar senha, Google de teste, termos, "complete seu cadastro (em breve)", aviso de outro aparelho).
- **painel/portal:** nada.

## 5. Riscos
- **Segurança de conta (alto):** senhas só com hash forte; códigos só com hash e expiração; tokens curtos; refresh rotativo com detecção de reuso; rate limit por destino e por IP; mensagens que não revelam existência de conta; segredo do aparelho; nada sensível em log. Revisão do `revisor-seguranca` obrigatória.
- **Dados pessoais:** telefone e e-mail são 🔒 — mascarados em tela onde não precisam aparecer inteiros e nunca em log.
- **Web de teste:** `flutter_secure_storage` na web usa o armazenamento do navegador; serve só para o build de teste (o produto é Android).

## 6. Testes
- mock: contrato de cada rota (feliz + erros), limites de RN-02, senha fraca, e-mail inexistente responde igual, rotação e reuso de refresh, sessão única (2º login revoga o 1º e emite `session.replaced`), reset revoga sessões, termos pendentes, anti-bot por flag.
- app: unitários do TokenStore, interceptor (refresh único com chamadas paralelas, `sessao_substituida`), SessionController (restaurar, sair), validação de senha e máscara; widget de cada tela (pt/en, fonte 2x, erros).
- E2E web: `ENT04.cjs` (telefone → código do outbox → entra; código errado; limite), `ENT05.cjs` (cadastro → confirmar → entra; senha errada não revela), `ENT06.cjs` (conta nova → "complete seu cadastro"; existente entra; erro; cancelar), `ENT07.cjs` (reset derruba a outra sessão), `ENT16.cjs` (termos novos pedem aceite), `ENT19.cjs` (2 navegadores: login no 2º derruba o 1º com aviso; token expira e renova sozinho), `SEG06.cjs` (`exigir-desafio` → app resolve com o fake e entra), e `ENT17` atualizado (retoma a ação após login real).

## 7. Passos (um commit cada)
1. Contratos (API, eventos, catálogo de erros, flags, config) + DATABASE.
2. mock: segredo do aparelho + Usuario/MetodoLogin/Sessao em memória + tokens.
3. mock: códigos (send/verify) + limites RN-02 + outbox + cenários.
4. mock: e-mail (signup/login/confirmar) + senhas (RN-03) + reset (RN-04).
5. mock: Google de teste + refresh rotativo + reuso + logout + sessão única/`session.replaced`.
6. mock: `/me`, termos pendentes/aceite, anti-bot por flag.
7. app: TokenStore + SessionController + restaurar na abertura + interceptor de refresh + sessão substituída.
8. app: telefone + código (ENT04).
9. app: e-mail login/cadastro/confirmação + recuperar senha (ENT05, ENT07).
10. app: Google de teste + "complete seu cadastro (em breve)" (ENT06).
11. app: termos (ENT16) + anti-bot (SEG06) + retomar ação (ENT17).
12. E2E web dos itens + prints.
13. Revisões (revisor, revisor-seguranca, revisor-ux, guardiao-dados), verificador, docs.

## Ajustes da revisão de segurança (2026-11-21) — valem sobre o texto acima
1. **Força bruta:** limite em `/auth/email/login`, `/auth/password/reset` e `code/verify` por conta, por IP e por aparelho, com bloqueio progressivo; `429` idêntico exista ou não a conta. Código: morre após 5 erros, uso único, código novo invalida o anterior.
2. **Tempo constante:** login com e-mail inexistente roda o scrypt contra um hash falso; cadastro e recuperação com o mesmo tempo com ou sem conta (teste de contrato compara).
3. **Refresh preso ao aparelho:** `/auth/refresh` exige `deviceId` + `deviceSecret` da sessão.
4. **Revogação imediata:** access token carrega `sid`; toda rota autenticada e o WebSocket checam se a sessão está ativa. Logout, troca de senha, reuso de refresh e login em outro aparelho fecham o tempo real.
5. **Android:** `allowBackup=false` (ou regras de backup excluindo tokens/segredo) e armazenamento seguro com Keystore.
6. **Google:** liga a uma conta de e-mail existente só com `email_verified`; `mock-google:` só existe no mock (teste garante que o código real recusa).
7. **Reuso de refresh** responde `401 sessao_revogada` (novo código) e avisa o dono; tolerância de **10 s** para a resposta perdida na rede (o refresh anterior ainda vale uma vez nesse intervalo).
8. **Logs:** redação no logger do mock/backend de `password`, `newPassword`, `code`, `refreshToken`, `deviceSecret`, `idToken`, `destination` e `authorization`, com teste.
9. **Tempos:** `accessTokenMinutes` com piso 5 e teto 60 no servidor; validade máxima absoluta da sessão: **180 dias** desde o login, configurável (Q-54).
10. **Termos obrigatórios no servidor:** rotas autenticadas (exceto `/me`, `/me/terms/accept`, `/auth/logout`) respondem `403 termos_pendentes` enquanto houver aceite pendente. `AceiteTermos` guarda aparelho e IP 🔒.
11. **Conta suspensa/banida** não entra nem renova (`conta_suspensa`, `conta_banida`).
12. **`POST /devices`:** rate limit e anti-bot.
13. **Anti-bot (`428 desafio_necessario`)** vale em `code/send`, `email/signup`, `email/login`, `password/reset` e `devices`; o token do desafio é de uso único e preso à ação.
14. **E-mail "ocupado":** cadastro não confirmado não trava o e-mail (novo cadastro confirmado substitui); e-mail com conta confirmada recebe aviso "você já tem conta" em vez de código.
15. Alerta de novo aparelho ao dono da conta (SEGURANCA.md) — evento/notificação registrado; envio real com push (Fase 8).
16. Logout limpa o armazenamento local mesmo sem rede.
17. `/__mock/outbox` fica no módulo de rotas mock; teste garante que o app nunca chama `/__mock/*`.
- Novos códigos no catálogo: `sessao_revogada`, `termos_pendentes`.

## Ajustes da revisão do arquiteto (2026-11-21)
1. **Tempo real com token vencido:** `auth` do WebSocket distingue `token_expirado` (fecha com **`4003`, não terminal**) de `token_invalido` (`4001`, terminal). O `RealtimeClient` renova pelo `TokenSource` antes do `auth` e ao receber `4003`. Teste unitário + passo no `ENT19.cjs`.
2. **Conexão ligada à sessão (`sid`), não só à conta:** reconexão da mesma sessão fecha a antiga com código não terminal (`4004`); só sessão revogada por login em outro aparelho gera `session.replaced` (`4002`).
3. **Todo motivo de revogação tem evento e código:** `session.invalid { reason: senha_trocada | expirada | revogada | conta_bloqueada }` no tempo real; no HTTP: `sessao_substituida` (outro aparelho), `sessao_revogada` (reuso/logout em outro lugar), `sessao_expirada` (30 dias sem uso / máximo absoluto), `conta_suspensa`, `conta_banida`. Cada um com texto próprio no app.
4. **Anti-bot no contrato:** headers `X-Antibot-Provider` e `X-Antibot-Token` (no CORS do mock); lista de rotas do item 13 da segurança.
5. **`deviceSecret`:** segredo errado → `401 dispositivo_invalido`; instalação sem segredo (da 1a) recebe aparelho novo no próximo registro; `POST /devices` com `deviceId` exige o segredo para atualizar (200), senão cria outro (201).
6. **Termos:** tabela de correspondência `terms/privacy/guidelines` ↔ `termos/privacidade/diretrizes`; aceitar versão diferente da atual → `409 conflito`.
7. `sessionIdleDays`, `accessTokenMinutes` e os limites da RN-02 ficam na config **do servidor** (editável pelo comprador), não no `GET /config` público.
8. `loginPhone` liga a entrada por telefone; `loginSms`/`loginWhatsapp` escolhem os canais (telefone ligado com os dois canais desligados = sem telefone).
9. Logout aceita refresh token mesmo com access vencido e fecha o tempo real.
10. Chave que assina os tokens do mock: variável de ambiente ou aleatória no boot (nunca no repositório).
11. Cenário `token-expira-rapido` (access de 5 s) para o E2E da renovação.
12. `features/auth/` com `domain/` (regras de senha, máscara, estados) puro e `data/` (DTOs, repositório).
13. **ADR 0012 — Modelo de sessão** (access curto + refresh rotativo com detecção de reuso, ligação ao aparelho por `deviceSecret`, `sid` no token, códigos de fechamento do tempo real) escrita no passo 1.

## Andamento (2026-11-21)
- Passos 1–12 feitos (commits 10f4429 a 56e5469; passos 2–6 e 8–11 agrupados em um commit cada).
- Testes: mock 76, app 131, E2E web 88/88.
- Passo 13 pendente: revisões interrompidas pelo limite de uso; retomar e depois rodar o verificador.

Status: aprovado pelo usuário em 2026-11-21
