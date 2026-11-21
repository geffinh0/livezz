# Design system

> Identidade **própria**: nada de cores, fontes, ícones ou layouts do concorrente (ver `docs/referencias/LEIA-ANTES.md`).
> A identidade visual do demo `liveapp` foi decidida na **Q-42** (2026-11-20). Todos os tokens vêm do tenant, então trocar a marca não exige mexer em telas.

## 1. Princípios
1. **O vídeo é o palco.** Na live, tudo que não é vídeo é overlay ou bottom sheet; nada empurra o usuário para fora da transmissão.
2. **Valor sempre visível.** Antes de qualquer gasto, o usuário vê preço, saldo e o que vai acontecer. Nada de cobrança surpresa.
3. **Feedback imediato.** Toda ação responde em até 100 ms (otimista quando seguro, com reversão em erro).
4. **Uma forma de fazer cada coisa.** Um componente de bottom sheet, um de botão, um de diálogo. Sem variações soltas.
5. **Gamificação transparente.** Níveis, metas e rankings explicam como funcionam.
6. **Acessível por padrão.** Contraste AA, alvo de toque ≥ 48dp, rótulos para leitor de tela, respeito a "reduzir animações".

## 2. Tokens (provisórios, sobrescritos pelo `tenant.json`)
| Token | Valor provisório | Uso |
| --- | --- | --- |
| color.primary | do tenant (`liveapp`: `#E91E8C`) | marca, destaques, ícones ativos |
| color.primaryAction / onPrimaryAction | do tenant (`liveapp`: `#D6157E` / `#FFFFFF`, 4,92:1) | fundo de botões e chips com texto (garante AA) |
| color.secondary / onSecondary | do tenant (`liveapp`: `#FF9100` / `#0E0E12`, 8,5:1) | apoio; texto sobre a secundária é sempre escuro |
| color.background | #0E0E12 | fundo escuro padrão |
| color.surface | #1A1A22 | cards, sheets |
| color.onSurface | #FFFFFF / 87% | texto |
| color.muted | 60% | texto secundário |
| color.success / warning / danger | verde / âmbar / vermelho acessíveis | estados |
| color.coin / color.diamond | dourado / azul | economia (sempre com ícone, nunca só cor) |
| font.family | do tenant (`liveapp`: Plus Jakarta Sans, Q-42) | todo o app |
| font.scale | 12 / 14 / 16 / 20 / 24 / 32 | escalas de texto |
| space | 4, 8, 12, 16, 24, 32 | espaçamentos |
| radius | 8 (campos), 16 (cards), 24 (sheets), círculo (avatar) | cantos |
| motion.fast / normal | 150 ms / 250 ms | animações de interface |
| elevation | 0, 1, 2 | sombras discretas |

Tema claro e escuro (CFG08). Na live, sempre texto claro sobre gradiente escuro para legibilidade em cima do vídeo.

## 3. Componentes base (`lib/core/ui/`)
| Componente | Regras |
| --- | --- |
| AppButton | primário, secundário, texto, perigo; estados carregando e desabilitado |
| AppBottomSheet | padrão para fluxos dentro da live; arrastar para fechar; altura adaptável |
| AppDialog | confirmações (sempre com ação destrutiva destacada) |
| AppTextField | rótulo, ajuda, erro, contador |
| AppDateField | campo de data que abre o seletor do sistema (aceita digitar); data no idioma do app; ajuda e erro no campo; leitor de tela lê rótulo + valor |
| AppChoiceChips | escolha múltipla em chips; selecionado com ícone de check (não só cor); limite opcional desliga o resto; alvo ≥ 48dp |
| Avatar | tamanhos fixos; moldura de item/VIP; indicador ao vivo/online |
| LiveCard | capa, título, host, espectadores, selos |
| PriceTag | ícone de moeda/diamante + valor formatado (pt-BR) |
| LevelBadge / VipBadge | nível e VIP com cor e número (não só cor) |
| GiftAnimationLayer | fila de animações; Lottie/vídeo; nunca bloqueia toques no chat |
| ChatOverlay | lista de mensagens sobre o vídeo; rolagem inteligente |
| StateViews | carregando (skeleton), vazio (com ação), erro (tentar de novo), sem conexão, sem permissão |
| Toast / Snackbar | feedback curto; ganho de XP/nível |
| CountdownTimer | convites, PK, reembolso |
| ScoreBar | barra de placar de PK animada |

## 4. Padrões de tela
- Listas: pull-to-refresh, paginação infinita, skeleton no primeiro carregamento.
- Formulários: validação ao sair do campo e ao enviar; botão principal sempre visível acima do teclado.
- Fluxos de dinheiro: tela/sheet de confirmação com preço, saldo depois da ação e aviso de reembolso quando houver.
- Erros: texto humano em pt-BR por `code` da API; nunca mostrar mensagem técnica.

## 5. Ícones e ilustrações
Conjunto de ícones único: **Material Symbols** (Q-42), no app (Flutter) e no painel/portal (fonte Material Symbols para web). Animações de presentes produzidas ou licenciadas pelo cliente (nunca extraídas de outros apps).

## 6. Idiomas, direção e temas (decisões de 2026-11-20)
- Tema **claro e escuro** (e "seguir o sistema") em todos os componentes; na live, o overlay continua escuro para legibilidade sobre o vídeo.
- **Português e inglês**; componentes testados com os dois idiomas.
- **Pronto para RTL:** só propriedades direcionais (`start`/`end`), ícones de direção espelháveis, nada de `left`/`right` fixos.
- Cores e fonte do tenant demo `liveapp`: decididas na Q-42 (2026-11-20). Regra: texto branco nunca sobre `color.primary` puro em texto pequeno; usar `color.primaryAction`.
