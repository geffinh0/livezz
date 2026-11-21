# Plano 1c — Cadastro inicial, bloqueio de menor e idioma

Itens: **ENT08, ENT10, ENT11, ENT12, CFG14** e o fechamento de **ENT06** (conta nova do Google cai no cadastro).
O resto do cadastro (ledger + ENT13, ENT14, ENT15, ENT09) vai para o **plano 1d** (rascunho em `docs/planos/2026-11-21-fase-1d-ledger-bonus-e-verificacao.md`), por decisão do usuário (Q-66).
Decisões usadas: Q-55 a Q-69 (`docs/QUESTOES-ABERTAS.md`). Revisado pelo `arquiteto` e pelo `revisor-seguranca` (ajustes já incorporados abaixo).

## Como cada critério será atendido

### ENT08 Dados iniciais
- Tela "Seus dados": nome de exibição (RN-05: 2–30, filtrado no servidor), data de nascimento (seletor acessível; aviso "não poderá ser alterada"), gênero opcional (Mulher, Homem, Não-binário, Prefiro não dizer; **privado**, Q-59, com a finalidade escrita na tela).
- Sinal da loja (Q-64): `AgeSignalProvider` em `lib/core/age/` com `FakeAgeSignalProvider` (configurável nos testes); o DTO espelha a Play: `{ status: shared|not_shared|verification_required|unavailable, ageLower?, ageUpper? }`. Plugin nativo na Fase 12.
- **O servidor decide** a idade: data com menos de 18 anos (comparando só datas, no fuso do tenant; RN-01 ganha essa frase) **ou** sinal com `ageUpper < 18` → ENT10. O sinal vem do cliente, então **só pode bloquear, nunca liberar**.
- `PATCH /me`: lista fechada de campos (`displayName`, `birthDate`, `gender`, `language`, `storeAgeSignal`); `birthDate` gravada só se ainda nula, de forma atômica (`409 conflito` com `details.reason = "data_imutavel"`); data não futura e no máximo 120 anos.
- **Portão de cadastro** (como `termos_pendentes`): enquanto `pendingSteps` tiver `profile`, só `GET /me`, `PATCH /me`, termos, logout e a checagem de @ respondem; o resto → `403 cadastro_pendente`.

### ENT10 Bloqueio de menor (Q-58, Q-63, Q-65, Q-68)
- Uma transação só: conta `congelada` (`situacao_idade = menor_bloqueado`), sessões revogadas (`conta_bloqueada`), aparelho marcado, identificadores da conta (telefone, e-mail, Google) reservados; resposta `403 menor_de_idade`.
- `congelada` passa a ser checada em `issueSession`, `/auth/refresh`, `authenticate`, todas as rotas de login e no upgrade do tempo real → `403 menor_de_idade`. Aparelho marcado é checado **antes** de criar usuário (sem conta órfã). `POST /devices` devolve `blocked: true` para aparelho marcado.
- App: destino `minorBlocked` com prioridade acima de termos e independente de haver sessão; interceptor global para `menor_de_idade`. Tela explicativa, sem acesso, com o **e-mail de suporte do tenant** (novo campo `supportEmail` em `tenant.json`) e um número de protocolo (Q-68).
- Desfazer: só a equipe, com verificação forte aprovada (ENT09, plano 1d). No 1c: regra no serviço + `/__mock/minor/unfreeze` para testes; tela do painel fica para ADM.
- Limitação conhecida: reinstalar o app gera aparelho novo. Registrada em MELHORIAS; atestação do aparelho (Play Integrity, SEG05) na Fase 12.

### ENT11 Criar @
- `GET /usernames/{u}/availability` (autenticada, limite por conta e IP) → `{ available, reason?, suggestions[] }`; formato `[a-z0-9._]` 3–20, sem ponto nas pontas nem pontos seguidos, único, sem reservados (lista do comprador + marca do tenant e variações); @ de conta congelada continua reservado.
- `POST /me/username`: checagem e gravação num passo só (`409 username_indisponivel` com `details.reason` se alguém pegou no meio).
- App: consulta 400 ms depois de parar de digitar; motivo no próprio campo; sugestões tocáveis.

### ENT12 Interesses
- `GET /interests` → categorias do servidor (`CategoriaInteresse`: nome pt/en, ordem, ativa); `POST /me/interests { ids }` (até 10, existentes, sem repetição). "Pular" grava lista vazia (`interesses = []`; `null` = ainda não respondeu). Ficam guardados para a descoberta (Fase 2).

### ENT06 (fechamento)
- Conta nova do Google cai no cadastro (ENT08) em vez de "complete seu cadastro". Google real continua na Fase 12 (Q-53).

### CFG14 Idioma
- Primeira vez: idioma do aparelho (pt → pt-BR; outro → en). Troca em Perfil → Configurações → Idioma, sem reiniciar.
- Logado: `PATCH /me { language }`; o servidor usa `Usuario.idioma` para textos e push; `Dispositivo.idioma` vale só para visitante.

## Contratos (escritos como `proposto` antes do código)
- `GET /me` ganha `displayName`, `username`, `gender` (só aqui), `ageStatus`, `language`, `pendingSteps` (`profile`, `username`, `interests`); `needsProfile` continua (= `pendingSteps` não vazio) para não quebrar a 1b.
- `PATCH /me`, `GET /usernames/{u}/availability`, `POST /me/username`, `GET /interests`, `POST /me/interests`, `POST /devices` (+ `blocked`).
- Erros: reusar `menor_de_idade`, `username_indisponivel`, `conflito`; novo `cadastro_pendente`.
- Mock-only: `/__mock/minor/unfreeze`, cenário `sinal-loja-menor` (o fake da loja diz menor).

## Dados
- Usuario: `username`, `nome_exibicao`, `genero` (privado), `data_nascimento`, `situacao_idade`, `situacao_conta = congelada`, `interesses` (null/lista), `idioma`, `faixa_etaria_loja` (`status`, `ageLower`, `ageUpper`).
- Dispositivo: `bloqueado_menor_em`, `bloqueado_menor_conta_id`.
- Novas: **CategoriaInteresse**, **PalavraReservada**, **IdentificadorBloqueado** (tipo, valor_hmac, conta_id, criado_em).
- Tenant: `supportEmail`. App: `PreferenciasLocais.idioma`.

## Mudanças por camada
- **mock-server:** `profile/` (perfil, @, interesses, portão de cadastro), regra de idade e congelamento em `auth/`, config central de reservados e filtro de nome, cenários, redação de log (`birthDate`, `gender`, `storeAgeSignal`, `ageLower`, `ageUpper`).
- **tools/tenant:** `supportEmail` validado e gerado.
- **app:** `lib/core/age/`, `features/onboarding/` (dados, @, interesses), destino `minorBlocked` + tela, `features/settings/` mínima (idioma), roteador com os passos do cadastro.
- **design system:** `AppDateField` (seletor de data acessível) e `AppChoiceChips` (interesses), documentados no DESIGN-SYSTEM.md.

## Riscos
- **Menores (ECA Digital):** decisão só no servidor; sinal só restringe; congelamento atômico; nada de idade em log; uso do sinal da loja só para idade (termos do Google).
- **Dados pessoais:** data e gênero 🔒; gênero só em `GET /me` (teste de contrato) e fora de analytics/descoberta.
- **Enumeração:** consulta de @ autenticada e limitada.
- **Jurídico:** Q-41 continua aberta.

## Testes
- Contrato: cada rota e erro; `PATCH /me` com menor → 403 + sessão revogada + aparelho marcado de uma vez; dois `PATCH` concorrentes com data; portão `cadastro_pendente`; login em aparelho marcado e de conta congelada → `menor_de_idade` (REST e tempo real); corrida no @ → 409; interesses pt/en e validação; log sem data, gênero e sinal; gênero ausente de outras respostas.
- Unitários: regras de nome e @; idade com aniversário hoje e fuso; decisão de destino com `minorBlocked` e `pendingSteps`.
- Widget de cada tela nova (pt/en, fonte 2x, erro, sem conexão).
- E2E web (um fluxo por arquivo): `ENT08.cjs` (cadastro completo + nome inválido), `ENT10.cjs` (data de menor → bloqueio; reabrir continua bloqueado), `ENT10-aparelho.cjs` (outra conta no aparelho marcado → bloqueio), `ENT10-sinal.cjs` (sinal da loja de menor), `ENT11.cjs` (@ ocupado + sugestão), `ENT12.cjs` (pular e escolher), `ENT06.cjs` atualizado, `CFG14.cjs` (troca sem reiniciar).

## Passos
1. Contratos (API, EVENTOS), DATABASE (`proposta`), RN-01 (fuso), `supportEmail` no tenant. ✅
2. mock: `PATCH /me`, portão de cadastro, perfil em `GET /me` + testes. ✅
3. mock: decisão de idade e congelamento (conta, sessões, aparelho, identificadores; REST e tempo real) + testes. ✅
4. mock: @ (disponibilidade, sugestões, reservados, gravação atômica) + testes. ✅
5. mock: interesses e idioma + testes; redação de log com teste. ✅
6. app: `AgeSignalProvider` + fake; repositórios e modelos (perfil, @, interesses); destinos `onboarding` e `minorBlocked` + testes unitários.
7. app: telas ENT08 e ENT10 + widget.
8. app: telas ENT11 e ENT12 + widget.
9. app: Configurações mínimas + CFG14 + widget.
10. E2E web dos itens; prints claro/escuro, pt/en.
11. Conferir a lista de testes; verificador; revisões (código, UX, segurança, dados); correções; verificador final; documentos.

## Fora do escopo
- Plano 1d: ledger mínimo (ADR 0013), ENT13, ENT14, ENT15, ENT09.
- Plugin nativo do Play Age Signals (Fase 12, Q-64).
- Tela do painel para revisar contas congeladas (ADM).
- Troca de @ a cada 30 dias e edição de perfil (PER02, Fase 2).

Status: aprovado pelo usuário em 2026-11-21
