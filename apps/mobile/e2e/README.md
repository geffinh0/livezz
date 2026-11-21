# Testes E2E (Maestro)

Rodam na **sua máquina**, com um celular Android (depuração USB) ou emulador.
Cada item de tela da especificação ganha um arquivo `e2e/<ID>.yaml`.

## Uma vez
1. Flutter estável, Android Studio/SDK e `adb` funcionando (`flutter doctor`).
2. Maestro: `curl -fsSL "https://get.maestro.mobile.dev" | bash` e confira com `maestro --version`.
3. Na raiz do repositório: `npm ci`.

## Toda vez
Terminal 1 — mock-server:
```bash
cd mock-server && npm run dev
```
Terminal 2 — app no celular (o `adb reverse` faz o `localhost` do celular apontar para o seu computador):
```bash
adb reverse tcp:3000 tcp:3000
```
```bash
cd apps/mobile && node ../../tools/tenant/generate.mjs && flutter pub get && flutter gen-l10n && dart run build_runner build -d
```
```bash
flutter run --flavor liveapp -t lib/main.dart --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=MOCK_DEV_TOKEN=dev-token-u-ana
```
Terminal 3 — fluxos (com o app instalado pelo passo anterior):
```bash
cd apps/mobile && maestro test e2e/
```

No emulador, use `http://10.0.2.2:3000` no lugar de `localhost` (e dispense o `adb reverse`).
`MOCK_DEV_TOKEN` só funciona em build debug e só no mock-server (Fase 0, antes do login real).
