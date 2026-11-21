# Plano 1d — Ledger mínimo, bônus, contas vinculadas e verificação de idade (RASCUNHO)

> Rascunho guardado para não perder as decisões e as revisões. Será planejado de verdade (`/planejar`) depois do 1c.

Itens: **ENT13, ENT14, ENT15, ENT09** + **ADR 0013 (ledger mínimo)**.
Decisões: Q-56, Q-57, Q-60, Q-61, Q-62, Q-67, Q-69.

## Pontos já definidos pelas revisões
- **Ledger (ADR 0013):** ContaLedger/TransacaoLedger/LancamentoLedger; conta de sistema "emissão promocional" em `moeda_gratis` (única que pode ficar negativa) como contrapartida; soma zero por moeda; decidir saldo derivado × `saldo_cache` + `versao`; chave de idempotência por usuário com hash do pedido (mesma chave, corpo diferente → 409/422); `referencia_tipo/id` → ConcessaoBonus; vínculo de estorno (`transacao_original_id`, motivo, autor); `criado_por = sistema`. `GET /wallet` e `wallet.updated` já no formato completo de ECO01 (`coins, freeCoins, diamonds, bonusDiamonds`).
- **Config:** estender `ConfigEconomia.bonus` (boas-vindas e telefone, ativo + moedas; padrão desligado); valor gravado na transação.
- **Crédito:** só por `POST /rewards/claim { kind: "welcome" | "phone_link" }` + `Idempotency-Key` + chave determinística do servidor; vincular telefone só torna elegível; `offers` em `GET /me`.
- **RN-31:** `ConcessaoBonus` nunca apagada; únicas por (tipo, aparelho), (tipo, telefone_hmac), (tipo, sujeito da verificação); HMAC com chave do servidor; sobrevive à exclusão da conta (Q-69).
- **ENT14:** `Usuario.oferta_telefone_vista_em`; oferta só com recompensa ou bônus ligado.
- **ENT15:** `MetodoLogin.id`; `purpose: "link"` autenticado e amarrado ao usuário; `POST /me/login-methods { type: "google", idToken }`; reautenticação recente (≤ 5 min) para vincular/desvincular; aviso aos métodos antigos; desvincular revoga os outros aparelhos; último método atômico; conflito só depois do código validado.
- **ENT09:** conector com estados `aprovado/reprovado/expirado` alinhados; status só pelo servidor; host permitido; sessão ligada ao usuário; **3 sessões por dia, configurável** (Q-67); idade estimada < 18 ou divergência → revisão; `GET /me/age-verification` ao voltar ao app; WebView já existe no projeto (`webview_flutter`), no E2E web o resultado vem por `/__mock/age/{id}/complete`.
- **Testes de dinheiro:** saldo, mesma chave repetida, mesma chave com corpo diferente, N resgates concorrentes com chaves diferentes, flag desligada, conta suspensa/sancionada, soma zero.

Status: rascunho (planejar depois do 1c)
