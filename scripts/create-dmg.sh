#!/bin/bash
# Build Clawdagotchi and create a distributable DMG
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Clawdagotchi"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
RELEASE_DIR="$PROJECT_DIR/releases"

# Get version from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PROJECT_DIR/Info.plist")
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.dmg"

echo "=== Building $APP_NAME v$VERSION ==="
echo ""

# Clean and build release binary
cd "$PROJECT_DIR"
swift build -c release 2>&1

BINARY="$PROJECT_DIR/.build/release/$APP_NAME"
if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found at $BINARY"
    exit 1
fi

# Assemble .app bundle
echo "Assembling $APP_NAME.app..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp "$BINARY" "$APP_PATH/Contents/MacOS/$APP_NAME"
cp "$PROJECT_DIR/Info.plist" "$APP_PATH/Contents/"

if [ -f "$PROJECT_DIR/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/AppIcon.icns" "$APP_PATH/Contents/Resources/"
fi

echo "App bundle: $APP_PATH"
echo ""

# Code sign with Developer ID (or fall back to ad-hoc)
SIGN_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/')
if [ -n "$SIGN_IDENTITY" ]; then
    echo "Code signing with: $SIGN_IDENTITY"
    codesign --force --deep --options runtime \
        --entitlements "$PROJECT_DIR/Clawdagotchi.entitlements" \
        --sign "$SIGN_IDENTITY" "$APP_PATH"
else
    echo "Code signing (ad-hoc — no Developer ID found)..."
    codesign --force --deep --sign - "$APP_PATH"
fi
echo ""

# Create DMG
echo "=== Creating DMG ==="
mkdir -p "$RELEASE_DIR"
rm -f "$DMG_PATH"

# Stage folder with app + Applications symlink
STAGE_DIR="$BUILD_DIR/dmg-stage"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
cp -r "$APP_PATH" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

BG_IMG="$SCRIPT_DIR/dmg_background.png"

if command -v create-dmg &> /dev/null && [ -f "$BG_IMG" ]; then
    echo "Using create-dmg with background..."
    create-dmg \
        --volname "$APP_NAME" \
        --window-size 600 400 \
        --background "$BG_IMG" \
        --icon-size 120 \
        --icon "$APP_NAME.app" 150 210 \
        --icon "Applications" 450 210 \
        --hide-extension "$APP_NAME.app" \
        --text-size 14 \
        "$DMG_PATH" \
        "$STAGE_DIR" || true
fi

if [ ! -f "$DMG_PATH" ]; then
    echo "Falling back to hdiutil..."
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$STAGE_DIR" \
        -ov -format UDZO \
        "$DMG_PATH"
fi

rm -rf "$STAGE_DIR"

# Also create stable-named copy for direct download links
STABLE_DMG="$RELEASE_DIR/$APP_NAME.dmg"
cp "$DMG_PATH" "$STABLE_DMG"

echo ""
echo "=== Done ==="
echo ""
echo "DMG: $DMG_PATH"
echo "Stable: $STABLE_DMG"
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
echo "To release:"
echo "  gh release create v$VERSION $DMG_PATH $STABLE_DMG --title \"Clawdagotchi v$VERSION\""
echo ""
echo "To test: open $DMG_PATH"
