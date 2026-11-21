# Plano: Fase 0 — Fundação

- Data: 2026-11-20
- Branch: `feat/fase-0-fundacao` (nesta sessão na nuvem: `claude/funny-darwin-w671g8`)
- Itens cobertos: TRV01, TRV02, TRV03, TRV04, TRV07, TRV09 (parte de infraestrutura), TRV13 (lado mock-server), base de TRV08 (tenant por configuração) e a estrutura do ROADMAP "Fase 0".
- Pré-requisito resolvido: Q-42 (Magenta + Laranja, Plus Jakarta Sans, Material Symbols).

> Fase 0 não entrega telas de produto. Ela entrega o "esqueleto" que todas as fases usam: monorepo, app que abre com a marca do tenant, mock-server que segue o contrato, tempo real, vídeo fake, erros, idiomas, CI e o primeiro fluxo E2E.
> Por isso os itens TRV ficam `[~]` (em andamento) ao fim da Fase 0 quando parte do critério depende de telas de fases seguintes (ex.: TRV09 "versão mínima" só fica visível com a ENT01). Só vira `[x]` o que cumprir a Definição de pronto inteira.

## 1. Como cada item será atendido
| Item | Critério | Como |
| --- | --- | --- |
| TRV01 | envelope versionado, reconexão exponencial, heartbeat, re-entrada em salas, ignorar tipos desconhecidos | `core/realtime/RealtimeClient` (Dart puro + `web_socket_channel`): parse do envelope `{v,id,type,ts,data}`, dedup por `id`, ignora `v>1` e tipos desconhecidos com log; backoff 1→30 s com jitter; `ping` a cada 25 s, reconecta sem `pong` em 10 s; reenvia `auth` e `room.join` das salas ativas ao reconectar e emite `reconnected` para as features rebuscarem estado por REST. Testado com relógio falso e servidor WS de teste. |
| TRV02 | `VideoProvider` com fake completo | Interface em `core/video/video_provider.dart` (joinAsHost, joinAsAudience, leave, switchCamera, setMic, setCamera, startRelay, stopRelay, streams de estado). `FakeVideoProvider`: vídeo de exemplo em loop (asset próprio, gerado por nós) para espectador; prévia do host com placeholder (câmera real entra na Fase 3 junto com permissões); simula convidado entrando/saindo e relay de PK. `BeautyProvider` no-op. |
| TRV03 | repositórios por feature, erros padronizados, paginação por cursor, idempotência | `core/http`: dio com interceptors de `Accept-Language`, `X-App-Version`, `Idempotency-Key` (gerado por operação), mapeamento do corpo `{error:{code,...}}` para `ApiFailure(code)` e de falha de rede para `NetworkFailure`; tipo `Page<T>{items,nextCursor}`. Interceptor de auth/refresh fica preparado (sem token na Fase 0; entra na Fase 1). |
| TRV04 | config remota e flags lidas no início e atualizadas por evento | `GET /v1/config` no mock-server + `core/flags/ConfigController` (Riverpod) que carrega no início e aplica `config.updated` (merge parcial) vindo do tempo real. |
| TRV07 | pt-BR e inglês, pronto para RTL, nenhum texto fixo | `flutter_localizations` + ARB (`app_pt.arb`, `app_en.arb`), lint que proíbe string literal em widgets de `presentation` (regra de análise + teste que procura `Text('`). Só `EdgeInsetsDirectional`/`AlignmentDirectional`. Teste de widget renderizando a tela de exemplo em `ar` (RTL) sem overflow. |
| TRV09 | mensagens amigáveis, offline, tentar de novo, versão mínima | Mapa `error.code → texto` nos ARB para todo o catálogo de erros da API; `StateViews` (carregando, vazio, erro, sem conexão, sem permissão) com "tentar de novo"; interceptor reconhece `426 atualizacao_obrigatoria` e `manutencao` e publica um estado global. A tela de "atualize o app" é da ENT01 (Fase 1). |
| TRV13 | conectores no servidor com fake | `mock-server/src/connectors/`: interface por tipo (`pagamento_loja_alternativa`, `pagamento_web`, `repasse_saque`, `sms_whatsapp`, `verificacao_idade`, `traducao`, `moderacao_midia`, `antibot`, `push`, `analytics`) + implementação fake de cada uma + registro (`ConnectorRegistry`) que lê a escolha de `IntegracaoProvedor`. Sem rotas de admin ainda (ADM19 é Fase 9). |
| TRV08 (base) | tenant por configuração | `tools/tenant/generate.mjs` lê `tenants/<id>/tenant.json` (validado por schema) e gera: flavor Android (`applicationId`, nome, cores do ícone), `lib/core/tenant/tenant_config.g.dart` (marca, cores, fonte, URLs, flags iniciais) e um `tenant.ts` para admin/portal. Script de "novo cliente" completo fica para a Fase 13. |

## 2. Contratos (escritos antes do código)
- `docs/API.md`: detalhar `GET /v1/config` (resposta: `minAppVersion`, `maintenance`, `flags{}`, `limits{}`, `discoverTabs[]`, `legalTexts{}`, `allowedRegions[]`, `configVersion`) e as rotas mock `/__mock/reset`, `/__mock/scenario/{nome}` (Fase 0: `erro-500`, `rede-lenta`, `manutencao`, `versao-minima`), `/__mock/emit`. Status → `no mock` quando implementado.
- `docs/EVENTOS-TEMPO-REAL.md`: detalhar `auth`, `ping`/`pong`, `ack`, `room.join`/`room.leave`, `config.updated`, `session.invalid`. Na Fase 0 o `auth` aceita **tokens de teste do mock** (fixture `dev-token-<usuario>`), documentado como mock-only; o login real vem na Fase 1.
- Nenhum contrato existente quebra.

## 3. Dados (`docs/DATABASE.md`)
- `ConfigApp`: campos usados pelo `GET /config` → status `em uso no mock`.
- `FlagHistorico`: só proposto (escrita vem com o painel).
- `IntegracaoProvedor`: `em uso no mock` (registro de conectores fake, sem credenciais).
- Histórico atualizado. Linha `dados:` no PROGRESSO.

## 4. Mudanças por camada
**Raiz do monorepo**
- `apps/mobile`, `apps/admin`, `apps/portal`, `mock-server`, `tools/tenant`, `tenants/liveapp` (já existe).
- `.editorconfig`, `.nvmrc` (Node LTS), npm workspaces para `mock-server`, `apps/admin`, `apps/portal`, `tools/tenant`.

**mock-server** (Node 22 LTS + TypeScript estrito)
- Fastify (REST) + `ws` (WebSocket), validação com TypeBox (JSON Schema nativo do Fastify).
- `src/config/` config central editável (valores de RN-xx provisórios, nunca espalhados).
- `src/realtime/` hub de salas, envelope, auth por token de teste, heartbeat, fechamento sem `auth` em 5 s.
- `src/scenarios/` + rotas `/__mock/*`; `src/connectors/` (TRV13); `fixtures/` (config inicial, 3 usuários de teste fictícios).
- Testes de contrato (Vitest + `fastify.inject` + cliente `ws`) para cada rota e evento da Fase 0, caminho feliz e erros.
- ESLint + Prettier; `npm run dev | test | lint | typecheck`.

**App** (`apps/mobile`, Flutter 3.50 estável)
- `lib/core/`: `tenant/` (gerado), `theme/` (tokens do DESIGN-SYSTEM a partir do tenant, claro/escuro/sistema, Plus Jakarta Sans empacotada como asset, Material Symbols), `ui/` (AppButton, AppBottomSheet, AppDialog, AppTextField, StateViews, Toast — versões base), `routing/` (go_router), `http/`, `realtime/`, `video/`, `flags/`, `i18n/`, `errors/`, `analytics/` (`AnalyticsProvider` + fake de console).
- `lib/features/dev_showcase/` (só em debug): tela que mostra marca, tema, componentes, estado da config e da conexão de tempo real. Serve de alvo para o E2E e para você conferir o visual no celular. Não é tela de produto.
- Flavor `liveapp` gerado do tenant.
- Testes: unitários (realtime, http/erros, config, tema), widget (StateViews, showcase em pt/en/RTL, claro/escuro).

**Painel e portal** (`apps/admin`, `apps/portal`)
- Esqueleto Next.js (App Router) + TypeScript com página inicial mostrando a marca do tenant e lendo `GET /v1/config` do mock; lint e um teste cada. Telas reais nas Fases 9.

**CI** (`.github/workflows/ci.yml`)
- Jobs: mock-server (lint, typecheck, test), mobile (analyze, test, build APK debug do flavor `liveapp`), admin e portal (lint, test). Roda a cada push/PR.

**E2E** (`apps/mobile/e2e/`)
- `TRV-fundacao.yaml`: `POST /__mock/reset`, abre o app, confere showcase (marca, conexão "conectado"); erro: `/__mock/scenario/erro-500` → StateViews de erro → "tentar de novo".

## 5. Dependências novas (preciso do seu ok)
Já previstas na ARQUITETURA: Riverpod, go_router, dio, freezed + json_serializable, flutter_secure_storage, Lottie (só na Fase 4), Fastify, ws, Next.js.
Novas que proponho:
| Pacote | Para quê | Alternativa |
| --- | --- | --- |
| `web_socket_channel` (Dart, mantido pelo time do Dart) | base do cliente de tempo real | `dart:io` WebSocket direto (menos testável) |
| `video_player` (Flutter oficial) | vídeo de exemplo do FakeVideoProvider | — |
| `material_symbols_icons` | Material Symbols no Flutter (o Flutter só traz o Material Icons antigo) | usar Material Icons padrão (visual diferente do web) |
| `@sinclair/typebox` | schemas de validação no mock-server | `zod` |
| `vitest` | testes do mock-server/admin/portal | `jest` (mais lento e pesado com TS) |
| ESLint + Prettier | lint/format (o hook de formatação usa Prettier) | — |
Antes de instalar cada uma, confiro a documentação atual e a compatibilidade com Flutter 3.50 / Node 22.

## 6. Riscos
- **Ambiente:** esta sessão roda na nuvem; tem Node e Flutter, mas **não tem Android SDK** (download bloqueado pela rede) nem celular. Aqui rodam `flutter analyze`/`flutter test` e tudo do mock-server/web. O **APK é gerado no CI do GitHub**; o **Maestro roda na sua máquina** com o celular. Na sua máquina você precisa de Flutter, Android Studio/SDK, Maestro e um aparelho.
- **Fonte:** Plus Jakarta Sans (licença OFL) será empacotada no app (sem baixar em tempo de execução: funciona offline e não manda dados ao Google). Se o download dos arquivos for bloqueado aqui, uso o pacote do npm `@fontsource/plus-jakarta-sans` como fonte dos arquivos.
- **Vídeo de exemplo:** precisa ser nosso (nada de terceiros). Gero um clipe curto e leve (gradiente animado com a marca) para não pesar no APK.
- **Segurança:** token de teste do WS só existe no mock-server; o app real nunca terá token fixo. Nenhum segredo no repositório (o hook confere).
- **Complexidade:** admin/portal ficam só esqueleto para não gastar tempo antes da Fase 9.

## 7. Testes
- mock-server: contrato de `GET /v1/config`, `/__mock/*`, WS (auth ok/inválido/timeout 5 s, ping/pong, join/leave + ack, `config.updated` entregue só a quem está conectado, envelope válido), conectores fake (cada um responde pela interface).
- App unitário: envelope (válido, `v` maior, tipo desconhecido, duplicado), backoff com jitter, heartbeat/reconexão, re-join; mapeamento de erros (cada `code` do catálogo tem texto pt e en); interceptors; merge de `config.updated`.
- App widget: StateViews (5 estados), showcase claro/escuro, pt/en, RTL, fonte 2x sem overflow, contraste dos tokens (teste que calcula a razão e exige ≥ 4,5).
- E2E: `TRV-fundacao.yaml` (caminho feliz + erro 500).

## 8. Passos (um commit cada)
1. `chore`: monorepo (workspaces, editorconfig, nvmrc, .gitignore ajustado) + `tools/tenant` com schema do `tenant.json` e teste.
2. `docs(TRV04 TRV01)`: contratos detalhados em API.md e EVENTOS-TEMPO-REAL.md (status proposto) + DATABASE.md.
3. `feat(mock)`: esqueleto do mock-server (Fastify, config central, fixtures, lint/typecheck/test).
4. `feat(TRV04)`: `GET /v1/config` + testes de contrato.
5. `feat(mock)`: rotas `/__mock/reset|scenario|emit` + cenários da Fase 0 + testes.
6. `feat(TRV01)`: WebSocket do mock (auth, heartbeat, salas, ack, envelope) + testes.
7. `feat(TRV13)`: interfaces e conectores fake + registro + testes.
8. `feat(mobile)`: projeto Flutter, flavor `liveapp` gerado do tenant, lints estritos.
9. `feat(TRV07)`: i18n pt/en, RTL, regra contra texto fixo.
10. `feat(mobile)`: tema a partir do tenant (claro/escuro/sistema, fonte, ícones) + teste de contraste.
11. `feat(TRV03 TRV09)`: http (dio, interceptors, erros por code, Page<T>) + textos de erro.
12. `feat(TRV04)`: ConfigController + flags.
13. `feat(TRV01)`: RealtimeClient + testes.
14. `feat(TRV02)`: VideoProvider + FakeVideoProvider + BeautyProvider no-op.
15. `feat(mobile)`: componentes base do design system + StateViews + showcase de debug.
16. `feat(admin portal)`: esqueletos Next.js.
17. `ci`: workflow GitHub Actions.
18. `test(e2e)`: Maestro + `TRV-fundacao.yaml` + instruções para rodar no celular.
19. `docs`: PROGRESSO, ESPECIFICACAO (status), DATABASE/API/EVENTOS → `no mock`, MELHORIAS, roteiro de teste para você.

## Ajustes da revisão do arquiteto (2026-11-20) — valem sobre o texto acima
1. **URL da API por ambiente:** `apiBaseUrl` do tenant é só o padrão; o build recebe a URL por `--dart-define=API_BASE_URL`. Texto puro (`http`/`ws`) liberado só no build debug (`network_security_config` restrito a `localhost`/`10.0.2.2`); release exige HTTPS/WSS (SEGURANCA.md). Roteiro do celular inclui `adb reverse tcp:3000 tcp:3000`.
2. **Flags só do servidor:** o `tenant.json` alimenta a **fixture do mock** (`ConfigApp` inicial), não o app. O app usa só `GET /v1/config` (com cache local da última config válida). Nomes de flags unificados em `camelCase` no JSON (`luckyGift`), `snake_case` só no DATABASE.md, com a tabela de correspondência lá.
3. **`config.updated` antes do login (Q-43, ADR 0011):** sem login o app rebusca `GET /v1/config` ao abrir e ao voltar do segundo plano; logado, recebe `config.updated` pelo tempo real. Sem conexão anônima.
4. **Versão da config:** `ConfigApp.versao` (inteiro crescente) no DATABASE.md; app ignora `config.updated` com versão ≤ atual e rebusca a config no `reconnected`.
5. **`manutencao`:** HTTP `503` + `Retry-After`, definido em API.md no passo 2.
6. **TRV13 enxuto:** registro com os 10 tipos e fakes mínimos; contrato detalhado só para `sms_whatsapp` e `verificacao_idade` (usados na Fase 1). TRV13 fica `[~]`.
7. **CI cedo:** workflow entra logo após o passo 8 (mobile analyze/test + build APK) e cresce a cada passo.
8. **Vídeo fake testável:** estado do `FakeVideoProvider` em Dart puro (testado com `flutter test`); o widget com `video_player` fica separado. Clipe gerado com `ffmpeg` (gradiente animado próprio, < 300 KB).
9. `/__mock/emit` valida `type` contra o catálogo; `/__mock/reset` zera cenários.
10. Rotas `/__mock/*` num plugin Fastify isolado, registrado só pelo mock.
11. `RealtimeClient` recebe o token por `TokenSource` (Fase 0: dev-token; Fase 1: sessão real).
12. Texto fixo: lint customizado (`custom_lint`) cobrindo `Text`, `tooltip`, `semanticsLabel`, `hintText`, `labelText`.
13. `dev_showcase` só com `kDebugMode` (rota e import fora do release); E2E encontra elementos por Key.
14. Arquivos gerados (freezed/json_serializable/l10n) **não** vão para o git; CI roda `build_runner`.

Ordem dos passos revisada: 1, 2, 3, 4, 5, 6, 7, 8, **17 (CI)**, 9, 10, 11, 12, 13, 14, 15, 16, 18, 19.

## 9. Fora do escopo
- Login, sessão e refresh real (Fase 1); telas de produto; câmera real e permissões (Fase 3); push, analytics real, Crashlytics (Fases 8/12); painel e portal funcionais (Fase 9); Agora (Fase 12); script completo de novo cliente (Fase 13).

## Andamento (2026-11-21)
- Passos 1–19 implementados, um commit por passo (ver `git log`), mais correções das revisões.
- Testes: mock-server 35 · app 68 (+2 de integração contra o mock real, passando) · tenant 7 · painel 3 · portal 3.
- Revisões: arquiteto (plano), revisor, revisor-seguranca, revisor-ux, guardiao-dados, verificador-spec. Problemas reais corrigidos nos commits `fix(mobile)` e `fix(mock)`; sugestões em `docs/MELHORIAS.md` (M-004 a M-022).
- Pendente para fechar a fase: rodar `apps/mobile/e2e/TRV-fundacao.yaml` num aparelho (sem aparelho na sessão da nuvem) e confirmar o APK no CI. Por isso os TRV ficam `[~]`.

Status: aprovado pelo usuário em 2026-11-21 · implementado, aguardando E2E no aparelho
