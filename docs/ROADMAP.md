# Roadmap (ordem de construção)

> Todo o produto é MVP (decisão do usuário). As fases são a **ordem de construção**, não de lançamento.
> Uma fase só começa quando a anterior passou no `/auditar` sem pendências críticas.
> Os IDs entre parênteses estão em `docs/ESPECIFICACAO.md`.

## Fase 0 — Fundação
- [ ] Monorepo: `apps/mobile`, `apps/admin`, `apps/portal`, `mock-server`, `tenants/liveapp`
- [ ] Flutter Android com flavor `liveapp` gerado de `tenants/liveapp/tenant.json`; tema claro/escuro; pt-BR e inglês; layout pronto para RTL
- [ ] Escolher cores e fonte do demo (Q-42)
- [ ] Núcleo do app: tema a partir do design system, rotas, HTTP, erros padronizados, i18n pt-BR, flags (TRV03, TRV04, TRV07, TRV09)
- [ ] Cliente de tempo real com reconexão (TRV01)
- [ ] `VideoProvider` + `FakeVideoProvider` (TRV02)
- [ ] mock-server: estrutura, fixtures, envelope de eventos, rotas `/__mock/*`, conectores fake (TRV13), configurações editáveis, testes de contrato
- [ ] CI: lint, testes, build APK debug
- [ ] Maestro configurado com um fluxo de exemplo

## Fase 1 — Entrada e conta
- [ ] ENT01–ENT19, NAV01, NAV04, CFG14, SEG06

## Fase 2 — Descoberta e perfil
- [ ] DES01–DES09, PER01–PER09, NAV02, NAV03

## Fase 3 — Live (vídeo simulado)
- [ ] ASS01–ASS16, TRA01–TRA16, NAV05, TRV14

## Fase 4 — Economia e presentes
- [ ] ECO01–ECO12 (exceto removidos), PRE01–PRE12

## Fase 5 — PK, convidados e grupo
- [ ] PK01–PK10 (e revisão de TRA07, TRA08)

## Fase 6 — Mensagens, feed e chamadas
- [ ] MSG01–MSG12, FEED01–FEED06, CHA01–CHA11

## Fase 7 — VIP, assinaturas, comunidade e estatísticas
- [ ] VIP01, VIP03–VIP08, SUB01–SUB04, FAM01–FAM06, AGE01–AGE04, EST01–EST06

## Fase 8 — Configurações, suporte e segurança
- [ ] CFG01–CFG13, SEG01–SEG08, TRV05, TRV06, TRV10, TRV11, TRV12

## Fase 9 — Painel admin e portal do usuário
- [ ] ADM01–ADM21
- [ ] POR01–POR07

## Fase 10 — Revisão completa contra o mock
- [ ] `/auditar` geral sem pendências
- [ ] `docs/DATABASE.md`, `docs/API.md` e `docs/EVENTOS-TEMPO-REAL.md` 100% sincronizados com o código (`/sincronizar-dados`)
- [ ] Todas as questões de `docs/QUESTOES-ABERTAS.md` respondidas ou adiadas conscientemente

## Fase 11 — Banco de dados e backend real
- [ ] Usuário escolhe banco e framework (`/preparar-banco`)
- [ ] Schema gerado a partir de `docs/DATABASE.md`
- [ ] Backend implementando `docs/API.md` e `docs/EVENTOS-TEMPO-REAL.md`, com os mesmos testes de contrato do mock-server
- [ ] App apontando para o backend real

## Fase 12 — Integrações reais
- [ ] Agora (`AgoraVideoProvider`, servidor de token, relay de PK, beleza básica)
- [ ] Conectores reais (TRV13): pagamento alternativo e web, repasse/saque, SMS/WhatsApp, verificação de idade (Yoti como padrão), tradução, moderação de mídia, anti-bot
- [ ] Google Play Billing, Play Age Signals, Google Sign-In, push (FCM), Firebase Analytics + Crashlytics, detecção no aparelho (TRV14)
- [ ] Responder Q-35, Q-37, Q-38, Q-39, Q-40 com pesquisa antes de integrar

## Fase 13 — Pronto para vender
- [ ] White-label: script de novo cliente (TRV08) e guia de onboarding
- [ ] Testes de carga (lives com muitos espectadores, rajada de presentes, PK)
- [ ] Revisão de segurança completa e revisão jurídica das features com trava e do modelo de idade (Q-41)
- [ ] Publicação na Google Play do tenant demo `liveapp`
- [ ] Primeiro cliente piloto

## Depois do Android
- [ ] iOS (mesmo código; exige Mac ou build na nuvem, conta Apple Developer do cliente; verificação de idade da Apple, Q-36)
