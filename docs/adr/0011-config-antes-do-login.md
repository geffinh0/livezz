# ADR 0011: Config antes do login sem tempo real anônimo

- Status: aceita
- Data: 2026-11-20

## Contexto
O WebSocket exige `auth` com token (ADR 0005). Antes do login o app não recebe `config.updated`, mas o TRV04 pede config atualizada por evento e o comprador pode mudar flags, manutenção ou versão mínima no painel a qualquer momento.

## Opções consideradas
1. Conexão de tempo real anônima só com eventos de sistema: atualização imediata para todos, porém mais conexões abertas (custo) e mais superfície de ataque.
2. Rebuscar `GET /v1/config` ao abrir o app e ao voltar do segundo plano enquanto não há login; com login, `config.updated` pelo tempo real.

## Decisão
Opção 2 (decisão do usuário, Q-43). A config tem `versao` crescente; o app ignora eventos com versão menor ou igual à atual e rebusca a config ao reconectar.

## Consequências
- Sem conexões anônimas no servidor.
- Usuário não logado vê mudanças na próxima abertura ou retorno ao app; respostas `426` e `503 manutencao` cobrem os casos urgentes em qualquer requisição.
