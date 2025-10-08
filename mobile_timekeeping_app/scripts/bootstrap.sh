#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "[bootstrap] App dir: $APP_DIR"

if ! command -v flutter >/dev/null 2>&1; then
  echo "[bootstrap] 'flutter' not found in PATH."
  # Try common locations or FLUTTER_HOME
  if [[ -n "${FLUTTER_HOME:-}" && -x "$FLUTTER_HOME/bin/flutter" ]]; then
    export PATH="$FLUTTER_HOME/bin:$PATH"
    echo "[bootstrap] Using FLUTTER_HOME=$FLUTTER_HOME"
  elif [[ -d "$HOME/development/flutter/bin" ]]; then
    export PATH="$HOME/development/flutter/bin:$PATH"
    echo "[bootstrap] Using ~/development/flutter/bin"
  elif [[ -d "/Applications/flutter/bin" ]]; then
    export PATH="/Applications/flutter/bin:$PATH"
    echo "[bootstrap] Using /Applications/flutter/bin"
  else
    echo "[bootstrap] Please install Flutter and ensure it's on PATH. See https://docs.flutter.dev/get-started/install"
    exit 1
  fi
fi

echo "[bootstrap] Flutter: $(flutter --version | head -n 1)"

pushd "$APP_DIR" >/dev/null
if [[ ! -d android || ! -d ios || ! -f pubspec.lock ]]; then
  echo "[bootstrap] Running 'flutter create .' to generate missing platform files and scaffolding"
  flutter create .
fi

flutter pub get
echo "[bootstrap] Done. You can now run 'flutter run' inside $APP_DIR"
popd >/dev/null
