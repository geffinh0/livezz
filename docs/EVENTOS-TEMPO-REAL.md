# Eventos em tempo real (WebSocket)

> Contrato do canal de eventos (ADR 0005). Evento novo ou alterado é escrito aqui **antes** de ser implementado.
> Status: `proposto` · `no mock` · `no backend`.

## Conexão
- URL: `{apiBaseUrl}/v1/realtime` (troca para `wss`).
- Primeira mensagem do cliente: `auth` com o access token. Sem `auth` em 5 s → servidor fecha.
- Heartbeat: cliente envia `ping` a cada 25 s; servidor responde `pong`. Sem resposta em 10 s → reconectar.
- Reconexão exponencial (1 s, 2 s, 4 s… até 30 s, com variação aleatória). Ao reconectar, o cliente reentra nas salas e busca o estado atual por REST (`GET /lives/{id}`) para não depender de eventos perdidos.
- Uma conexão por conta e um aparelho por conta (RN-06). Login em outro aparelho: a conexão antiga recebe `session.replaced` e é fechada.

## Envelope
```json
{ "v": 1, "id": "01J...", "type": "live.gift.sent", "ts": "2026-11-20T22:10:00Z", "data": { } }
```
- `id` único (deduplicação no cliente). `type` em `dominio.evento`. O cliente **ignora** tipos desconhecidos e versões maiores que a suportada (com log).

## Cliente → servidor
| type | data | Descrição |
| --- | --- | --- |
| auth | `{ token }` | Autenticar a conexão |
| ping | `{}` | Manter viva |
| room.join | `{ room: "live:{id}" \| "pk:{id}" \| "call:{id}" \| "conversation:{id}" }` | Entrar numa sala |
| room.leave | `{ room }` | Sair da sala |
| presence.watch / presence.unwatch | `{ userIds: [] }` | Acompanhar online de usuários |

Respostas: `ack` `{ refId, ok, error? }` (`refId` = `id` do envelope enviado pelo cliente; `error` usa os códigos do catálogo da API). Status das mensagens do cliente: `auth`, `ping`, `room.join`, `room.leave` **no mock**; `presence.*` proposto.

## Servidor → cliente

### Sessão e sistema
| type | data (resumo) | Usado por | Status |
| --- | --- | --- | --- |
| pong | `{}` | TRV01 | no mock |
| ack | `{ refId, ok, error }` | TRV01 | no mock |
| session.invalid | `{ reason: "token_expirado" \| "token_invalido" \| "revogada" \| "senha_trocada" \| "expirada" \| "conta_bloqueada" }` | ENT19 | no mock |
| session.replaced | `{ at }` (a conta entrou em outro aparelho) | ENT19 | no mock |
| config.updated | `{ partial config }` | TRV04 | no mock |
| account.sanctioned | `{ type, until, reason }` | SEG03 | proposto |
| age.verification.updated | `{ status }` | ENT09 | proposto |
| notification.new | `{ notification }` | DES08 | proposto |
| unread.updated | `{ messages, notifications }` | NAV01 | proposto |
| ui.offer | `{ offerId, placement, payload }` | ECO04, NAV03 | proposto |
| ui.banner | `{ banner }` | NAV03 | proposto |
| presence.changed | `{ userId, online, lastSeenAt }` | MSG11 | proposto |

### Live (sala `live:{id}`)
| type | data (resumo) | Usado por | Status |
| --- | --- | --- | --- |
| live.state | estado completo (enviado ao entrar) | ASS01, TRA04 | proposto |
| live.updated | `{ title?, type?, goal? }` | TRA09, ASS15 | proposto |
| live.viewers.updated | `{ count, topViewers }` | ASS01, ASS06 | proposto |
| live.viewer.joined | `{ user, entryEffect? }` | ASS14 | proposto |
| live.chat.message | `{ message }` | ASS02 | proposto |
| live.chat.removed | `{ messageId }` | SEG04 | proposto |
| live.likes | `{ total, burst }` | ASS04 | proposto |
| live.followed | `{ user }` | ASS05 | proposto |
| live.host.paused / live.host.resumed | `{}` | TRA05 | proposto |
| live.media.updated | `{ userId, mic, camera }` | TRA05, TRA07 | proposto |
| live.ended | `{ reason (inclui `conteudo_detectado`), summary? }` | ASS10, TRA13 | proposto |
| live.user.muted / live.user.kicked | `{ userId, until?, refund? }` | TRA06, ASS16 | proposto |
| live.moderator.changed | `{ userId, isModerator }` | TRA06 | proposto |
| live.stage.request | `{ request }` | TRA07 | proposto |
| live.stage.updated | `{ participants }` | TRA07, TRA08 | proposto |
| live.goal.updated | `{ goal }` | ASS15 | proposto |
| live.private.started / live.private.ended | `{ pricePerMinute }` | TRA14 | proposto |
| live.private.charged | `{ minute, coins, balance }` (só para o pagante) | TRA14 | proposto |
| live.private.low_balance | `{ minutesLeft }` | TRA14 | proposto |
| live.private.refunded | `{ coins, reason }` | TRA14, RN-50 | proposto |
| live.detection.warning | `{ kind: "rosto_ausente", secondsLeft }` (só para o host) | TRA13 | proposto |
| live.privatized | `{ reason: "ausencia_detectada" \| "host" }` | TRA13, TRA14 | proposto |
| live.wheel.spun | `{ userId, option }` | PRE08 | proposto |
| live.tip.requested | `{ user, item }` | PRE09 | proposto |
| live.sticker.updated | `{ sticker }` | PRE07 | proposto |

### Presentes
| type | data (resumo) | Usado por | Status |
| --- | --- | --- | --- |
| live.gift.sent | `{ sender (ou anônimo), receiverId, gift, quantity, comboId, comboCount }` | PRE01–PRE03 | proposto |
| gift.super.announced | `{ sender, receiver, gift, liveId }` (todas as conexões) | PRE04 | proposto |
| gift.lucky.result | `{ multiplier, coins }` (só para o remetente) 🚩 | PRE05 | proposto |
| gift.catalog.updated | `{ version }` | PRE01 | proposto |

### PK (sala `pk:{id}` + salas das lives)
| type | data (resumo) | Usado por | Status |
| --- | --- | --- | --- |
| pk.invite.received | `{ invite }` | PK04 | proposto |
| pk.invite.updated | `{ inviteId, status }` | PK03 | proposto |
| pk.started | `{ pk }` | PK05, PK06 | proposto |
| pk.score.updated | `{ sides: [{ hostId, points, topSenders }] }` | PK06, PK07 | proposto |
| pk.ended | `{ winner, scores, mvps, punishmentSeconds }` | PK08 | proposto |
| pk.participant.left | `{ hostId, reason }` | PK10 | proposto |

### Chamadas (sala `call:{id}`)
| type | data (resumo) | Usado por | Status |
| --- | --- | --- | --- |
| call.incoming | `{ call }` | CHA03 | proposto |
| call.updated | `{ callId, status }` | CHA04, CHA07 | proposto |
| call.charged | `{ minute, coins, balance }` | CHA06 | proposto |
| call.low_balance | `{ minutesLeft }` | CHA05 | proposto |
| call.refunded | `{ coins, reason }` | CHA06 | proposto |
| call.media.updated | `{ userId, mic, camera }` | CHA05 | proposto |

### Mensagens (sala `conversation:{id}` e conexão pessoal)
| type | data (resumo) | Usado por | Status |
| --- | --- | --- | --- |
| message.new | `{ conversationId, message }` | MSG01, MSG02 | proposto |
| message.removed | `{ conversationId, messageId }` | MSG07 | proposto |
| message.read | `{ conversationId, userId, lastReadId }` | MSG02 | proposto |
| message.typing | `{ conversationId, userId }` | MSG02 | proposto |

### Economia
| type | data (resumo) | Usado por | Status |
| --- | --- | --- | --- |
| wallet.updated | `{ coins, freeCoins, diamonds, bonusDiamonds, reason, transactionId }` | ECO01 | proposto |
| purchase.completed | `{ purchaseId, coins }` | ECO02, POR04 | proposto |
| purchase.failed | `{ purchaseId, code }` | ECO02, POR04 | proposto |
| payout.updated | `{ payoutId, status, reason? }` | ECO01, POR02 | proposto |
| level.up | `{ level, rewards }` | PER06 | proposto |
| vip.updated | `{ level, spent7d, nextLevel, dropsAt }` | VIP01 | proposto |
| subscription.updated | `{ creatorId, status }` | SUB02, SUB03 | proposto |

### Comunidade
| type | data (resumo) | Usado por | Status |
| --- | --- | --- | --- |
| family.updated | `{ familyId, change }` | FAM* | proposto |
| family.request | `{ request }` | FAM03 | proposto |
| agency.invite | `{ invite }` 🚩 | AGE02 | proposto |

## Detalhes (Fase 0, no mock)
- **Envelope do cliente:** mesmo formato `{ v, id, type, ts, data }`. JSON inválido ou sem `type` → ignorado, sem resposta. O `ack` só é enviado quando a mensagem tem `id`. Tipo desconhecido depois do `auth` → `ack { ok:false, error:"validacao" }`. Frame acima de 16 KB é recusado.
- **auth:** `data.token`. Válido → `ack { ok:true }`. Vencido → `session.invalid { reason:"token_expirado" }` e fechamento `4003` (não terminal: o cliente renova e reconecta). Inválido → `session.invalid { reason:"token_invalido" }` e fechamento com código `4001`. Também caem aqui o token de sessão já revogada (mesmo dentro da validade), de sessão inexistente e de conta suspensa, banida ou congelada por menor de idade (fechamento com texto `menor_de_idade`; quem já estava conectado recebe `reason: "conta_bloqueada"`): o texto do fechamento carrega o código da API (ex.: `sessao_substituida`). A checagem da sessão vem antes da validade do token. Por isso quem **conecta** com token de sessão substituída não recebe `session.replaced`/`4002`: o aviso "outro aparelho" só chega a quem estava conectado na hora (o app também recebe `401 sessao_substituida` no REST). Sem `auth` em 5 s → fechamento `4000`. Outra mensagem antes do `auth` → `ack { ok:false, error:"nao_autenticado" }`.
  - **Só no mock:** além do access token real (Fase 1b), aceita os tokens de teste `dev-token-<userId>` das fixtures. O app obtém o token por `TokenSource`, sem token fixo. Com `dev-token-<userId>` a conexão não tem sessão: a regra "uma conexão por conta" derruba a anterior com `session.replaced` + `4002`; `4004` só vale para tokens reais.
- **Uma conexão por sessão (ADR 0012):** reconexão da mesma sessão fecha a conexão antiga com `4004` (não terminal, sem aviso). Login em outro aparelho revoga a sessão: a conexão dela recebe `session.replaced` e fecha com `4002`. Outras revogações fecham com `4001` e enviam `session.invalid { reason }`: `logout`, `reuso_refresh` e `mesmo_aparelho` (novo login no **mesmo** aparelho, sem aviso de "outro aparelho") → `revogada`; `senha_trocada` → `senha_trocada`; `expirada` → `expirada`; `conta_bloqueada` → `conta_bloqueada`.
- **auth repetido** numa conexão já autenticada → `ack { ok:false, error:"conflito" }` (não troca de conta).
- **ping → pong** com `data` vazio, sem `ack`.
- **Limites (mock):** até 20 mensagens por segundo por conexão (acima disso fecha com `4008`) e até 20 salas por conexão (`ack limite_excedido`). Valores em `mock-server/src/business.ts`.
- **room.join / room.leave:** `data.room` no formato `live:{id}`, `pk:{id}`, `call:{id}`, `conversation:{id}`; formato inválido → `ack { ok:false, error:"validacao" }`. Na Fase 0 só salas `live:` são abertas; `pk:`, `call:` e `conversation:` respondem `ack { ok:false, error:"sem_permissao" }` até a feature dona checar participação (Fases 3, 5, 6).
- **config.updated:** `data = { configVersion, ...campos alterados }` (mesmo formato de `GET /config`). O cliente ignora se `configVersion` ≤ à versão que já tem.
- **Códigos de fechamento:** `4000` sem auth a tempo · `4001` token inválido ou sessão revogada · `4002` sessão substituída · `4003` token vencido (não terminal) · `4004` substituída pela mesma sessão (não terminal) · `4008` limite de mensagens · `1001` servidor encerrando (mock reset). `4001` e `4002` são terminais: o cliente não reconecta.
- **Cliente (app):** espera o `ack` do `auth` por até 10 s; reconecta com espera de 1 s dobrando até 30 s (±20%); ao reconectar reenvia `auth` e `room.join` das salas ativas e rebusca o estado por REST. `session.invalid` com `token_expirado` é ignorado (o `4003` seguinte renova e reconecta); com `token_invalido` encerra como token inválido; qualquer outro motivo encerra como sessão revogada; `session.replaced` encerra como substituída. `4001`/`4002` não reconectam; `4003` renova e reconecta (sem rede, tenta de novo depois sem encerrar a sessão); `4004` para de disputar a conexão.

