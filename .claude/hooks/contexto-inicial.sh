#!/usr/bin/env bash
# SessionStart: injeta no contexto do Claude o estado real do projeto
# quando a sessão começa, é retomada, limpa (/clear) ou compactada.

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

echo "=== ESTADO DO PROJETO (gerado automaticamente pelo hook) ==="

# Progresso
if [ -f docs/PROGRESSO.md ]; then
  echo
  echo "--- docs/PROGRESSO.md (estado e próximo passo) ---"
  sed -n '/^## Estado atual/,/^## Últimas sessões/p' docs/PROGRESSO.md | grep -v '^## Últimas sessões' | head -n 30
fi

# Placar da especificação
if [ -f docs/ESPECIFICACAO.md ]; then
  total=$(grep -cE '^- \[( |~|x)\] \*\*[A-Z]+[0-9]+' docs/ESPECIFICACAO.md)
  prontos=$(grep -cE '^- \[x\] \*\*[A-Z]+[0-9]+' docs/ESPECIFICACAO.md)
  andamento=$(grep -cE '^- \[~\] \*\*[A-Z]+[0-9]+' docs/ESPECIFICACAO.md)
  echo
  echo "--- Especificação: $prontos prontos, $andamento em andamento, de $total itens ---"
  echo "Por módulo (prontos/total):"
  grep -oE '^- \[( |~|x)\] \*\*[A-Z]+' docs/ESPECIFICACAO.md \
    | sed -E 's/^- \[(.)\] \*\*([A-Z]+)/\1|\2/' \
    | awk -F'|' '{t[$2]++; if ($1=="x") p[$2]++} END {for (m in t) printf "%s %d/%d\n", m, p[m]+0, t[m]}' \
    | sort | paste -sd' ' -
  if [ "$andamento" -gt 0 ]; then
    echo "Em andamento:"
    grep -E '^- \[~\] \*\*' docs/ESPECIFICACAO.md | sed -E 's/^- \[~\] \*\*([^*]+)\*\*.*/  \1/'
  fi
fi

# Plano mais recente
if ls docs/planos/*.md >/dev/null 2>&1; then
  ultimo=$(ls -1 docs/planos/*.md | sort | tail -n 1)
  echo
  echo "--- Plano mais recente: $ultimo ---"
  grep -m1 -E '^Status:' "$ultimo" || echo "  (sem linha de Status)"
fi

# Questões abertas
if [ -f docs/QUESTOES-ABERTAS.md ]; then
  abertas=$(sed -n '/^## Abertas/,/^## Respondidas/p' docs/QUESTOES-ABERTAS.md | grep -cE '^\| Q-')
  echo
  echo "--- Questões abertas: $abertas (decisões do usuário; nunca decida sozinho) ---"
  sed -n '/^## Abertas/,/^## Respondidas/p' docs/QUESTOES-ABERTAS.md | grep -E '^\| Q-' | cut -d'|' -f2,3,4 | head -n 8
  [ "$abertas" -gt 8 ] && echo "  ... (veja docs/QUESTOES-ABERTAS.md)"
fi

# Melhorias críticas e altas
if [ -f docs/MELHORIAS.md ]; then
  criticas=$(grep -E '^\| M-' docs/MELHORIAS.md | grep -E '\| *crítica *\|' | grep -vcE '\| *(feita|descartada) *\|$')
  altas=$(grep -E '^\| M-' docs/MELHORIAS.md | grep -E '\| *alta *\|' | grep -vcE '\| *(feita|descartada) *\|$')
  echo
  echo "--- Melhorias abertas: $criticas crítica(s), $altas alta(s) ---"
  [ "$criticas" -gt 0 ] && grep -E '^\| M-' docs/MELHORIAS.md | grep -E '\| *crítica *\|' | cut -d'|' -f2,6 | head -n 5
fi

# Git
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo
  echo "--- git: branch $(git branch --show-current 2>/dev/null) ---"
  git log --oneline -5 2>/dev/null
  pendentes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  [ "$pendentes" -gt 0 ] && echo "Atenção: $pendentes arquivo(s) com mudanças não commitadas."
fi

echo
echo "Lembretes: responda em pt-BR; pergunte antes de decidir o que não está decidido; atualize PROGRESSO, ESPECIFICACAO e DATABASE/API/EVENTOS ao fim de cada tarefa."
exit 0
