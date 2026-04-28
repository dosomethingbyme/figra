#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Figra.app"
DMG_NAME="Figra.dmg"
SIGNING_STAGING="/tmp/pdf2figure-dmg-staging"

"$ROOT_DIR/build_app.sh" >/dev/null

rm -rf "$SIGNING_STAGING"
mkdir -p "$SIGNING_STAGING"
ditto "$ROOT_DIR/$APP_NAME" "$SIGNING_STAGING/$APP_NAME"
ln -s /Applications "$SIGNING_STAGING/Applications"

chmod -R u+w "$SIGNING_STAGING/$APP_NAME"
xattr -cr "$SIGNING_STAGING/$APP_NAME"
xattr -d com.apple.FinderInfo "$SIGNING_STAGING/$APP_NAME" 2>/dev/null || true
codesign --force --deep --sign - "$SIGNING_STAGING/$APP_NAME"
codesign --verify --deep --strict "$SIGNING_STAGING/$APP_NAME"

rm -f "$ROOT_DIR/$DMG_NAME"
hdiutil create \
  -volname "Figra" \
  -srcfolder "$SIGNING_STAGING" \
  -ov \
  -format UDZO \
  "$ROOT_DIR/$DMG_NAME" >/dev/null

echo "$ROOT_DIR/$DMG_NAME"
