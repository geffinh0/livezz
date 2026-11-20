#!/usr/bin/env bash
# Stop: impede o Claude de encerrar se houver código alterado e
#  1) lint, tipos ou testes falhando na parte alterada;
#  2) docs/PROGRESSO.md não atualizado;
#  3) modelos/DTOs/mock alterados sem atualizar DATABASE.md/API.md/EVENTOS
#     e sem declarar "dados: sem impacto" no PROGRESSO.
# Saída 2 = bloqueia e manda o texto de stderr para o Claude corrigir.

entrada=$(cat)

# Evita loop: se já bloqueamos e o Claude está tentando parar de novo, deixa.
if [ "$(echo "$entrada" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

if git rev-parse --verify HEAD >/dev/null 2>&1; then
  rastreados=$(git diff --name-only HEAD 2>/dev/null)
else
  rastreados=$(git diff --name-only --cached 2>/dev/null)
fi
mudados=$( { echo "$rastreados"; git ls-files --others --exclude-standard; } | grep -v '^$' | sort -u)
[ -z "$mudados" ] && exit 0

problemas=""

rodar() { # $1 = rótulo, $2 = pasta, resto = comando
  local rotulo="$1" pasta="$2"; shift 2
  local saida
  saida=$(cd "$pasta" && "$@" 2>&1)
  if [ $? -ne 0 ]; then
    problemas+=$'\n'"[$rotulo] falhou: $*"$'\n'"$(echo "$saida" | tail -n 20)"
    return 1
  fi
}

# mock-server
if echo "$mudados" | grep -q '^mock-server/' && [ -f mock-server/package.json ]; then
  rodar mock-server mock-server npm run --silent lint && \
  rodar mock-server mock-server npm run --silent typecheck && \
  rodar mock-server mock-server npm test --silent
fi

# app
if echo "$mudados" | grep -q '^apps/mobile/' && [ -f apps/mobile/pubspec.yaml ]; then
  rodar mobile apps/mobile flutter analyze && rodar mobile apps/mobile flutter test
fi

# painel
if echo "$mudados" | grep -q '^apps/admin/' && [ -f apps/admin/package.json ]; then
  rodar admin apps/admin npm run --silent lint && rodar admin apps/admin npm test --silent
fi

# portal
if echo "$mudados" | grep -q '^apps/portal/' && [ -f apps/portal/package.json ]; then
  rodar portal apps/portal npm run --silent lint && rodar portal apps/portal npm test --silent
fi

# backend
if echo "$mudados" | grep -q '^backend/' && [ -f backend/package.json ]; then
  rodar backend backend npm run --silent lint && \
  rodar backend backend npm run --silent typecheck && \
  rodar backend backend npm test --silent
fi

codigo_mudou=$(echo "$mudados" | grep -E '^(apps|mock-server|backend)/' | head -n 1)

# Progresso
if [ -n "$codigo_mudou" ] && ! echo "$mudados" | grep -q '^docs/PROGRESSO.md$'; then
  problemas+=$'\n[docs] O código mudou mas docs/PROGRESSO.md não foi atualizado. Atualize "Estado atual", "Próximo passo", a linha "dados:" e o status dos itens em docs/ESPECIFICACAO.md.'
fi

# Dados e contratos
dados_mudou=$(echo "$mudados" | grep -E '^(apps/mobile/lib/features/.*/(domain|data)/|mock-server/(src|fixtures)/|apps/(admin|portal)/.*(api|types)/|backend/)' | head -n 1)
docs_dados_mudou=$(echo "$mudados" | grep -E '^docs/(DATABASE|API|EVENTOS-TEMPO-REAL)\.md$' | head -n 1)
if [ -n "$dados_mudou" ] && [ -z "$docs_dados_mudou" ]; then
  declarou=""
  if git rev-parse --verify HEAD >/dev/null 2>&1 && git ls-files --error-unmatch docs/PROGRESSO.md >/dev/null 2>&1; then
    git diff HEAD -- docs/PROGRESSO.md | grep -E '^\+' | grep -qi 'dados: *sem impacto' && declarou="sim"
  else
    grep -qi 'dados: *sem impacto' docs/PROGRESSO.md 2>/dev/null && declarou="sim"
  fi
  if [ -z "$declarou" ]; then
    problemas+=$'\n[dados] Modelos, DTOs, mock-server ou fixtures mudaram ('"$dados_mudou"' ...) mas docs/DATABASE.md, docs/API.md e docs/EVENTOS-TEMPO-REAL.md não. Atualize o que mudou (com Histórico) ou, se realmente não houve impacto em dados/contratos, escreva "dados: sem impacto" na entrada desta sessão em docs/PROGRESSO.md.'
  fi
fi

if [ -n "$problemas" ]; then
  echo "Não encerre ainda. Corrija antes de terminar:$problemas" >&2
  exit 2
fi
exit 0
