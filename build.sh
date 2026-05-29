#!/usr/bin/env bash
# Builds Zzan.app from the SwiftPM executable and ad-hoc signs it.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Zzan"
CONFIG="release"
BUILD_BIN=".build/${CONFIG}/${APP_NAME}"
APP_DIR="build/${APP_NAME}.app"

echo "==> Compiling ($CONFIG)…"
swift build -c "$CONFIG"

echo "==> Assembling ${APP_DIR}…"
rm -rf "$APP_DIR"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "$BUILD_BIN" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_DIR}/Contents/Info.plist"

echo "==> Ad-hoc signing…"
codesign --force --deep --sign - "$APP_DIR"

echo "==> Done: ${APP_DIR}"
echo "    Run with: open \"${APP_DIR}\""
