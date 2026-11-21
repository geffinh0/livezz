# Progresso

> Atualizado pelo Claude ao fim de **toda** tarefa. Curto: o estado atual, não um diário.
> Inclua sempre uma linha `dados:` dizendo se a tarefa mexeu no modelo de dados (e o que foi atualizado no DATABASE.md) ou `dados: sem impacto`.

## Estado atual
Fase 0 concluída (auditoria 2026-11-21): TRV01, TRV04 e TRV07 prontos `[x]`; TRV02, TRV03, TRV08, TRV09 e TRV13 em `[~]` com o resto atribuído às fases donas (vídeo/câmera na Fase 3, idempotência e paginação no primeiro endpoint que usar, script de novo cliente na Fase 13, ADM19 na Fase 9). E2E no navegador 13/13. Fase 1a planejada (`docs/planos/2026-11-21-fase-1a-entrada.md`), revisada pelo arquiteto, aguardando aprovação.

## Próximo passo
Usuário aprovar o plano 1a (e responder voltar/aba Seguindo para visitante); depois `/implementar`.

## Problemas conhecidos / dívidas técnicas
- Sessão da nuvem sem Android SDK nem aparelho: APK só no CI (confirmado: run 12 verde, artefato `liveapp-debug-apk`), Maestro só na máquina do usuário (`tools/dev/setup-linux.sh` e `tools/dev/e2e-emulador.sh`).
- Em release, a tela inicial fica vazia depois de carregar a config (as telas de produto chegam na ENT01).
- Ver `docs/MELHORIAS.md` M-004 a M-022 (sugestões das revisões).

## Últimas sessões (manter só as 5 mais recentes)
- 2026-11-21: auditoria final da Fase 0; bug do portão de versão mínima corrigido (o app não comparava `minAppVersion`); regra nova no CLAUDE.md (trocar de abordagem após 2 falhas); Q-44 a Q-47; plano 1a. dados: sem impacto.
- 2026-11-21: emulador no PC do usuário abandonado após falhas repetidas (OOM, SIGILL); app passou a compilar para web e ganhou E2E no navegador (Playwright) local e no CI; contraste dos botões no tema escuro corrigido; CORS local no mock-server. dados: sem impacto.
- 2026-11-21: Fase 0 implementada (19 passos + correções das revisões). dados: DATABASE.md atualizado — ConfigApp (versao, manutencao, correspondência JSON↔banco) e IntegracaoProvedor em uso no mock, ConfigCacheLocal no app, dados de teste do mock; API.md e EVENTOS-TEMPO-REAL.md com detalhes da Fase 0 (ver Histórico).
- 2026-11-20: kit instalado no repositório; Flutter 3.50.1 instalado na sessão da nuvem (sem Android SDK: APK via CI); Q-42 e Q-43 respondidas; plano da Fase 0 escrito e revisado. dados: sem impacto (ConfigApp.versao entra no passo 2 do plano).
- 2026-11-20: respostas do usuário aplicadas (configurável pelo comprador, portal web, um aparelho por conta, VIP por gasto, cobrança por presente, detecção, idiomas, sem jogos). dados: DATABASE.md atualizado (ver Histórico).
- 2026-11-20: kit completo criado (especificação, DATABASE.md, API, eventos, regras, segurança, design system, skills, agentes, hooks). dados: modelo lógico inicial proposto.
