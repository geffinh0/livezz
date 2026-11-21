# Testes E2E

## No navegador (mais rápido; não precisa de Android)
O app também compila para web. `bash tools/dev/e2e-web.sh` compila, sobe o mock-server e roda os fluxos de `e2e/web/` com Playwright (Chromium), com prints em `build/e2e-web/`. Roda no CI a cada push. Cobre telas, tema, idiomas, config, tempo real e erros; **não** cobre o que é só do Android (flavor, permissões, câmera, vídeo nativo): isso fica com o Maestro abaixo.

# Testes E2E no Android (Maestro)

Rodam na **sua máquina**, com um celular Android (depuração USB) ou emulador.
Cada item de tela da especificação ganha um arquivo `e2e/<ID>.yaml`.

## Atalho no Linux (Ubuntu/Debian)
- Instalar tudo uma vez: `bash tools/dev/setup-linux.sh` (Flutter, Android SDK + emulador, Node, Maestro, Claude Code).
- Testar tudo: `bash tools/dev/e2e-emulador.sh` (sobe emulador e mock-server, instala o app e roda os fluxos; relatório e prints em `build/e2e/`).

## Uma vez (manual)
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
