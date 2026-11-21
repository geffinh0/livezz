#!/usr/bin/env bash
# Prepara um computador Linux (Ubuntu/Debian) para desenvolver e testar o app.
# Instala: pacotes do sistema, Node 22 (nvm), Flutter 3.50.1, Android SDK +
# emulador (sem Android Studio), Maestro e Claude Code; cria o emulador
# "livezz_pixel"; clona o repositório e baixa as dependências.
# Pode rodar de novo: o que já existe é pulado.
#
# Uso:  bash setup-linux.sh            (pasta padrão: ~/projetos/livezz)
#       PROJECT_DIR=~/outra bash setup-linux.sh
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.50.1}"
ANDROID_API="${ANDROID_API:-36}"
CMDLINE_TOOLS_REV="${CMDLINE_TOOLS_REV:-13114758}"
AVD_NAME="${AVD_NAME:-livezz_pixel}"
PROJECT_DIR="${PROJECT_DIR:-$HOME/projetos/livezz}"
REPO_URL="${REPO_URL:-https://github.com/geffinh0/livezz.git}"
BRANCH="${BRANCH:-claude/funny-darwin-w671g8}"
DEV="$HOME/development"
export ANDROID_HOME="$DEV/android-sdk"

passo() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
aviso() { printf '\033[1;33m[aviso]\033[0m %s\n' "$*"; }

[ "$(id -u)" -eq 0 ] && { echo "Rode como seu usuário normal (o script pede sudo quando precisar)."; exit 1; }
command -v apt-get >/dev/null || { echo "Este script é para Ubuntu/Debian (apt)."; exit 1; }

passo "1/8 Pacotes do sistema"
sudo apt-get update -y
sudo apt-get install -y git curl unzip xz-utils zip jq libglu1-mesa openjdk-17-jdk \
  qemu-kvm libvirt-daemon-system cpu-checker clang cmake ninja-build pkg-config libgtk-3-dev
if [ -e /dev/kvm ]; then
  sudo usermod -aG kvm "$USER" || true
else
  aviso "Sem /dev/kvm: ative a virtualização (VT-x/AMD-V) na BIOS, senão o emulador fica muito lento."
fi

passo "2/8 Node 22 (nvm)"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"
nvm install 22 >/dev/null && nvm alias default 22 >/dev/null

passo "3/8 Flutter $FLUTTER_VERSION"
mkdir -p "$DEV"
if [ ! -x "$DEV/flutter/bin/flutter" ]; then
  curl -fL -o /tmp/flutter.tar.xz \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tar -xf /tmp/flutter.tar.xz -C "$DEV" && rm /tmp/flutter.tar.xz
fi
export PATH="$DEV/flutter/bin:$PATH"
flutter --disable-analytics >/dev/null 2>&1 || true

passo "4/8 Android SDK, emulador e imagem Android $ANDROID_API"
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  curl -fL -o /tmp/cmdline-tools.zip \
    "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_REV}_latest.zip"
  unzip -q -o /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-unzip && rm /tmp/cmdline-tools.zip
  mv /tmp/cmdline-tools-unzip/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
fi
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
yes | sdkmanager --licenses >/dev/null || true
sdkmanager "platform-tools" "emulator" "platforms;android-${ANDROID_API}" \
  "build-tools;${ANDROID_API}.0.0" "system-images;android-${ANDROID_API};google_apis;x86_64"
flutter config --android-sdk "$ANDROID_HOME" >/dev/null
yes | flutter doctor --android-licenses >/dev/null 2>&1 || true

passo "5/8 Emulador $AVD_NAME"
if ! avdmanager list avd 2>/dev/null | grep -q "Name: $AVD_NAME"; then
  echo no | avdmanager create avd -n "$AVD_NAME" -d pixel_7 \
    -k "system-images;android-${ANDROID_API};google_apis;x86_64"
fi

passo "6/8 Maestro e Claude Code"
command -v maestro >/dev/null || [ -x "$HOME/.maestro/bin/maestro" ] || curl -fsSL "https://get.maestro.mobile.dev" | bash
command -v claude >/dev/null || [ -x "$HOME/.local/bin/claude" ] || curl -fsSL https://claude.ai/install.sh | bash

passo "7/8 Variáveis no ~/.bashrc"
MARK="# >>> livezz dev >>>"
if ! grep -qF "$MARK" "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" <<RC
$MARK
export ANDROID_HOME="$ANDROID_HOME"
export PATH="$DEV/flutter/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator:\$HOME/.maestro/bin:\$HOME/.local/bin:\$PATH"
# <<< livezz dev <<<
RC
fi
export PATH="$HOME/.maestro/bin:$HOME/.local/bin:$PATH"

passo "8/8 Repositório e dependências ($PROJECT_DIR)"
if [ ! -d "$PROJECT_DIR/.git" ]; then
  mkdir -p "$(dirname "$PROJECT_DIR")"
  git clone "$REPO_URL" "$PROJECT_DIR"
fi
cd "$PROJECT_DIR"
git fetch origin "$BRANCH" && git checkout "$BRANCH" && git pull --ff-only origin "$BRANCH"
npm ci
node tools/tenant/generate.mjs
(cd apps/mobile && flutter pub get && flutter gen-l10n && dart run build_runner build -d)

passo "Pronto. Conferência:"
node --version; flutter --version | head -1; adb --version | head -1
maestro --version 2>/dev/null || true; claude --version 2>/dev/null || true
flutter doctor || true
cat <<FIM

Próximos passos:
  1) Abra um terminal novo (ou: source ~/.bashrc).
  2) Se foi adicionado ao grupo kvm agora, saia e entre na sessão do Linux.
  3) Teste tudo:  bash $PROJECT_DIR/tools/dev/e2e-emulador.sh
  4) Para o Claude usar este computador:  cd $PROJECT_DIR && claude remote-control
FIM
