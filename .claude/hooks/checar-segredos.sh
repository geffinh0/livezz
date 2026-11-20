#!/usr/bin/env bash
# PostToolUse (Edit|Write): procura padrões de segredo no arquivo recém-editado.
# Se achar, devolve código 2 com a explicação para o Claude remover o segredo.

arquivo=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$arquivo" ] && exit 0
[ -f "$arquivo" ] || exit 0

case "$arquivo" in
  *.env.example|*google-services.json|*/.claude/hooks/checar-segredos.sh|*.png|*.jpg|*.webp|*.mp4|*.json.lottie) exit 0 ;;
esac

achados=$(grep -nIE \
  -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
  -e 'AKIA[0-9A-Z]{16}' \
  -e 'sk_live_[0-9A-Za-z]{16,}' \
  -e 'xox[abpr]-[0-9A-Za-z-]{10,}' \
  -e '(app_?certificate|appcertificate|client_?secret|private_?key|api_?secret|secret_?key)["'"'"' ]*[:=] *["'"'"'][^"'"'"' ]{16,}["'"'"']' \
  -i "$arquivo" 2>/dev/null | head -n 5)

if [ -n "$achados" ]; then
  {
    echo "Possível segredo em $arquivo:"
    echo "$achados" | cut -c1-160
    echo "Segredos nunca entram no código, fixtures, docs ou app. Use variável de ambiente no servidor e .env.example sem valores. Se for um valor falso de teste, troque por algo obviamente falso (ex.: TEST_ONLY_xxx)."
  } >&2
  exit 2
fi
exit 0
