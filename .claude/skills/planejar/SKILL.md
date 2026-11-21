---
name: planejar
description: Cria o plano de implementação de um ou mais itens da especificação antes de escrever código. Use no início de qualquer trabalho novo.
argument-hint: [IDs da especificação ou descrição, ex. "ENT04 ENT05 ENT06 ENT07"]
---

Planejar: $ARGUMENTS

Não escreva código de produção nesta etapa.

## 1. Entender
- Leia os itens em `docs/ESPECIFICACAO.md` (critérios de aceite e Definição de pronto), as regras `RN-xx` citadas, as entidades do `docs/DATABASE.md`, os endpoints e eventos envolvidos, `docs/ARQUITETURA.md`, `docs/SEGURANCA.md` e o que já existe no código (subagente Explore se for muita coisa).
- **Caçar ambiguidade:** releia cada critério de aceite e cada regra citada perguntando "dá para ler isto de mais de um jeito?" (ex.: quais documentos são obrigatórios, quem vê o quê, o que acontece no erro ou sem rede). Cada leitura dupla vira pergunta ao usuário **antes** da aprovação do plano, não durante a implementação.
- Liste o que **não está definido** (comportamento, texto, valor, regra). Para cada ponto: é decisão óbvia (decida e diga) ou precisa do usuário (pergunte agora, até 4 por vez)?
- Se a tarefa usa biblioteca, SDK ou política externa, peça ao `pesquisador` a documentação atual.

## 2. Escrever o plano
Arquivo `docs/planos/AAAA-MM-DD-<nome-curto>.md`:
- **Itens cobertos** (IDs) e, para cada um, como cada critério de aceite será atendido.
- **Contratos:** endpoints e eventos novos/alterados (já escreva em `docs/API.md` / `docs/EVENTOS-TEMPO-REAL.md` com status `proposto`).
- **Dados:** entidades/campos novos ou alterados (já atualize `docs/DATABASE.md` como `proposta` + Histórico).
- **Mudanças por camada:** mock-server (rotas, regras, fixtures, cenários `/__mock`), app (telas, estado, repositórios, componentes do design system), painel (se houver).
- **Riscos:** dinheiro, segurança, dados pessoais, menores, desempenho, custo.
- **Testes:** unitários, widget, contrato, E2E (um `e2e/<ID>.yaml` por tela) e cenários de erro.
- **Passos numerados**, cada um pequeno o bastante para um commit, na ordem: contrato → mock-server + testes de contrato → domínio/dados do app → telas → E2E.
- **Fora do escopo** deste plano (o que fica para depois e por quê).
- Linha final: `Status: aguardando aprovação`.

## 3. Revisar
- Peça ao subagente `arquiteto` para revisar o plano; se toca em dinheiro/auth/dados pessoais/moderação, também ao `revisor-seguranca`. Incorpore o que fizer sentido e diga o que não incorporou e por quê.

## 4. Aprovação
Mostre ao usuário um resumo curto (itens, principais decisões, perguntas pendentes, número de passos). Só depois do "ok" dele, mude a linha para `Status: aprovado pelo usuário em AAAA-MM-DD`. Sem isso, `/implementar` não começa.
