# Progresso

> Atualizado pelo Claude ao fim de **toda** tarefa. Curto: o estado atual, não um diário.
> Inclua sempre uma linha `dados:` dizendo se a tarefa mexeu no modelo de dados (e o que foi atualizado no DATABASE.md) ou `dados: sem impacto`.

## Estado atual
Fase 0 (fundação) implementada na branch `claude/funny-darwin-w671g8`: monorepo, gerador de tenant, mock-server (config, cenários, WebSocket, conectores fake), app Flutter (tema do tenant, i18n pt/en + RTL, HTTP, config remota, tempo real, vídeo fake, componentes base, vitrine de debug), esqueletos do painel e do portal, CI e fluxo Maestro. TRV01–04, 07–09 e 13 em `[~]`. E2E no navegador (Flutter web + Playwright) passando 12/12 aqui e no CI; E2E Android (Maestro) ainda não rodou: o emulador do usuário trava (SIGILL) e foi deixado de lado.

## Próximo passo
1. Decidir com o usuário se o E2E web basta para fechar a Fase 0 ou se roda o Maestro num celular via USB / emulador no CI; depois `/auditar` TRV e `/retro fase-0`.
2. Depois: `/planejar` da Fase 1 (ENT01–ENT19, NAV01, NAV04, CFG14, SEG06).

## Problemas conhecidos / dívidas técnicas
- Sessão da nuvem sem Android SDK nem aparelho: APK só no CI (confirmado: run 12 verde, artefato `liveapp-debug-apk`), Maestro só na máquina do usuário (`tools/dev/setup-linux.sh` e `tools/dev/e2e-emulador.sh`).
- Em release, a tela inicial fica vazia depois de carregar a config (as telas de produto chegam na ENT01).
- Ver `docs/MELHORIAS.md` M-004 a M-022 (sugestões das revisões).

## Últimas sessões (manter só as 5 mais recentes)
- 2026-11-21: emulador no PC do usuário abandonado após falhas repetidas (OOM, SIGILL); app passou a compilar para web e ganhou E2E no navegador (Playwright) local e no CI; contraste dos botões no tema escuro corrigido; CORS local no mock-server. dados: sem impacto.
- 2026-11-21: Fase 0 implementada (19 passos + correções das revisões). dados: DATABASE.md atualizado — ConfigApp (versao, manutencao, correspondência JSON↔banco) e IntegracaoProvedor em uso no mock, ConfigCacheLocal no app, dados de teste do mock; API.md e EVENTOS-TEMPO-REAL.md com detalhes da Fase 0 (ver Histórico).
- 2026-11-20: kit instalado no repositório; Flutter 3.50.1 instalado na sessão da nuvem (sem Android SDK: APK via CI); Q-42 e Q-43 respondidas; plano da Fase 0 escrito e revisado. dados: sem impacto (ConfigApp.versao entra no passo 2 do plano).
- 2026-11-20: respostas do usuário aplicadas (configurável pelo comprador, portal web, um aparelho por conta, VIP por gasto, cobrança por presente, detecção, idiomas, sem jogos). dados: DATABASE.md atualizado (ver Histórico).
- 2026-11-20: kit completo criado (especificação, DATABASE.md, API, eventos, regras, segurança, design system, skills, agentes, hooks). dados: modelo lógico inicial proposto.
