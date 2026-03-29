#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Clawdagotchi"
APP_BUNDLE="${SCRIPT_DIR}/${APP_NAME}.app"

echo "Building ${APP_NAME} (release)..."
cd "$SCRIPT_DIR"
swift build -c release 2>&1

BINARY="${SCRIPT_DIR}/.build/release/${APP_NAME}"
if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found at ${BINARY}"
    exit 1
fi

echo "Assembling ${APP_NAME}.app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "$BINARY" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "${SCRIPT_DIR}/Info.plist" "${APP_BUNDLE}/Contents/"

if [ -f "${SCRIPT_DIR}/AppIcon.icns" ]; then
    cp "${SCRIPT_DIR}/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"
    echo "  Included app icon"
fi

echo ""
echo "Built: ${APP_BUNDLE}"
echo ""
echo "To run:  open ${APP_BUNDLE}"
echo "To install: cp -r ${APP_BUNDLE} /Applications/"
