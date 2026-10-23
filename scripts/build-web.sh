#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not on PATH. Install Flutter 3.24 or newer, then run this script again." >&2
  exit 1
fi

flutter pub get
flutter build web --release --no-wasm-dry-run --output "$ROOT/hosting"
echo "Web bundle written to $ROOT/hosting"
