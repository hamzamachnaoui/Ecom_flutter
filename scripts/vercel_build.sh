#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="${HOME}/flutter_sdk"

if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -d "${FLUTTER_DIR}" ]; then
    echo "Installing Flutter SDK (stable) for Vercel build..."
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
  fi
  export PATH="${FLUTTER_DIR}/bin:${PATH}"
fi

if [ "${1:-}" = "--install-only" ]; then
  flutter --version
  flutter config --enable-web --no-analytics
  flutter pub get
  exit 0
fi

flutter pub get

BUILD_ARGS=(build web --release --base-href "/")
if [ -n "${API_BASE_URL:-}" ]; then
  echo "Using API_BASE_URL from Vercel environment..."
  BUILD_ARGS+=("--dart-define=API_BASE_URL=${API_BASE_URL}")
fi

flutter "${BUILD_ARGS[@]}"

