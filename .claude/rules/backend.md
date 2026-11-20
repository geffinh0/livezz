---
paths:
  - "backend/**/*"
---

# Regras do backend real (Fase 11 em diante)

- Só existe depois de `/preparar-banco`. Framework e banco conforme Q-26/Q-27 e ADR correspondente.
- Implementa `docs/API.md` e `docs/EVENTOS-TEMPO-REAL.md` sem mudar contratos; os testes de contrato do mock-server precisam passar contra ele.
- Schema e migrations derivados de `docs/DATABASE.md`. Divergência → atualizar o documento primeiro.
- Um módulo por domínio; controller fino, regra no service, acesso a dados no repositório.
- Operações de valor: transação, bloqueio de conta, idempotência, ledger (`.claude/rules/dinheiro.md`).
- Configuração validada na inicialização; segredos só por variáveis de ambiente.
- Logs estruturados sem dados pessoais; `requestId` em toda resposta.
- Rotas `/__mock/*` não podem existir aqui.
- Antes de terminar: lint, tipos, testes unitários e de integração com banco real em container.
