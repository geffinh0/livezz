#!/usr/bin/env bash
# E2E no navegador: compila o app para web (debug), sobe mock-server e um
# servidor estático e roda apps/mobile/e2e/web/*.cjs com Playwright (Chromium).
# Prints e resultado em build/e2e-web/. Não precisa de Android nem emulador.
#
# Uso:  bash tools/dev/e2e-web.sh
#       E2E_ONLY='ENT08 ENT10' bash tools/dev/e2e-web.sh   (só esses fluxos)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/build/e2e-web"
TENANT="${TENANT:-liveapp}"
mkdir -p "$OUT"
PIDS=()
# Cada servidor roda no próprio grupo de processos (setsid): no fim, o grupo
# inteiro é encerrado (inclusive o node filho do npx).
trap 'for p in "${PIDS[@]:-}"; do [ -n "$p" ] && kill -- "-$p" 2>/dev/null || true; done' EXIT

echo "==> App web ($TENANT, debug)"
cd "$ROOT"
node tools/tenant/generate.mjs "$TENANT"
cd apps/mobile
flutter pub get >/dev/null
flutter gen-l10n
dart run build_runner build -d >/dev/null
flutter build web --debug --no-web-resources-cdn --no-wasm-dry-run \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=MOCK_DEV_TOKEN=dev-token-u-ana

echo "==> mock-server e servidor estático"
for port in 3000 8080; do
  if curl -s -o /dev/null "http://127.0.0.1:$port/"; then
    echo "Porta $port já está em uso (servidor antigo?). Feche-o antes: o teste rodaria contra a versão errada."
    exit 1
  fi
done
setsid bash -c "cd '$ROOT/mock-server' && PORT=3000 exec npx tsx src/main.ts" > "$OUT/mock-server.log" 2>&1 &
PIDS+=($!)
setsid bash -c "cd '$ROOT/apps/mobile/build/web' && exec python3 -m http.server 8080 --bind 127.0.0.1" > "$OUT/http.log" 2>&1 &
PIDS+=($!)
for _ in $(seq 1 30); do
  curl -sf http://127.0.0.1:3000/v1/config >/dev/null && curl -sf http://127.0.0.1:8080/ >/dev/null && break
  sleep 1
done

echo "==> Fluxos"
cd "$ROOT"
status=0
for f in apps/mobile/e2e/web/[!_]*.cjs; do
  if [ -n "${E2E_ONLY:-}" ]; then
    name="$(basename "$f" .cjs)"
    keep=0
    for want in $E2E_ONLY; do [ "${name%%-*}" = "$want" ] || [ "$name" = "$want" ] && keep=1; done
    [ $keep -eq 1 ] || continue
  fi
  echo "--- $f"
  node "$f" "$OUT" || status=1
done
echo "==> Resultado: $([ $status -eq 0 ] && echo PASSOU || echo FALHOU) (prints em $OUT)"
exit $status
