# Arquitetura

> Decisões vivas. Qualquer mudança aqui passa por uma ADR em `docs/adr/` (use `/adr`).
> Itens marcados **[DECIDIR]** estão em `docs/QUESTOES-ABERTAS.md` e não podem ser decididos pelo Claude sozinho.

## 1. Visão geral por fase

### Fase atual: app-first com servidor fake (ADR 0002, 0003, 0004)
```
[App Android Flutter] ──REST /v1──> [mock-server (Node, em memória)]
        │            ──WebSocket──>        │  dados semeados (fixtures)
        │                                  │  cenários: /__mock/* (forçar PK, presente, ban…)
        └── FakeVideoProvider (vídeo local de exemplo, câmera local na prévia)
[Painel Admin Next.js] ──REST /v1──> [mock-server]
[Portal do usuário Next.js] ──REST /v1──> [mock-server]   (saque, dados de recebimento, recarga, assinatura)
```

### Fase final
```
[App Flutter Android/iOS] ──REST /v1──> [Backend real] ──> Banco escolhido (a partir de docs/DATABASE.md)
        │                ──WebSocket──>        │       ──> Cache/fila (presença, placar, rate limit)
        │                                      ├──> Provedores: pagamentos (Play, Pix), SMS, push, verificação de idade
        └── AgoraVideoProvider ──> [Agora]  <──┘ tokens gerados pelo backend
[Painel Admin Next.js] ──REST /v1──> [Backend real] ──> Conectores de provedores configurados pelo comprador (ADR 0007)
[Portal do usuário Next.js] ──REST /v1──> [Backend real]
```

O app **não muda** entre as duas fases: só a URL da API e a implementação de `VideoProvider`. É isso que garante que todo o trabalho feito contra o mock-server vale para o produto real.

## 2. Princípios
1. **Servidor autoritativo.** Saldo, preço, conversão, pontuação de PK, permissões e flags vêm do servidor. O app só exibe e pede.
2. **Contrato primeiro.** Todo endpoint e evento é descrito em `docs/API.md` / `docs/EVENTOS-TEMPO-REAL.md` antes de existir no mock-server e no app. Todo dado persistente é descrito em `docs/DATABASE.md`.
3. **Comando por REST, estado por evento.** Ações do usuário vão por REST; mudanças de estado (chat, presentes, placar, moderação, saldo) chegam por WebSocket.
4. **Tudo que é de cliente fica fora do código** (`tenants/<id>/`): nome, cores, ícone, URLs, IDs públicos, flags iniciais.
5. **Provedores atrás de interfaces.** Vídeo, pagamentos, push, SMS, verificação de idade e analytics têm interface própria com implementação fake e real.
6. **Configurável pelo comprador.** Valores de negócio, limites, provedores e flags são editáveis no painel admin, sem nova versão do app nem do servidor.
7. **O usuário nunca sai do vídeo.** Fluxos secundários da live (presentes, perfil, convites, compra) são *bottom sheets* e overlays.

## 3. Repositório (monorepo)
```
apps/mobile/        App Flutter (Android agora, iOS depois)
apps/admin/         Painel web do comprador (Next.js + TypeScript)
apps/portal/        Portal web do usuário final: saque, dados de recebimento, recarga, assinatura de criador (Next.js, ADR 0008)
mock-server/        Servidor fake local (Node + TypeScript), descartável
backend/            Backend real (criado só na fase do banco)
packages/contracts/ (opcional) tipos gerados a partir de docs/API.md e EVENTOS
tenants/<id>/       Configuração white-label por cliente
docs/               Especificação, dados, contratos, decisões, progresso
```

## 4. App mobile (`apps/mobile/`)
- **Flutter estável mais recente**, Dart com análise estrita (`flutter_lints` + regras extras).
- **Arquitetura por feature em camadas:**
  ```
  lib/
    core/        tema, rotas, http, tempo real, video, flags, i18n, erros, analytics
    features/<feature>/
      presentation/   telas, widgets, bottom sheets
      application/    estado (controllers/notifiers)
      domain/         entidades e regras puras (sem Flutter)
      data/           repositórios, DTOs, fontes (api, tempo real, cache)
  ```
- **Estado:** Riverpod. **Rotas:** go_router (deep links). **HTTP:** dio com interceptors (auth, refresh, idempotência, erros). **Modelos:** freezed + json_serializable. **Tempo real:** cliente WebSocket próprio em `core/realtime` com reconexão exponencial, heartbeat e re-inscrição em salas. **Animações:** Lottie e vídeo para presentes. **Armazenamento local:** flutter_secure_storage para tokens; cache leve para catálogo de presentes e config.
- **Idiomas:** pt-BR e inglês com arquivos de tradução (ARB); layout com `Directionality`/`EdgeInsetsDirectional` para estar pronto para RTL.
- **Sessão:** um aparelho por conta (ADR 0009); tratar `session.replaced` e `sessao_substituida` levando ao login com aviso.
- **Detecção no aparelho:** `DetectionProvider` em `core/detection` (rosto/corpo e conteúdo durante a live; fake agora, modelo no aparelho depois) que reporta ao servidor; o servidor decide a ação (ADR 0010).
- **Flavors** gerados a partir de `tenants/<id>/tenant.json` (nome, applicationId, ícone, cores, URL da API).
- **Repositórios:** cada feature define uma interface em `domain` e uma implementação em `data` que chama a API. Não existe "repositório fake" no app: o fake é o mock-server. Assim o app exercita HTTP, erros e tempo real reais desde o início.
- **Testes:** unitários (domain/application), widget (presentation), golden opcional, E2E com Maestro (`apps/mobile/e2e/`).

## 5. Vídeo: `VideoProvider` (ADR 0003)
Interface única em `lib/core/video/`:
- `joinAsHost`, `joinAsAudience`, `leave`, `switchCamera`, `setMic`, `setCamera`, `startRelay` (PK), `stopRelay`, streams de estado (conectado, qualidade, participante entrou/saiu).
- **Agora:** `FakeVideoProvider` mostra a câmera local na prévia do host e um vídeo de exemplo em loop para o espectador; simula entrada/saída de convidados e PK (tela dividida com dois vídeos de exemplo). Os eventos de estado são os mesmos que o provedor real emitirá.
- **Depois:** `AgoraVideoProvider` (único lugar que importa o SDK da Agora). Tokens RTC/sinalização sempre vindos do backend.
- Filtros de beleza: beleza básica da Agora (Q-10). Interface `BeautyProvider` com fake no-op até a Fase 12.

## 6. Tempo real (ADR 0005)
- Um WebSocket por sessão do app, autenticado por token.
- Envelope versionado: `{ "v": 1, "id": "...", "type": "dominio.evento", "ts": "ISO-8601", "data": { ... } }`.
- Cliente → servidor: `auth`, `ping`, `room.join`, `room.leave`, `presence.watch`, `presence.unwatch`. Todo o resto é REST.
- Catálogo completo em `docs/EVENTOS-TEMPO-REAL.md`. Evento desconhecido é ignorado com log (compatibilidade para frente).
- O servidor pode **empurrar estado de UI** (ex.: oferta, banner, aviso de moderação) por evento, para mudar comportamento sem nova versão.

## 7. mock-server (`mock-server/`)
- Node + TypeScript, Fastify para REST e `ws` para WebSocket, dados **em memória** semeados a partir de `mock-server/fixtures/` (usuários, lives, presentes, conversas realistas em pt-BR).
- Implementa **exatamente** `docs/API.md` e `docs/EVENTOS-TEMPO-REAL.md`, incluindo erros, paginação e idempotência.
- **Simuladores:** bots que conversam, entram, seguem e mandam presentes em lives de exemplo; PK simulada; chamadas simuladas.
- **Rotas de cenário** `/__mock/*` (só no mock) para forçar situações em testes: saldo zero, PK recebida, banimento, live encerrada pelo admin, falha de pagamento, latência, erro 500.
- Aplica as regras de negócio de `docs/REGRAS-DE-NEGOCIO.md` de forma simples (incluindo o ledger em memória), para o app ser testado contra o comportamento correto.
- É descartável: quando o backend real existir, o mock-server continua só para testes E2E e desenvolvimento offline.

## 8. Economia (o coração do faturamento)
- **Moedas** (compradas pelo usuário) → **presentes** → **diamantes** (ganhos do streamer) → **saque** em reais via Pix.
- **Ledger de dupla entrada:** todo movimento gera lançamentos de débito e crédito entre contas (carteira de moedas do usuário, carteira de diamantes do streamer, conta de receita da plataforma, conta da agência, conta de reembolso etc.). Saldos são derivados do ledger.
- Valores sempre **inteiros**. Toda operação com **chave de idempotência**, transação e bloqueio de linha (no backend real). O mock-server reproduz idempotência e validação de saldo.
- Taxas, conversões, mínimos e limites ficam em configuração editável pelo painel (`ConfigEconomia` no DATABASE.md). Valores iniciais em `docs/REGRAS-DE-NEGOCIO.md`, todos configuráveis pelo comprador (ADR 0007).

## 9. Portal web do usuário (`apps/portal/`, ADR 0008)
- Next.js + TypeScript, responsivo para celular, marca do tenant, pt-BR e inglês.
- Entrada a partir do app por link de uso único e curta duração (`POST /portal/links`), ou por login normal.
- Páginas: saque, dados de recebimento, recarga de moedas, checkout e gestão de assinatura de criador, ganhos e comprovantes.
- Pagamentos e repasses pelo provedor configurado pelo comprador; confirmações por webhook no servidor, nunca pelo navegador.

## 10. Painel admin (`apps/admin/`)
- Next.js (App Router) + TypeScript, componentes acessíveis, tabelas com filtros/paginação/exportação CSV.
- Papéis: admin, moderador, financeiro, suporte (RBAC no servidor).
- Consome a mesma API com escopo `/v1/admin/*`. 2FA obrigatório para admin e financeiro.
- Tudo que é configurável pelo comprador mora aqui: economia, progressão, VIP, diretrizes e detecção, flags e **Integrações e provedores** (ADM19).

## 11. Backend real (fase futura)
- Linguagem/framework: **Node.js + TypeScript (NestJS)** como base sugerida. **[DECIDIR Q-26]** antes da fase do banco.
- Banco: **[DECIDIR Q-27]** (o usuário vai escolher). O `docs/DATABASE.md` é escrito de forma independente de banco, com notas para relacional.
- Tudo o que o mock-server faz em memória vira serviço real; os contratos não mudam.

## 12. Integrações e conectores (ADR 0007)
No servidor, cada tipo de provedor tem uma **interface de conector**; o comprador escolhe a implementação e grava as credenciais no painel (criptografadas). O mock-server tem conectores fake para todos. O app só conhece interfaces e nunca recebe segredos.
| Integração | Interface | Fake agora | Real depois |
| --- | --- | --- | --- |
| Vídeo ao vivo | `VideoProvider` | vídeo de exemplo | Agora |
| Beleza/filtros | `BeautyProvider` | sem efeito | beleza básica da Agora |
| Pagamento na loja | `StorePurchaseProvider` | compra simulada no mock | Google Play Billing + faturamento alternativo (Q-37) |
| Recarga, assinatura e saque | conector `pagamento_web` / `repasse_saque` | simulado no mock | escolhido pelo comprador (Q-38) |
| SMS / WhatsApp OTP | conector `sms_whatsapp` | código fixo no mock | escolhido pelo comprador |
| Login Google | `SocialAuthProvider` | conta de teste | Google Sign-In |
| Sinal de idade da loja | `StoreAgeSignalProvider` | faixa fixa por cenário | Play Age Signals |
| Verificação forte de idade | conector `verificacao_idade` (liga/desliga) | aprovar/reprovar por cenário | escolhido pelo comprador; padrão Yoti (Q-35) |
| Detecção na live | `DetectionProvider` | eventos por cenário | modelo no aparelho (Fase 12) |
| Moderação de mídia | conector `moderacao_midia` | aprova tudo / cenário | o mais acessível (Q-39) |
| Anti-bot | conector `antibot` | sempre passa | App Check, reCAPTCHA Enterprise, Turnstile por flag |
| Push | `PushProvider` | evento local | Firebase Cloud Messaging |
| Analytics / crash | `AnalyticsProvider` | log no console | Firebase Analytics + Crashlytics |
| Tradução de mensagens | conector `traducao` | tradução fake | gratuito (Q-40) |

No mock-server: interfaces em `mock-server/src/connectors/types.ts`, fakes em `fakes.ts` e escolha por `IntegracaoProvedor` em `registry.ts`. Contrato detalhado já existe para `sms_whatsapp` (`sendCode`) e `verificacao_idade` (`startSession`, `getResult`); os demais têm só `testConnection` até a feature dona chegar.

## 13. Segurança e conformidade
Detalhado em `docs/SEGURANCA.md`. Resumo: tokens curtos + refresh rotativo, segredos só no servidor, rate limit, validação de toda entrada, ledger auditável, verificação de idade confiável (ECA Digital), LGPD (exportar/excluir), moderação em tempo real, logs de auditoria no painel.

## 14. Qualidade
- Definição de pronto em `docs/ESPECIFICACAO.md`.
- Testes obrigatórios por camada (seção 4) e testes de contrato no mock-server (cada endpoint de `docs/API.md` tem teste).
- CI: lint, análise, testes e build do APK de debug a cada push.
