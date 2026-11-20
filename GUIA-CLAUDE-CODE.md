# Guia: como usar o kit com o Claude Code

> Versão em PDF: `GUIA-KIT-LIVESTREAM.pdf`. Este arquivo é a versão em texto, que fica junto do projeto.

## O que é o kit
Uma pasta que transforma o Claude Code no desenvolvedor líder do seu app de lives:
- **Documentos** que dizem o que construir (`docs/ESPECIFICACAO.md`, 226 itens), como (`docs/ARQUITETURA.md`), em que ordem (`docs/ROADMAP.md`), com quais regras (`docs/REGRAS-DE-NEGOCIO.md`), com que segurança (`docs/SEGURANCA.md`) e com que visual (`docs/DESIGN-SYSTEM.md`).
- **Memória de dados** (`docs/DATABASE.md`), **contratos** (`docs/API.md`, `docs/EVENTOS-TEMPO-REAL.md`) e **decisões** (`docs/adr/`, `docs/QUESTOES-ABERTAS.md`).
- **Configuração do Claude Code** (`CLAUDE.md` e `.claude/`): regras por pasta, 13 comandos, 7 especialistas e automações de início de sessão, fim de tarefa e edição de arquivos.

## 1. Preparar o computador (uma vez)
Instale e confira cada um com o comando de versão:
| Ferramenta | Para quê | Conferir |
| --- | --- | --- |
| Git | Histórico e segurança do código | `git --version` |
| Claude Code | O desenvolvedor | `claude --version` |
| Flutter (estável) + Android Studio/SDK | O app Android | `flutter doctor` |
| Node.js LTS | mock-server, painel e portal | `node --version` |
| jq | Usado pelas automações | `jq --version` |
| Maestro CLI | Testes que clicam nas telas | `maestro --version` |
| Um celular Android com depuração USB ou um emulador | Rodar o app | `flutter devices` |

Instalar o Claude Code (Linux, macOS ou WSL): `curl -fsSL https://claude.ai/install.sh | bash`. No Windows (PowerShell): `irm https://claude.ai/install.ps1 | iex`. Precisa de uma assinatura do Claude (Pro, Max, Team ou Enterprise) ou conta no Console.
Não sabe instalar algo? Na primeira sessão, o `/comecar` confere o ambiente e explica o que falta.

## 2. Montar o projeto (uma vez)
1. Crie a pasta do projeto e descompacte o kit dentro dela (a pasta `.claude/` é oculta: confira se veio junto).
2. No terminal, dentro da pasta: `git init`, `git add -A`, `git commit -m "chore: kit inicial"`.
3. Abra o Claude Code: `claude`.
4. Confira: `/memory` deve listar o `CLAUDE.md`; `/hooks` deve mostrar SessionStart, PostToolUse e Stop; `/agents` deve listar os 7 especialistas. Na primeira vez, o Claude Code pode pedir para você confiar na pasta e aprovar os hooks: aprove.

## 3. A primeira sessão
Digite: **"comece a fazer o aplicativo"** (ou `/comecar`). O Claude vai:
1. ler tudo e ver que não há código ainda;
2. conferir o que está instalado na sua máquina;
3. perguntar o que bloqueia a Fase 0 (principalmente cores e fonte do tenant `liveapp`, Q-42);
4. propor o plano da Fase 0 (fundação: monorepo, app Flutter, mock-server, design system base, testes).
Leia o plano em `docs/planos/`, peça ajustes e só então aprove.

## 4. O ciclo de trabalho (sempre o mesmo)
1. **`/comecar`** (ou "continua"): ele diz onde parou e o que propõe agora.
2. **Responder perguntas**: ele pergunta tudo que não está decidido. Responder bem aqui evita retrabalho.
3. **`/planejar`**: plano escrito, revisado pelo arquiteto. Você aprova.
4. **`/implementar`**: passo a passo, teste primeiro, um commit por passo. Ao final, revisores e QA conferem e ele só marca como pronto o que provou.
5. **Testar você mesmo** no celular, seguindo o roteiro que ele entrega no fim.
6. **`/clear`** antes do próximo assunto. A automação de início de sessão devolve o contexto do projeto.

No fim de cada fase: **`/auditar`** → **`/retro`** → merge da branch → próxima fase.

## 5. Todos os comandos
| Comando | Quando usar |
| --- | --- |
| `/comecar` | Início de toda sessão, ou "o que eu faço agora?" |
| `/status` | Ver o placar do projeto rapidamente |
| `/decidir` | Responder questões abertas em rodadas |
| `/planejar <IDs>` | Antes de construir qualquer coisa |
| `/implementar <plano>` | Construir um plano aprovado |
| `/revisar` | Revisão completa antes de juntar na `main` |
| `/corrigir-bug <descrição>` | Algo quebrou |
| `/auditar [módulo]` | Conferir de verdade o que está pronto |
| `/sincronizar-dados` | Garantir que DATABASE/API/EVENTOS batem com o código |
| `/melhorias [área]` | Procurar o que melhorar e organizar o backlog |
| `/adr <decisão>` | Registrar decisão de arquitetura |
| `/retro <fase>` | Fim de fase: aprender e evoluir o próprio kit |
| `/preparar-banco` | Fase 11: escolher o banco e gerar o schema |

## 6. Como ele se mantém atualizado e se autoverifica
| Mecanismo | O que faz |
| --- | --- |
| `CLAUDE.md` | Papel, regras invioláveis, quando perguntar, o que atualizar ao fim de cada tarefa |
| Regras por pasta (`.claude/rules/`) | Carregam sozinhas: app, mock-server, painel, portal, backend, dinheiro, dados, segurança, E2E, design, referências |
| Início de sessão (hook) | Injeta progresso, placar por módulo, plano atual, questões abertas, melhorias críticas e git |
| Antes de terminar (hook) | Roda lint e testes da parte alterada; bloqueia se falhar, se o progresso não foi atualizado ou se dados mudaram sem atualizar o DATABASE.md |
| Ao editar arquivo (hooks) | Bloqueia segredos (chaves, certificados) e formata o código |
| Especialistas (`.claude/agents/`) | arquiteto, revisor, revisor-seguranca, revisor-ux, guardiao-dados, verificador-spec, pesquisador |
| `docs/MELHORIAS.md` | Tudo que ele percebe que pode melhorar fica registrado |
| `/retro` | Ele propõe mudanças no próprio kit; você aprova |

## 7. O DATABASE.md (o banco antes do banco)
- Toda vez que o app ou o mock-server passa a guardar ou ler um dado, a entidade é registrada/atualizada no `docs/DATABASE.md`, com campos, tipos, dados pessoais marcados 🔒, quais telas usam e um histórico.
- A automação de fim de tarefa cobra isso.
- Na Fase 11, `/preparar-banco` mostra opções de banco com prós, contras e custo, você escolhe, e o schema é gerado a partir desse documento. Nada que o app usa fica de fora.

## 8. Suas responsabilidades
- Responder as perguntas (`docs/QUESTOES-ABERTAS.md` tem 11 abertas hoje, quase todas de pesquisa, jurídico ou da Fase 11). Ele usa valores provisórios configuráveis enquanto você não decide, mas nunca decide sozinho.
- Ler e aprovar planos. Testar no celular.
- Validar com advogado o que tem trava jurídica (ADR 0006) e a proteção de menores (ECA Digital) antes de publicar.
- Fazer backup do repositório (por exemplo, um repositório privado no GitHub).

## 9. Problemas comuns
| Problema | Solução |
| --- | --- |
| Ele "esqueceu" algo depois de muito tempo de conversa | `/clear` e `/comecar`. Sessões curtas, um assunto por vez. |
| O hook de fim bloqueou | Leia o motivo: ele mesmo corrige. Se repetir várias vezes, peça para explicar o erro. |
| Testes demoram no fim de cada tarefa | Normal: é a garantia de qualidade. |
| Ele quer decidir algo que é seu | Diga "isso é decisão minha, me pergunte com opções". Se repetir, peça para virar regra no `/retro`. |
| Mudou de ideia sobre uma funcionalidade | Diga a mudança; ele atualiza ESPECIFICACAO, REGRAS e DATABASE antes do código. |
| `jq` não encontrado | Instale o jq; as automações dependem dele. |

## 10. Ordem das fases
0 Fundação · 1 Entrada e conta · 2 Descoberta e perfil · 3 Live com vídeo simulado · 4 Economia e presentes · 5 PK e convidados · 6 Mensagens, feed e chamadas · 7 VIP, assinaturas, famílias, agências, estatísticas · 8 Configurações, suporte e segurança · 9 Painel admin e portal do usuário · 10 Revisão completa · 11 Banco e backend real · 12 Integrações reais e conectores configuráveis (Agora, Play, pagamentos, SMS, push, verificação de idade) · 13 Pronto para vender · depois: iOS.
