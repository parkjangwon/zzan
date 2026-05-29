#!/usr/bin/env bash
# Builds Zzan.app, wraps it in a DMG, and creates a GitHub release.
set -euo pipefail

cd "$(dirname "$0")"

VERSION="${1:-1.0.0}"
APP_NAME="zzan"
APP_PATH="build/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="build/${DMG_NAME}"

echo "==> Building ${APP_NAME}.app…"
./build.sh

echo "==> Creating ${DMG_NAME}…"
rm -f "$DMG_PATH"

# Staging folder
STAGE=$(mktemp -d)
cp -R "$APP_PATH" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"

hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGE"
echo "==> Built: ${DMG_PATH}"

echo "==> Creating GitHub release v${VERSION}…"
git tag -f "v${VERSION}"
git push origin "v${VERSION}"

gh release create "v${VERSION}" \
  "$DMG_PATH" \
  --title "zzan v${VERSION}" \
  --notes "## Install
Download \`${DMG_NAME}\`, open it, drag **Zzan.app** to Applications.

## Requirements
macOS 15 or later. On first use, macOS may download the on-device language model for your language.

## What's new
- Initial release
- Global hotkey opens a minimal input panel
- Type in any language → Enter → English translation copied to clipboard
- Shift+Enter for newline, Esc to cancel
- Source language: auto-detect or fixed
- History: last 10 translations in the menu bar
- Launch at login option"

echo "==> Done: https://github.com/parkjangwon/zzan/releases/tag/v${VERSION}"
