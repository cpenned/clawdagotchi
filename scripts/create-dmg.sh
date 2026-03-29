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

# Ad-hoc code sign (allows Gatekeeper to identify the app)
echo "Code signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_PATH"
echo ""

# Create DMG
echo "=== Creating DMG ==="
mkdir -p "$RELEASE_DIR"

# Remove existing DMG
rm -f "$DMG_PATH"

if command -v create-dmg &> /dev/null; then
    echo "Using create-dmg..."
    create-dmg \
        --volname "$APP_NAME" \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 150 200 \
        --app-drop-link 450 200 \
        --hide-extension "$APP_NAME.app" \
        "$DMG_PATH" \
        "$APP_PATH" || true

    # create-dmg returns non-zero if no signing identity, but DMG is still created
    if [ ! -f "$DMG_PATH" ]; then
        echo "create-dmg failed, falling back to hdiutil..."
        hdiutil create -volname "$APP_NAME" \
            -srcfolder "$APP_PATH" \
            -ov -format UDZO \
            "$DMG_PATH"
    fi
else
    echo "Using hdiutil (install create-dmg for prettier DMG: brew install create-dmg)"
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$APP_PATH" \
        -ov -format UDZO \
        "$DMG_PATH"
fi

echo ""
echo "=== Done ==="
echo ""
echo "DMG: $DMG_PATH"
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
echo "To test: open $DMG_PATH"
echo ""
echo "Note: This DMG is ad-hoc signed. For distribution without"
echo "Gatekeeper warnings, sign with a Developer ID certificate:"
echo "  codesign --force --deep --sign \"Developer ID Application: ...\" $APP_PATH"
echo "  xcrun notarytool submit $DMG_PATH --keychain-profile \"...\" --wait"
