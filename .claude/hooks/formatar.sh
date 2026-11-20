#!/usr/bin/env bash
# PostToolUse (Edit|Write): formata o arquivo que o Claude acabou de editar.
# Requer jq. Dart/Flutter para .dart; Node (prettier instalado no projeto) para TS/JS/JSON/CSS.
# Markdown não é formatado de propósito, para não bagunçar tabelas dos docs.

arquivo=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$arquivo" ] && exit 0
[ -f "$arquivo" ] || exit 0

case "$arquivo" in
  *.dart)
    command -v dart >/dev/null 2>&1 && dart format "$arquivo" >/dev/null 2>&1 ;;
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css)
    dir=$(dirname "$arquivo")
    (cd "$dir" && npx --no-install prettier --write "$arquivo" >/dev/null 2>&1) ;;
esac
exit 0
