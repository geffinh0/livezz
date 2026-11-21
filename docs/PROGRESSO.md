# Progresso

> Atualizado pelo Claude ao fim de **toda** tarefa. Curto: o estado atual, não um diário.
> Inclua sempre uma linha `dados:` dizendo se a tarefa mexeu no modelo de dados (e o que foi atualizado no DATABASE.md) ou `dados: sem impacto`.

## Estado atual
Fase 1a implementada e verificada: ENT18 `[x]`; ENT01, ENT02, ENT03, ENT17, NAV01 `[~]` (faltam: restaurar sessão e retomar ação após login real → plano 1b; visitante assistir live → Fase 3; botão "Atualizar" com link da loja → M-030). Testes: app 115, mock 45, E2E web 50/50. Decisões Q-50 a Q-53 (sessão 30 dias, autopreenchimento do SMS na Fase 12, cadastro na 1c, Google por contas de teste do mock).

## Próximo passo
`/planejar` do plano 1b: ENT04, ENT05, ENT06, ENT07, ENT16, ENT19, SEG06 (login, recuperar senha, termos, sessão única, anti-bot).

## Problemas conhecidos / dívidas técnicas
- Sessão da nuvem sem Android SDK nem aparelho: APK só no CI (confirmado: run 12 verde, artefato `liveapp-debug-apk`), Maestro só na máquina do usuário (`tools/dev/setup-linux.sh` e `tools/dev/e2e-emulador.sh`).
- Em release, a tela inicial fica vazia depois de carregar a config (as telas de produto chegam na ENT01).
- Ver `docs/MELHORIAS.md` M-004 a M-022 (sugestões das revisões).

## Últimas sessões (manter só as 5 mais recentes)
- 2026-11-21: Fase 1a concluída (revisões + verificador); E2E web ganhou casos de erro e espera por texto; script de E2E encerra o grupo de processos. dados: API.md com cenário `entrada-desligada` e CORS do mock.
- 2026-11-21: Fase 1a passos 1–7. dados: DATABASE.md atualizado — Dispositivo em uso no mock (id gerado pelo servidor), PreferenciasLocais no app, `region` calculado por requisição (ver Histórico).
- 2026-11-21: auditoria final da Fase 0; bug do portão de versão mínima corrigido (o app não comparava `minAppVersion`); regra nova no CLAUDE.md (trocar de abordagem após 2 falhas); Q-44 a Q-47; plano 1a. dados: sem impacto.
- 2026-11-21: emulador no PC do usuário abandonado após falhas repetidas (OOM, SIGILL); app passou a compilar para web e ganhou E2E no navegador (Playwright) local e no CI; contraste dos botões no tema escuro corrigido; CORS local no mock-server. dados: sem impacto.
- 2026-11-21: Fase 0 implementada (19 passos + correções das revisões). dados: DATABASE.md atualizado — ConfigApp (versao, manutencao, correspondência JSON↔banco) e IntegracaoProvedor em uso no mock, ConfigCacheLocal no app, dados de teste do mock; API.md e EVENTOS-TEMPO-REAL.md com detalhes da Fase 0 (ver Histórico).
- 2026-11-20: kit instalado no repositório; Flutter 3.50.1 instalado na sessão da nuvem (sem Android SDK: APK via CI); Q-42 e Q-43 respondidas; plano da Fase 0 escrito e revisado. dados: sem impacto (ConfigApp.versao entra no passo 2 do plano).
- 2026-11-20: respostas do usuário aplicadas (configurável pelo comprador, portal web, um aparelho por conta, VIP por gasto, cobrança por presente, detecção, idiomas, sem jogos). dados: DATABASE.md atualizado (ver Histórico).
- 2026-11-20: kit completo criado (especificação, DATABASE.md, API, eventos, regras, segurança, design system, skills, agentes, hooks). dados: modelo lógico inicial proposto.
