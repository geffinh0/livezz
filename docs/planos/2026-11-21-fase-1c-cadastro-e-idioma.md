# Plano 1c — Cadastro, idade, bônus e idioma

Itens: **ENT08, ENT09, ENT10, ENT11, ENT12, ENT13, ENT14, ENT15, CFG14**.
Decisões do usuário usadas: Q-55 a Q-65 (`docs/QUESTOES-ABERTAS.md`).

## Como cada critério será atendido

### ENT08 Dados iniciais
- Tela "Seus dados": nome de exibição (RN-05: 2–30, filtrado no servidor), data de nascimento (seletor; aviso "não poderá ser alterada"), gênero opcional (Mulher, Homem, Não-binário, Prefiro não dizer; **privado**, Q-59).
- Sinal da loja (Q-64): o app consulta `AgeSignalProvider` (interface em `lib/core/age/`) e envia o resultado junto com a data. No 1c só existe o `FakeAgeSignalProvider` (configurável nos testes); o plugin nativo com a biblioteca oficial entra na Fase 12.
- **O servidor decide** a idade (nunca o app): data < 18 anos **ou** sinal com `ageUpper < 18` → conta congelada (ENT10). Data é gravada uma vez e nunca mais muda (RN-01).

### ENT09 Verificação forte de idade (conector fake, Q-57)
- `POST /me/age-verification { method }` inicia a sessão no conector `verificacao_idade` (fake), devolve `{ id, status: "pendente", redirectUrl }`. O app abre a página do provedor (WebView); no fake, a página do mock tem "Aprovar / Reprovar / Menor de idade".
- Estados: pendente → aprovado | reprovado | expirado (validade da sessão configurável). Resultado chega pelo evento `age.verification.updated { status }` e por `GET /me/age-verification` (reconexão).
- Reprovado: não transmite nem saca (guarda para TRA01/POR02 no servidor; a checagem é escrita agora como regra reutilizável). Menor detectado → congela a conta (ENT10).
- Ligada/desligada pelo comprador (flag `ageVerification`, padrão ligada). Desligada: rota → `403 funcionalidade_desligada` e o app esconde o fluxo.
- Ponto de entrada no 1c: Perfil → "Verificação de idade" (até TRA01 existir).

### ENT10 Bloqueio de menor (Q-58, Q-63, Q-65)
- Conta inteira **congelada** (`situacao_conta = congelada`, `situacao_idade = menor_bloqueado`), sessões revogadas (`conta_bloqueada`), **aparelho marcado**.
- Login, cadastro ou uso nesse aparelho, ou dessa conta → `403 menor_bloqueado` → tela explicativa, sem acesso, sem "voltar e mudar a data" (data imutável + aparelho marcado).
- Desfazer: só a equipe, com verificação forte aprovada; sem exclusão automática. No 1c: regra e rota `/__mock/minor/unfreeze` para testes; a tela do painel fica para ADM.

### ENT11 Criar @
- `GET /usernames/{u}/availability` → `{ available, reason?, suggestions[] }` (formato `[a-z0-9._]` 3–20, único, sem palavras reservadas; RN-05). App consulta com espera de 400 ms após digitar (debounce) e mostra o motivo no próprio campo; sugestões tocáveis.
- `POST /me/username` grava (troca a cada 30 dias vale depois, PER02; no cadastro é a primeira definição). Limite de consultas por minuto.

### ENT12 Interesses
- `GET /interests` (categorias do servidor, no idioma) e `POST /me/interests { ids }`. Pular permitido (grava "visto, nenhum"). Usados na descoberta (Fase 2: o campo fica salvo e exposto para o servidor de descoberta).

### ENT13 Bônus de boas-vindas (Q-56, Q-60, Q-62)
- **Ledger mínimo** no mock (ADR 0013): `ContaLedger`, `TransacaoLedger` (chave de idempotência única), `LancamentoLedger` (soma zero por moeda), saldo derivado. Só o tipo `bonus` neste plano; moedas **grátis** separadas das pagas (RN-30).
- Config do comprador (`ConfigRecompensas`): `bonus_boas_vindas { ativo: false, moedas }`, `recompensa_telefone { ativo: false, moedas }` (padrão desligado). Cenário `/__mock/scenario/bonus-ligado` liga com valores de teste.
- `GET /me` passa a trazer `offers { welcomeBonus: bool, phoneLinkReward: int|null }` (o servidor decide a elegibilidade).
- `POST /rewards/claim { kind: "welcome" }` + `Idempotency-Key` → `{ coins, transactionId }`; elegível só com telefone na conta e uma vez por pessoa (aparelho, telefone e verificação de idade; RN-31). Erros: `403 funcionalidade_desligada`, `409 ja_recebido`, `403 telefone_necessario`.
- App: overlay com o valor que o servidor devolveu; evento `wallet.updated`. `GET /wallet` mínimo (saldos) para provar o crédito.

### ENT14 Vincular telefone com recompensa (Q-61)
- Oferecido uma vez, depois do cadastro, a quem entrou por e-mail/Google **quando a recompensa ou o bônus de boas-vindas estiver ligado** (sem nada ligado não há o que oferecer; o vínculo continua em ENT15). Decisão minha.
- `POST /auth/code/send { purpose: "link" }` + `POST /me/login-methods { type: "phone", destination, code }`. Telefone já usado por outra conta → `409 conflito`.
- Recompensa creditada no servidor (uma vez por número, idempotente) e, se elegível, libera o bônus de boas-vindas (Q-62).

### ENT15 Contas vinculadas
- Tela em Perfil → Configurações → "Contas vinculadas": lista (telefone mascarado, e-mail mascarado, Google), vincular telefone (código), e-mail (código + senha) e Google (conta de teste), desvincular.
- `DELETE /me/login-methods/{id}` → `409 ultimo_metodo` se for o único. Desvincular exige confirmação na tela.

### CFG14 Idioma
- Primeira vez: segue o idioma do aparelho (pt → pt-BR; qualquer outro → en; padrão pt-BR). Troca em Configurações → "Idioma", sem reiniciar (já suportado pelo `MaterialApp`).
- Logado: `PATCH /me { language }` (servidor usa nos textos e push). Visitante: só local.

## Contratos (escritos como `proposto` antes do código)
- REST: `PATCH /me` (displayName, birthDate só uma vez, gender, language, `storeAgeSignal`), `GET /usernames/{u}/availability`, `POST /me/username`, `GET /interests`, `POST /me/interests`, `POST|GET /me/age-verification`, `GET|POST|DELETE /me/login-methods`, `POST /rewards/claim`, `GET /wallet` (mínimo), `/auth/code/send purpose: "link"`. `GET /me` ganha `username`, `displayName`, `birthDateSet`, `ageStatus`, `language`, `pendingSteps` (`profile`, `username`, `interests`), `offers`.
- Erros novos: `menor_bloqueado`, `username_indisponivel` (com `details.reason`), `data_imutavel`, `ultimo_metodo`, `ja_recebido`, `telefone_necessario`.
- Eventos: `age.verification.updated`, `wallet.updated` (subconjunto).
- Mock-only: cenários `bonus-ligado`, `verificacao-idade-desligada`; `/__mock/age/{id}/complete { result }`; `/__mock/minor/unfreeze`.

## Dados (DATABASE.md, `proposta` → `em uso no mock`)
- Usuario: `username`, `nome_exibicao`, `genero` (privado), `data_nascimento`, `situacao_idade`, `situacao_conta = congelada`, `interesses` (null = não respondeu), `idioma`, `faixa_etaria_loja`.
- Dispositivo: `bloqueado_menor_em`, `bloqueado_menor_conta_id`.
- VerificacaoIdade: em uso no mock; `expira_em`.
- Novas: **ConfigRecompensas**, **ConcessaoBonus** (tipo, usuario, aparelho, telefone_hash, verificacao_id; únicas por regra RN-31), **CategoriaInteresse**, **PalavraReservada** (lista do comprador).
- Ledger: ContaLedger, TransacaoLedger, LancamentoLedger em uso no mock (ADR 0013).
- App: `PreferenciasLocais.idioma`.

## Mudanças por camada
- **mock-server:** módulos `profile/`, `age/`, `ledger/`, `rewards/`; config central de nomes reservados e filtro; cenários; testes de contrato de tudo (incl. idempotência, concorrência, soma zero, flag desligada, conta congelada).
- **app:** `lib/core/age/` (AgeSignalProvider + fake), `features/onboarding/` (dados, @, interesses, bônus), `features/age_verification/`, `features/account/` (contas vinculadas, idioma, configurações mínimas), `EntryDestination.minorBlocked` e o fluxo de cadastro no roteador no lugar de "complete seu cadastro".
- **design system:** componente de seletor de data acessível e `AppChoiceChips` (interesses), documentados no DESIGN-SYSTEM.md.

## Riscos
- **Dinheiro:** ledger novo → ADR 0013, `revisor-seguranca`, testes obrigatórios de `.claude/rules/dinheiro.md` (idempotência repetida, concorrência, soma zero, flag desligada, sancionado).
- **Menores (ECA Digital):** decisão de idade só no servidor; bloqueio do aparelho; nenhum dado de idade em log; sinal da loja não usado para outra coisa (termos do Google).
- **Dados pessoais:** data de nascimento e gênero 🔒, mascarados em log; gênero nunca em resposta pública.
- **Abuso:** consulta de @ com limite; RN-31 por aparelho, telefone e verificação.
- **Jurídico:** Q-41 continua aberta (validade do modelo de idade).

## Testes
- Contrato (mock) para cada rota e erro acima; ledger: soma zero, mesma chave repetida, dois resgates concorrentes, flag desligada, conta congelada.
- Unitários: regras de nome e @, cálculo de idade com data limite (aniversário hoje), decisão de destino com `minorBlocked`.
- Widget de cada tela nova (pt/en, fonte 2x, erro, sem conexão).
- E2E web: `ENT08.cjs` (cadastro completo + erro de nome), `ENT10.cjs` (data de menor → bloqueio; reabrir continua bloqueado; outro login no aparelho bloqueado), `ENT11.cjs` (@ indisponível + sugestão), `ENT12.cjs` (pular e escolher), `ENT13.cjs` (bônus ligado → overlay; repetir não credita), `ENT14.cjs`, `ENT15.cjs` (último método não sai), `ENT09.cjs` (aprovado, reprovado, desligado), `CFG14.cjs` (troca sem reiniciar).

## Passos
1. Contratos (API, EVENTOS), DATABASE (`proposta`), ADR 0013 (ledger mínimo).
2. mock: perfil inicial, @ (disponibilidade, sugestões, reservados), interesses, idioma + testes.
3. mock: decisão de idade, congelamento de conta e aparelho (ENT10) + testes.
4. mock: verificação forte com conector fake, evento e flag + testes.
5. mock: ledger mínimo + recompensas (boas-vindas, telefone) + RN-31 + `GET /wallet` + testes de dinheiro.
6. mock: métodos vinculados (listar, vincular telefone/e-mail/Google, desvincular) + testes.
7. app: AgeSignalProvider + fake; repositórios e modelos (perfil, @, interesses, verificação, carteira, métodos).
8. app: fluxo de cadastro (ENT08, ENT11, ENT12) no roteador + telas + widget.
9. app: ENT10 (tela e destino) + ENT09 (telas, WebView, evento) + widget.
10. app: ENT13 overlay + ENT14 oferta + widget.
11. app: Configurações mínimas: ENT15 contas vinculadas + CFG14 idioma + widget.
12. E2E web de todos os itens; prints claro/escuro, pt/en.
13. Conferir a lista de testes deste plano; verificador; revisões (código, UX, segurança, dados); correções; verificador final; documentos.

## Ajustes da revisão de segurança (incorporados)
- **Reautenticação (crítico):** `POST`/`DELETE /me/login-methods` exigem prova recente (≤ 5 min) de um método existente (código ao telefone/e-mail atual ou senha) → senão `401 reautenticacao_necessaria`. Aviso a todos os métodos antigos (AvisoConta). Desvincular revoga a sessão nos demais aparelhos.
- **Bônus irrepetível (crítico):** `ConcessaoBonus` nunca é apagada; únicas por (tipo, telefone_hmac), (tipo, aparelho) e (tipo, sujeito da verificação). `telefone_hmac` com chave do servidor (não sha256 puro).
- **Idempotência e corrida (crítico):** além da `Idempotency-Key`, chave determinística do servidor (`reward:welcome:<userId>`, `reward:phone:<hmac>`); mesma chave com corpo diferente → `422`. Elegibilidade + crédito num passo só; teste com N resgates paralelos e chaves diferentes → um crédito. Valor gravado na transação; contrapartida na conta de sistema "emissão promocional" (única que pode ficar negativa), moedas grátis separadas.
- **Contornar o bloqueio:** identificadores da conta congelada (telefone_hmac, e-mail, Google sub) recusam cadastro novo; reinstalar o app gera aparelho novo → limitação registrada (Q-41) e atestação do aparelho (Play Integrity) planejada para a Fase 12.
- **Estado `congelada` na sessão:** `issueSession`, `refresh`, `authenticate` e WebSocket → `403 menor_bloqueado`; aparelho marcado checado antes de criar usuário (sem conta órfã).
- **Portão de cadastro:** sem data de nascimento, só `GET/PATCH /me`, termos e logout; o resto → `403 cadastro_pendente`. Resgate exige idade adulta decidida.
- **`PATCH /me`:** lista fechada de campos; data gravada só se nula (atômico, teste concorrente); não futura, ≤ 120 anos; `storeAgeSignal` só pode bloquear, nunca liberar.
- **ENT09:** status só pelo servidor (consulta/callback do provedor), nunca pelo retorno da WebView; `redirectUrl` com host permitido; sessão ligada ao usuário (outro usuário → 404); limite de sessões por dia; idade estimada < 18 ou divergência com a data → revisão; RN-31 usa identificador estável do provedor.
- **Enumeração ao vincular:** conflito só checado depois do código validado; código de `link` amarrado ao usuário (`link|userId|destino`); limite por conta; Google não religa e-mail já desvinculado.
- **Logs e gênero:** redação de `birthDate`, `gender`, `storeAgeSignal`, `ageUpper`, `details`, com teste; gênero só em `GET /me` (teste de contrato) e fora de analytics/descoberta; finalidade escrita na tela.
- **Atômicos e validação:** último método (dois DELETE concorrentes), `POST /me/username` (checar+gravar), `interests.ids` (tamanho, existentes, sem repetição), `language` e `kind` fechados, valores de recompensa inteiros positivos com teto. Consulta de @ autenticada e limitada por conta e IP; reservados incluem a marca do tenant e variações; @ de conta congelada continua reservado.
- **Rotas mock-only** só em `scenarios/mock-routes.ts`, com teste.

## Fora do escopo
- Plugin nativo do Play Age Signals (Fase 12, Q-64); provedor real de verificação de idade (Fase 12, Q-35).
- Tela do painel para revisar contas congeladas e configurar recompensas (ADM, fase do painel); suporte para pedir revisão.
- Ledger completo (compras, presentes, saques, extrato): Fase 4.
- Troca de @ a cada 30 dias e edição de perfil (PER02, Fase 2).

Status: aguardando aprovação
