---
paths:
  - "apps/mobile/**/*"
---

# Regras do app Flutter (Android primeiro)

## Estrutura
- `lib/core/` (tema, ui, rotas, http, realtime, video, flags, i18n, erros, analytics) e `lib/features/<feature>/{presentation,application,domain,data}`.
- `domain` é Dart puro (sem Flutter, sem dio, sem JSON). `data` converte DTO ↔ entidade.
- Riverpod para estado, go_router para rotas e deep links, dio para HTTP, freezed + json_serializable para modelos, cliente próprio de tempo real em `core/realtime`.
- Antes de adicionar um pacote: confira se é mantido, compatível com a versão do Flutter, e se já não existe um no projeto que faça o mesmo. Pacote novo relevante → pergunte.

## Comportamento
- Toda tela trata: carregando, vazio, erro, sem conexão e sem permissão (componentes `StateViews`).
- O app nunca calcula preço, saldo, pontos ou permissão: exibe o que o servidor manda e reage a eventos.
- Operações de valor enviam `Idempotency-Key` e mostram confirmação com preço e saldo antes (`PriceTag`).
- Erros da API são traduzidos por `error.code` para textos em pt-BR (arquivo de tradução), nunca exibir `message` técnico.
- Na live, fluxos secundários abrem em `AppBottomSheet`/overlay; nada tira o usuário do vídeo.
- Vídeo só via `VideoProvider` (`lib/core/video/`). O SDK de vídeo real só pode ser importado em `lib/core/video/providers/agora/`.
- Marca, cores, nome e URLs vêm do flavor/tenant. Nenhuma string de marca no código.
- Textos de interface sempre em arquivo de tradução pt-BR.
- Widgets com `Key`/`Semantics` estáveis para o Maestro e para leitor de tela.

## Qualidade
- `flutter analyze` sem avisos. Sem `dynamic` desnecessário, sem `!` sem justificativa.
- Testes: unitário para `domain`/`application`, widget para telas, E2E Maestro por item de tela.
- Antes de terminar: `flutter analyze && flutter test`.
