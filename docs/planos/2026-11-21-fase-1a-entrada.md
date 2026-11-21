# Plano: Fase 1a — Abrir o app, boas-vindas e navegação

- Data: 2026-11-21 · Branch: `claude/funny-darwin-w671g8`
- Itens: **ENT01, ENT02, ENT03, ENT17, ENT18** (módulo ENT) + **NAV01** (casca de navegação, destino "Home" do ENT01).
  - Exceção à regra "um módulo por plano": NAV01 entra porque o ENT01 precisa de uma Home para onde ir e o ENT17 precisa de ações reais que peçam login (Ao vivo, Mensagens, Perfil). Só a casca: o conteúdo das abas é de outras fases.
- Fora daqui (Fase 1b/1c): métodos de login (ENT04–07), sessão (ENT19), termos com aceite (ENT16), cadastro (ENT08–15), idioma (CFG14), anti-bot (SEG06).
- Decisões do usuário usadas: Q-44 (E2E no navegador), Q-45 (boas-vindas simples), Q-46 (termos em WebView).

## 1. Como cada critério será atendido
| Item | Critério | Como |
| --- | --- | --- |
| ENT01 | carrega config do tenant e do servidor | já existe (TRV04); splash = tela inicial com marca do tenant enquanto carrega |
| | registra o dispositivo | `POST /v1/devices` no primeiro uso (sem login); `deviceId` guardado no aparelho e reenviado nas próximas aberturas |
| | restaura sessão | Fase 1a: verifica se há sessão guardada; sem sessão → Boas-vindas. A restauração real (token, `GET /me`) chega com ENT19 no plano 1b → ENT01 fica `[~]` até lá |
| | decide Home / Boas-vindas / Atualização / Manutenção | roteador decide por estado: portão 426/503 (já existe) → região (ENT18) → sessão → visitante já escolheu "explorar" → Home; senão Boas-vindas |
| | tempo máximo de espera com erro e "tentar de novo" | 10 s no carregamento inicial (valor técnico, não de negócio) → `StateView.error` com "tentar de novo" |
| ENT02 | marca do tenant; Entrar, Criar conta, Explorar sem conta | tela simples (Q-45): nome do tenant, frase curta, 3 ações. "Explorar" grava modo visitante e vai à Home |
| | visitante navega, interação abre ENT17 | toda ação marcada como "exige conta" passa por `requireAccount()` |
| ENT03 | telefone, e-mail, Google conforme flags | lista só os métodos com flag ligada (`loginPhone`, `loginEmail`, `loginGoogle`); cada um leva a uma tela "em breve" até o plano 1b |
| | links para termos e política | abrem `LegalScreen` (WebView, Q-46) com a URL de `config.legalTexts`; navegação restrita ao domínio do portal |
| | aviso 18+ | texto fixo traduzido "Este app é só para maiores de 18 anos" com ícone |
| ENT17 | bottom sheet quando visitante interage | `AppBottomSheet` com Entrar / Criar conta |
| | após entrar, retoma a ação | a ação pendente fica guardada (`PendingAction`) e roda quando a sessão aparecer; testado com sessão falsa até o login real (1b) |
| ENT18 | países permitidos configuráveis; fora mostra tela informativa (detecção pelo servidor) | `GET /config` ganha `region: { country, allowed }`, calculado pelo servidor a partir da requisição; `allowedRegions` já é configurável. Fora da região → tela informativa, sem acesso ao resto |
| NAV01 | barra com Descobrir, Seguindo, Ao vivo (central), Mensagens (contador), Perfil; estado por aba; voltar previsível | `StatefulShellRoute` do go_router (uma pilha por aba). Abas com `StateView.empty` "em breve". Ao vivo, Mensagens e Perfil exigem conta (ENT17). Contador de mensagens lê `unread.updated` quando houver sessão (0 para visitante). Voltar: dentro da aba volta na pilha; na raiz de outra aba volta para Descobrir; em Descobrir fecha o app |

## 2. Contratos (antes do código)
- `POST /v1/devices` — corpo `{ deviceId?, platform: "android"|"web", appVersion, locale }` → `200 { deviceId }`. Sem auth. Idempotente por `deviceId`. Erros: `400 validacao`.
- `GET /v1/config` — novo campo `region: { country: "BR", allowed: true }`. Mock: país vem do header `X-Mock-Country` (padrão `BR`) e do cenário `regiao-bloqueada`. Backend real: geolocalização por IP (provedor a decidir na Fase 11; nova questão Q-47).
- Novo cenário `/__mock/scenario/regiao-bloqueada`.
- Nenhum evento novo.

## 3. Dados
- **Dispositivo** → `em uso no mock` (id, plataforma, versao_app, idioma, registrado_em, visto_em; `usuario_id` vazio até o login).
- **ConfigApp**: `region` é calculado por requisição, não guardado (anotar).
- **Preferências locais** (aparelho): `deviceId`, `visitorMode` (escolheu "explorar"). Sem dado pessoal.

## 4. Mudanças por camada
- **mock-server:** rota `/v1/devices`, `region` no `/config`, cenário novo, testes de contrato.
- **app:** `features/entry/` (splash/decisão, boas-vindas, escolha de entrada, legal, região bloqueada), `features/shell/` (NAV01), `core/auth/` (`AccountGate` + `PendingAction`), `core/device/` (registro). Dependência nova: `webview_flutter` (oficial, aprovado na Q-46). No build web de teste, a tela legal mostra o link em vez do WebView (o pacote não roda na web).
- **painel/portal:** nada.

## 5. Riscos
- **WebView:** só abre URLs do domínio do portal do tenant; outros links abrem fora ou são bloqueados; JavaScript ligado só porque o portal é Next.js (ver SEGURANCA).
- **Região:** no mock é por header/cenário; a detecção real (IP) é decisão da Fase 11/12 (Q-47). Nunca confiar em país informado pelo app.
- **Visitante:** nada de dado pessoal; ações que exigem conta são bloqueadas também no servidor (já vale: sem token = 401).

## 6. Testes
- mock-server: contrato de `/devices` (novo, repetido, inválido), `region` (padrão, header, cenário).
- app: unitários (decisão de rota, `PendingAction`, registro de dispositivo com reaproveitamento do id), widget (boas-vindas pt/en/RTL/fonte 2x, escolha de entrada respeitando flags, região bloqueada, barra de navegação e estado por aba, sheet ENT17).
- E2E web: `e2e/web/ENT01.cjs` (abre → boas-vindas; erro 500 → tentar de novo; manutenção), `ENT02-ENT03.cjs` (explorar → Home; Entrar → métodos conforme flags; termos abrem), `ENT17.cjs` (visitante toca em Perfil → sheet), `ENT18.cjs` (região bloqueada), `NAV01.cjs` (troca de abas e estado preservado). Prints claro/escuro e pt/en.

## 7. Passos
1. Contratos e DATABASE (devices, region, cenário, Q-47).
2. mock-server: `/devices` + `region` + cenário + testes.
3. app: registro de dispositivo + preferências locais + testes.
4. app: `AccountGate`/`PendingAction` + sheet ENT17 + testes.
5. app: decisão de rota (ENT01) + região bloqueada (ENT18) + timeout 10 s + testes.
6. app: boas-vindas (ENT02) + escolha de entrada (ENT03) + LegalScreen (WebView) + testes.
7. app: casca de navegação (NAV01) + testes.
8. E2E web dos itens + prints; ajustar `tools/dev/e2e-web.sh` se preciso.
9. Revisões (revisor, revisor-ux, revisor-seguranca, guardiao-dados), verificador-spec, docs.

## Ajustes da revisão do arquiteto (2026-11-21) — valem sobre o texto acima
1. **Região é portão HTTP, não campo da config.** O servidor responde `403 regiao_bloqueada` em todas as rotas `/v1/*` (mesmas exceções de 426/503: `/config` e o upgrade do tempo real), com `details.country`. O app trata como portão (`GateRegionBlocked`). Para o app saber já na abertura, `GET /config` inclui `region` **calculado por requisição, fora do cache local e fora do `config.updated`** (escrito em API.md e DATABASE.md). A barreira real é o 403 no servidor.
2. **`POST /v1/devices`:** o servidor gera o `deviceId`; id desconhecido ou forjado recebe id novo (nunca é adotado); `201` ao criar, `200` ao atualizar; limite de frequência por IP no backend real. Campos batem com a entidade Dispositivo (`modelo` opcional). Esse id é a base da RN-06 no plano 1b. `platform` aceita `android`, `ios` e `web` (só build de teste).
3. **Tempo de espera:** 10 s é o prazo total da abertura (config); o registro do dispositivo roda em segundo plano e não bloqueia a decisão de rota (falhou → tenta na próxima abertura).
4. **`PendingAction`:** só em memória, expira em 5 min, a ação é revalidada no servidor quando roda.
5. **Decisão de rota** em `features/entry/domain` como função Dart pura, com teste de tabela de todas as combinações (portão, região, sessão, visitante).
6. `X-Mock-Country` documentado como só do mock (o app nunca envia) e incluído no CORS do mock.
7. Testes de widget com fonte 2x e RTL também na barra de navegação.
8. **Voltar (Q-48):** em Descobrir, toque duplo para sair (aviso por 2 s). **Seguindo para visitante (Q-49):** tela vazia com convite e botão Entrar; Ao vivo, Mensagens e Perfil abrem o ENT17.

Status: aguardando aprovação
