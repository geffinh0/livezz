# ADR 0012: Modelo de sessão (token curto, refresh rotativo, aparelho com segredo)

- Status: aceita
- Data: 2026-11-21

## Contexto
A conta tem saldo em dinheiro, então sequestro de sessão é o maior risco do produto (docs/SEGURANCA.md). Ao mesmo tempo: um aparelho por conta (ADR 0009, RN-06), sessão de 30 dias sem uso e máximo absoluto de 180 dias (Q-50, Q-54), tempo real que precisa sobreviver à renovação do token, e revogação imediata (logout, troca de senha, login em outro aparelho, reuso de refresh).

## Opções consideradas
1. Token longo sem refresh: simples, mas um token roubado vale até expirar e não dá para revogar sem consultar estado.
2. Token de acesso curto + refresh rotativo com detecção de reuso, sessão no servidor e ligação ao aparelho por segredo.

## Decisão
Opção 2.
- **Aparelho:** `POST /devices` devolve `deviceId` + `deviceSecret` (servidor guarda só o hash). Login, refresh e atualização do aparelho exigem os dois.
- **Sessão** (`Sessao` no DATABASE.md): uma ativa por usuário. Login novo revoga a anterior: `outro_aparelho` (aviso "outro aparelho") ou `mesmo_aparelho` (mesmo aparelho, sem esse aviso).
- **Access token:** curto (15 min, configurável entre 5 e 60), assinado pelo servidor, carrega `sub` (usuário) e `sid` (sessão). No mock o formato é `at.<claims base64url>.<hmac>` com `sub`, `sid` e `exp` (ms), **só do mock**; o backend real usa o formato que a ADR do backend definir. Toda rota autenticada e o WebSocket checam se a sessão `sid` está ativa → revogação vale na hora.
- **Refresh token:** opaco, guardado só como hash, rotativo (cada uso gera outro). Reuso de um refresh já trocado → revoga a sessão (`sessao_revogada`), exceto dentro de 10 s da troca (tolerância para resposta perdida na rede). A tolerância vale **uma única vez** por troca (o refresh anterior não reabre a janela); reuso fora dela gera aviso `sessao_revogada` ao dono. Expira com 30 dias sem uso ou 180 dias desde o login (configuráveis).
- **Tempo real:** `auth` com token vencido fecha com `4003` (não terminal: o cliente renova e reconecta); token inválido `4001` (terminal); sessão substituída `4002` (terminal, aviso "outro aparelho"); reconexão da mesma sessão fecha a conexão antiga com `4004` (não terminal); qualquer outra revogação envia `session.invalid { reason }` e fecha com `4001`.
- **Avisos de conta:** login em aparelho diferente do das sessões anteriores gera aviso `novo_aparelho`; reuso de refresh gera `sessao_revogada` (envio por push/e-mail na Fase 8). `auth` no tempo real com sessão já revogada responde `session.invalid`/`4001` (EVENTOS-TEMPO-REAL.md).
- **No app:** tokens e segredo do aparelho no armazenamento seguro (Keystore), fora do backup do Android.

## Consequências
- O backend real precisa de consulta rápida de sessão ativa (cache) em toda requisição.
- Códigos de erro distintos por motivo (`token_expirado`, `nao_autenticado`, `sessao_substituida`, `sessao_revogada`, `sessao_expirada`, `dispositivo_invalido`, `conta_suspensa`, `conta_banida`) para o app mostrar o aviso certo.
- Mock e backend usam os mesmos testes de contrato desses fluxos.
