# Progresso

> Atualizado pelo Claude ao fim de **toda** tarefa. Curto: o estado atual, não um diário.
> Inclua sempre uma linha `dados:` dizendo se a tarefa mexeu no modelo de dados (e o que foi atualizado no DATABASE.md) ou `dados: sem impacto`.

## Estado atual
Plano 1b (login, senha, termos, sessão única, anti-bot) implementado e revisado (segurança, código, UX, dados). Correções aplicadas: sessão não cai por erro passageiro ao abrir, termos pendentes com o app aberto levam aos termos, código usa os tempos do servidor, anti-bot por flag (RN-85), diretrizes obrigatórias (Q-55), testes de tela e casos de erro nos E2E. Testes: mock 84, app 160, E2E web 97/97. ENT04, ENT06 e SEG06 ficam `[~]` por decisões registradas (Q-51, Q-52/Q-53, provedores reais na Fase 12). Verificação final de ENT01, ENT05, ENT07, ENT16, ENT17 e ENT19 em andamento.

## Próximo passo
Aplicar o veredito do verificador na especificação; depois `/retro` curto da etapa (propor a regra M-045) e `/planejar` do plano 1c (cadastro ENT08–ENT15, idioma CFG14).

## Problemas conhecidos / dívidas técnicas
- Sessão da nuvem sem Android SDK nem aparelho: APK só no CI (confirmado: run 12 verde, artefato `liveapp-debug-apk`), Maestro só na máquina do usuário (`tools/dev/setup-linux.sh` e `tools/dev/e2e-emulador.sh`).
- Em release, a tela inicial fica vazia depois de carregar a config (as telas de produto chegam na ENT01).
- Ver `docs/MELHORIAS.md` (M-037 a M-051 vieram das revisões do plano 1b).

## Últimas sessões (manter só as 5 mais recentes)
- 2026-11-21: plano 1b passo 13 (revisões, correções, Q-55). dados: DATABASE.md — CadastroPendente, AvisoConta, ConfigAuth, controles efêmeros de autenticação, CodigoVerificacao/Sessao/Dispositivo/AceiteTermos alinhados, TokensLocais com chaves reais; API.md com erros de cada rota de auth, `/devices`, cenários e `/__mock/ping-autenticado`; signup devolve tempos do código.
- 2026-11-21: plano 1b passos 1–12; ADR 0012; Q-54. dados: DATABASE.md — MetodoLogin, CodigoVerificacao, Sessao, AceiteTermos, Usuario (parcial) em uso no mock; Dispositivo.segredo_hash; TokensLocais no app (ver Histórico).
- 2026-11-21: Fase 1a concluída (revisões + verificador); E2E web ganhou casos de erro e espera por texto; script de E2E encerra o grupo de processos. dados: API.md com cenário `entrada-desligada` e CORS do mock.
- 2026-11-21: Fase 1a passos 1–7. dados: DATABASE.md atualizado — Dispositivo em uso no mock (id gerado pelo servidor), PreferenciasLocais no app, `region` calculado por requisição (ver Histórico).
- 2026-11-21: auditoria final da Fase 0; bug do portão de versão mínima corrigido (o app não comparava `minAppVersion`); regra nova no CLAUDE.md (trocar de abordagem após 2 falhas); Q-44 a Q-47; plano 1a. dados: sem impacto.
