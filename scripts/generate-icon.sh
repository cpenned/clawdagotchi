#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ICONSET_DIR="/tmp/AppIcon.iconset"
ICON_OUTPUT="$PROJECT_DIR/AppIcon.icns"

# Write the Swift CoreGraphics script to /tmp
cat > /tmp/generate_icon.swift << 'SWIFT_EOF'
import CoreGraphics
import AppKit
import Foundation

let size = 1024
let canvas = CGFloat(size)

// CrabView geometry: viewBox 66w x 52h
let viewW: CGFloat = 66
let viewH: CGFloat = 52

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create CGContext")
    exit(1)
}

// Flip coordinate system so origin is top-left
ctx.translateBy(x: 0, y: canvas)
ctx.scaleBy(x: 1, y: -1)

// Draw rounded square background: salmon/coral #D97757
let cornerRadius = canvas * 0.22
let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: canvas, height: canvas),
                    cornerWidth: cornerRadius, cornerHeight: cornerRadius,
                    transform: nil)
ctx.setFillColor(red: 0xD9/255.0, green: 0x77/255.0, blue: 0x57/255.0, alpha: 1.0)
ctx.addPath(bgPath)
ctx.fillPath()

// Scale crab to ~60% of canvas, centered
let crabScale = canvas * 0.6 / viewW
let xOff = (canvas - viewW * crabScale) / 2
let yOff = (canvas - viewH * crabScale) / 2

func fillRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, r: CGFloat, g: CGFloat, b: CGFloat) {
    ctx.setFillColor(red: r, green: g, blue: b, alpha: 1.0)
    ctx.fill(CGRect(x: xOff + x * crabScale, y: yOff + y * crabScale, width: w * crabScale, height: h * crabScale))
}

let bodyColor: (CGFloat, CGFloat, CGFloat) = (0xFF/255.0, 0xF5/255.0, 0xED/255.0)
let eyeColor: (CGFloat, CGFloat, CGFloat) = (0xD9/255.0, 0x77/255.0, 0x57/255.0)

// Antennae
fillRect(0, 13, 6, 13, r: bodyColor.0, g: bodyColor.1, b: bodyColor.2)
fillRect(60, 13, 6, 13, r: bodyColor.0, g: bodyColor.1, b: bodyColor.2)

// Body
fillRect(6, 0, 54, 39, r: bodyColor.0, g: bodyColor.1, b: bodyColor.2)

// Legs (4)
for lx: CGFloat in [6, 18, 42, 54] {
    fillRect(lx, 39, 6, 13, r: bodyColor.0, g: bodyColor.1, b: bodyColor.2)
}

// Eyes
fillRect(14, 12, 6, 7, r: eyeColor.0, g: eyeColor.1, b: eyeColor.2)
fillRect(46, 12, 6, 7, r: eyeColor.0, g: eyeColor.1, b: eyeColor.2)

guard let image = ctx.makeImage() else {
    print("Failed to create CGImage")
    exit(1)
}

let outputURL = URL(fileURLWithPath: "/tmp/AppIcon_1024.png")
guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, "public.png" as CFString, 1, nil) else {
    print("Failed to create image destination")
    exit(1)
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    print("Failed to write PNG")
    exit(1)
}
print("Icon written to \(outputURL.path)")
SWIFT_EOF

echo "Running Swift icon generator..."
swift /tmp/generate_icon.swift

echo "Creating .iconset folder..."
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Helper: resize using sips
resize_icon() {
    local size=$1
    local filename=$2
    sips -z "$size" "$size" /tmp/AppIcon_1024.png --out "$ICONSET_DIR/$filename" > /dev/null
}

resize_icon 16   "icon_16x16.png"
resize_icon 32   "icon_16x16@2x.png"
resize_icon 32   "icon_32x32.png"
resize_icon 64   "icon_32x32@2x.png"
resize_icon 128  "icon_128x128.png"
resize_icon 256  "icon_128x128@2x.png"
resize_icon 256  "icon_256x256.png"
resize_icon 512  "icon_256x256@2x.png"
resize_icon 512  "icon_512x512.png"
resize_icon 1024 "icon_512x512@2x.png"

echo "Running iconutil..."
iconutil -c icns "$ICONSET_DIR" -o "$ICON_OUTPUT"

echo "AppIcon.icns created at: $ICON_OUTPUT"
