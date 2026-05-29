#!/usr/bin/env bash
# Builds Zzan.app from the SwiftPM executable and ad-hoc signs it.
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

readonly APP_NAME="zzan"
readonly SWIFT_TARGET="Zzan"
readonly CONFIG="release"
readonly BUILD_ROOT="build"
readonly APP_DIR="${BUILD_ROOT}/${APP_NAME}.app"

log() {
  printf '==> %s\n' "$1"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'error: required command not found: %s\n' "$1" >&2
    exit 1
  fi
}

require_command swift
require_command codesign

log "Compiling (${CONFIG})..."
swift build -c "$CONFIG"

BUILD_BIN="$(swift build -c "$CONFIG" --show-bin-path)/${SWIFT_TARGET}"
if [[ ! -x "$BUILD_BIN" ]]; then
  printf 'error: expected executable not found: %s\n' "$BUILD_BIN" >&2
  exit 1
fi

log "Assembling ${APP_DIR}..."
rm -rf "$APP_DIR"
install -d "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"

install -m 755 "$BUILD_BIN" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_DIR}/Contents/Info.plist"

log "Ad-hoc signing..."
codesign --force --deep --sign - "$APP_DIR"

log "Done: ${APP_DIR}"
printf '    Run with: open "%s"\n' "$APP_DIR"
