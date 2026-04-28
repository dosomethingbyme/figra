#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Figra.app"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$ROOT_DIR/$APP_NAME"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES" "$BUILD_DIR"

swiftc "$ROOT_DIR/Sources/PDFImageExtractor.swift" \
  -target arm64-apple-macosx13.0 \
  -framework AppKit \
  -framework UniformTypeIdentifiers \
  -o "$MACOS/PDFImageExtractor"

cp "$ROOT_DIR/Info.plist" "$CONTENTS/Info.plist"
if [[ -f "$ROOT_DIR/Resources/pdffigures2.jar" ]]; then
  cp "$ROOT_DIR/Resources/pdffigures2.jar" "$RESOURCES/pdffigures2.jar"
fi
if [[ -d "$ROOT_DIR/Resources/jre" ]]; then
  ditto "$ROOT_DIR/Resources/jre" "$RESOURCES/jre"
fi
if [[ -f "$ROOT_DIR/Resources/AppIcon.icns" ]]; then
  cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi
chmod +x "$MACOS/PDFImageExtractor"
if [[ -f "$RESOURCES/jre/bin/java" ]]; then
  chmod +x "$RESOURCES/jre/bin/java"
fi

echo "$APP_DIR"
