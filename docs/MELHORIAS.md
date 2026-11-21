# Melhorias identificadas (backlog vivo)

> Onde o Claude registra **tudo que percebe que pode melhorar** durante o trabalho: dívida técnica, risco de segurança, problema de UX, desempenho, teste faltando, ideia de produto, lacuna na especificação.
> Regras:
> - Registre na hora em que perceber, mesmo que não seja o foco da tarefa.
> - **Não implemente** sem aprovação do usuário, exceto correções triviais e óbvias dentro do que já está sendo feito.
> - Prioridade: `crítica` (segurança/dinheiro/dados — avise o usuário na hora), `alta`, `média`, `baixa`.
> - Revise esta lista no `/retro` de cada fase.

| ID | Data | Tipo | Prioridade | Descrição | Onde | Status |
| --- | --- | --- | --- | --- | --- | --- |
| M-001 | 2026-11-20 | produto | média | Avaliar migração do envelope de eventos de JSON para formato binário se o volume de eventos justificar (ADR 0005) | TRV01 | aberta |
| M-002 | 2026-11-20 | segurança | alta | Avaliar *certificate pinning* no app na Fase 12 | SEGURANCA §3 | aberta |
| M-003 | 2026-11-20 | produto | média | iOS após a Fase 13 (ADR 0004) | ROADMAP | aberta |
| M-004 | 2026-11-21 | segurança | média | Rotas `/__mock/*`: chave opcional por header (`x-mock-key` lida do ambiente) além do bind em 127.0.0.1 | revisor-seguranca Fase 0 | aberta |
| M-005 | 2026-11-21 | segurança | média | Checar `Origin` no upgrade do WebSocket (CSWSH) no backend real | revisor-seguranca Fase 0 | aberta |
| M-006 | 2026-11-21 | segurança | média | Headers de segurança no painel e no portal (CSP, frame-ancestors, HSTS, Referrer-Policy) antes de ter login | POR, ADM | aberta |
| M-007 | 2026-11-21 | segurança | baixa | CI: fixar actions de terceiros por SHA (`subosito/flutter-action`) | CI | aberta |
| M-008 | 2026-11-21 | segurança | média | Validador do tenant: recusar `androidPackage` placeholder (`com.seudominio.*`) e URLs `http` ao gerar build de release | TRV08 | aberta |
| M-009 | 2026-11-21 | produto | alta | Ligar `RealtimeClient.ended` (token inválido / sessão substituída) ao logout e ao aviso de outro aparelho | ENT19, Fase 1 | aberta |
| M-010 | 2026-11-21 | produto | média | Tela de atualização obrigatória com botão para a loja (link vindo da config) | ENT01, Fase 1 | aberta |
| M-011 | 2026-11-21 | ux | média | Skeleton de carregamento por tela (DESIGN-SYSTEM §4); hoje é indicador simples que respeita reduzir animações | DESIGN-SYSTEM | aberta |
| M-012 | 2026-11-21 | ux | média | AppTextField: obscureText, autofill, validação ao sair do campo, contador traduzido | ENT, Fase 1 | aberta |
| M-013 | 2026-11-21 | ux | média | AppDialog rolável com fonte grande, foco inicial em Cancelar quando destrutivo; AppBottomSheet com rolagem e altura máxima | DESIGN-SYSTEM | aberta |
| M-014 | 2026-11-21 | ux | média | Criar `PriceTag` e sheet de confirmação de dinheiro (preço, saldo antes e depois) antes da Fase 4 | ECO, PRE | aberta |
| M-015 | 2026-11-21 | ux | baixa | AppToast com variantes sucesso/erro com ícone e ação de fechar | DESIGN-SYSTEM | aberta |
| M-016 | 2026-11-21 | ux | baixa | Mover textos da vitrine de debug para ARB separado | TRV07 | aberta |
| M-017 | 2026-11-21 | qualidade | média | RealtimeClient: flag `_opening` para impedir dois sockets se `start()` e o retry se cruzarem | TRV01 | aberta |
| M-018 | 2026-11-21 | qualidade | baixa | Validar a resposta de `/v1/config` no painel/portal (hoje só `as`) | ADM, POR | aberta |
| M-019 | 2026-11-21 | qualidade | baixa | CI: rodar `push` só nas branches principais (evita execução dupla com PR) e cache de npm no job mobile | CI | aberta |
| M-020 | 2026-11-21 | qualidade | média | appId do Maestro gerado a partir do tenant (hoje fixo no fluxo) | E2E | aberta |
| M-021 | 2026-11-21 | produto | média | Ícone e splash do app por tenant (`tenants/<id>/assets`) gerados no flavor | TRV08 | aberta |
| M-022 | 2026-11-21 | qualidade | média | Fontes por tenant: hoje só Plus Jakarta Sans empacotada; trocar de fonte exige mudar o pubspec | TRV08 | aberta |
| M-023 | 2026-11-21 | qualidade | média | Teste de widget de contraste não pegou o texto branco no botão de perigo do tema escuro (só o print web pegou): investigar por que a cor lida no RenderParagraph difere da desenhada | DESIGN-SYSTEM | aberta |
| M-024 | 2026-11-21 | produto | baixa | `web/index.html` e `manifest.json` com nome e cor do tenant (hoje padrão do Flutter); só afeta o build web de teste | TRV08 | aberta |
| M-025 | 2026-11-21 | qualidade | média | E2E Android no CI com emulador (KVM do GitHub) para cobrir o que a web não cobre: flavor, permissões, vídeo nativo | E2E | aberta |
| M-026 | 2026-11-21 | segurança | média | Segredo do aparelho (aleatório, só hash no servidor, guardado no Keystore) exigido para reconhecer o `deviceId`; base para a sessão única | ENT19/RN-06, plano 1b | aberta |
| M-027 | 2026-11-21 | segurança | média | Rate limit por IP e teto de registros em `POST /devices` (backend real e mock) | ENT01 | aberta |
| M-028 | 2026-11-21 | segurança | baixa | Checar região e `Origin` na autenticação do WebSocket | ENT18, TRV01 | aberta |
| M-029 | 2026-11-21 | segurança | baixa | Guarda de CI: nenhuma menção a `X-Mock-*` fora de `mock-server/` | ENT18 | aberta |
| M-030 | 2026-11-21 | ux | alta | Botão "Atualizar" na atualização obrigatória com link da loja vindo da config/tenant | ENT01 | aberta |
| M-031 | 2026-11-21 | ux | média | Voltar com páginas empilhadas dentro de uma aba: hoje as abas não têm subpáginas; quando tiverem, voltar deve desempilhar antes de ir a Descobrir (Q-48) | NAV01 | aberta |
| M-032 | 2026-11-21 | ux | média | Componente `TenantBrand` (logo + nome) em `core/ui` usado no splash e nas boas-vindas | ENT01, ENT02 | aberta |
| M-033 | 2026-11-21 | ux | média | Rótulo de acessibilidade no contador de mensagens e tokens para o destaque da aba Ao vivo (tamanho/cor, contraste AA com a aba selecionada) | NAV01 | aberta |
| M-034 | 2026-11-21 | ux | baixa | Texto do "Entre para continuar" específico por origem (aba, seguir, presente) | ENT17 | aberta |
| M-035 | 2026-11-21 | ux | baixa | Prints do E2E em escuro, inglês e fonte 200% para as telas de entrada | E2E | aberta |
| M-036 | 2026-11-21 | ux | média | "Tentar de novo" nos portões mantém o portão até a resposta (hoje libera antes e pode piscar a Home) | ENT01, ENT18 | aberta |
