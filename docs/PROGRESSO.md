# Progresso

> Atualizado pelo Claude ao fim de **toda** tarefa. Curto: o estado atual, não um diário.
> Inclua sempre uma linha `dados:` dizendo se a tarefa mexeu no modelo de dados (e o que foi atualizado no DATABASE.md) ou `dados: sem impacto`.

## Estado atual
Plano 1b concluído (login, senha, termos, sessão única, anti-bot), com revisões de segurança, código, UX e dados e duas rodadas do verificador. Prontos `[x]`: ENT01, ENT05, ENT07, ENT16, ENT17, ENT19 (além de ENT18 e TRV01/04/07). Em andamento por decisão registrada: ENT04 (Q-51, SMS real na Fase 12), ENT06 (cadastro no 1c, Google real na Fase 12), SEG06 (provedores reais na Fase 12). Testes: mock 84, app 162, E2E web 102/102.

## Próximo passo
`/retro` curto da etapa (propor a regra M-045: conferir edição por script e `pipefail`) e depois `/planejar` do plano 1c (cadastro ENT08–ENT15, idioma CFG14).

## Problemas conhecidos / dívidas técnicas
- Sessão da nuvem sem Android SDK nem aparelho: APK só no CI (confirmado: run 12 verde, artefato `liveapp-debug-apk`), Maestro só na máquina do usuário (`tools/dev/setup-linux.sh` e `tools/dev/e2e-emulador.sh`).
- Em release, a tela inicial fica vazia depois de carregar a config (as telas de produto chegam na ENT01).
- Ver `docs/MELHORIAS.md` (M-037 a M-051 vieram das revisões do plano 1b).

## Últimas sessões (manter só as 5 mais recentes)
- 2026-11-21: retro do plano 1b aprovada: regra de edição por script e `pipefail` (CLAUDE.md), `/implementar` confere testes do plano e roda o verificador antes das revisões, DATABASE.md no mesmo commit, `/planejar` caça ambiguidade, E2E um fluxo por arquivo. dados: sem impacto.
- 2026-11-21: plano 1b concluído: passo 13 (revisões, correções, Q-55, verificador: ENT01/05/07/16/17/19 prontos). dados: DATABASE.md — CadastroPendente, AvisoConta, ConfigAuth, controles efêmeros de autenticação, CodigoVerificacao/Sessao/Dispositivo/AceiteTermos alinhados, TokensLocais com chaves reais; API.md com erros de cada rota de auth, `/devices`, cenários e `/__mock/ping-autenticado`; signup devolve tempos do código.
- 2026-11-21: plano 1b passos 1–12; ADR 0012; Q-54. dados: DATABASE.md — MetodoLogin, CodigoVerificacao, Sessao, AceiteTermos, Usuario (parcial) em uso no mock; Dispositivo.segredo_hash; TokensLocais no app (ver Histórico).
- 2026-11-21: Fase 1a concluída (revisões + verificador); E2E web ganhou casos de erro e espera por texto; script de E2E encerra o grupo de processos. dados: API.md com cenário `entrada-desligada` e CORS do mock.
- 2026-11-21: Fase 1a passos 1–7. dados: DATABASE.md atualizado — Dispositivo em uso no mock (id gerado pelo servidor), PreferenciasLocais no app, `region` calculado por requisição (ver Histórico).
