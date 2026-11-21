#!/usr/bin/env bash
# Sobe emulador + mock-server, instala o app (flavor liveapp, debug) e roda o
# Maestro. Ao final, deixa prints em build/e2e/. Rode da raiz do repositório.
#
# Uso:  bash tools/dev/e2e-emulador.sh                (todos os fluxos de e2e/)
#       bash tools/dev/e2e-emulador.sh e2e/TRV-fundacao.yaml
#       HEADLESS=1 bash tools/dev/e2e-emulador.sh     (emulador sem janela)
#       KEEP=1 bash tools/dev/e2e-emulador.sh         (não desliga nada no fim)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AVD_NAME="${AVD_NAME:-livezz_pixel}"
TENANT="${TENANT:-liveapp}"
OUT="$ROOT/build/e2e"
FLOWS="${1:-e2e/}"
mkdir -p "$OUT"
free -h | head -2 || true
PIDS=()

limpar() {
  [ "${KEEP:-0}" = "1" ] && return
  for p in "${PIDS[@]:-}"; do [ -n "$p" ] && kill "$p" 2>/dev/null || true; done
  adb emu kill >/dev/null 2>&1 || true
}
trap limpar EXIT

passo() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }

passo "App ($TENANT, debug)"
cd "$ROOT"
node tools/tenant/generate.mjs "$TENANT"
cd apps/mobile
flutter pub get >/dev/null
flutter gen-l10n
dart run build_runner build -d >/dev/null
flutter build apk --debug --flavor "$TENANT" -t lib/main.dart \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=MOCK_DEV_TOKEN=dev-token-u-ana
APK="$ROOT/apps/mobile/build/app/outputs/flutter-apk/app-$TENANT-debug.apk"
# Libera a memória do Gradle antes de ligar o emulador.
(cd android && ./gradlew --stop >/dev/null 2>&1) || true
cd "$ROOT"


passo "Emulador ($AVD_NAME)"
if ! adb devices | grep -q "emulator-"; then
  args=(-avd "$AVD_NAME" -no-snapshot-save -no-audio -no-boot-anim -memory "${EMU_RAM_MB:-2048}")
  [ "${HEADLESS:-0}" = "1" ] && args+=(-no-window)
  emulator "${args[@]}" > "$OUT/emulator.log" 2>&1 &
  PIDS+=($!)
fi
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 2; done
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
adb reverse tcp:3000 tcp:3000

# O boot termina antes do serviço de instalação estar pronto em emuladores lentos.
for _ in $(seq 1 60); do adb shell cmd package list packages >/dev/null 2>&1 && break; sleep 3; done
instalado=""
for tentativa in 1 2 3 4 5; do
  if adb install -r "$APK"; then instalado=1; break; fi
  echo "instalação falhou (tentativa $tentativa); tentando de novo em 10 s..."
  sleep 10
done
[ -n "$instalado" ] || { echo "Não consegui instalar o APK."; exit 1; }

passo "mock-server"
if ! curl -sf http://127.0.0.1:3000/v1/config >/dev/null; then
  (cd "$ROOT/mock-server" && PORT=3000 npx tsx src/main.ts > "$OUT/mock-server.log" 2>&1) &
  PIDS+=($!)
  for _ in $(seq 1 30); do curl -sf http://127.0.0.1:3000/v1/config >/dev/null && break; sleep 1; done
fi
curl -sf http://127.0.0.1:3000/v1/config >/dev/null || { cat "$OUT/mock-server.log"; exit 1; }

passo "Maestro: $FLOWS"
status=0
cd "$ROOT/apps/mobile"
maestro test --format junit --output "$OUT/maestro-report.xml" \
  --test-output-dir "$OUT/maestro" "$FLOWS" || status=$?
adb exec-out screencap -p > "$OUT/final.png" || true

passo "Resultado: $([ $status -eq 0 ] && echo PASSOU || echo FALHOU) (relatório e prints em $OUT)"
exit $status
