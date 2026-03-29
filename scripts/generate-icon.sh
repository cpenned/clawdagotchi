#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ICONSET_DIR="/tmp/AppIcon.iconset"
ICON_OUTPUT="$PROJECT_DIR/AppIcon.icns"

cat > /tmp/generate_icon.swift << 'SWIFT_EOF'
import CoreGraphics
import AppKit
import Foundation

let size = 1024
let canvas = CGFloat(size)

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { exit(1) }

ctx.translateBy(x: 0, y: canvas)
ctx.scaleBy(x: 1, y: -1)

// macOS icon rounded rect background — salmon orange #D97757
let bgCorner = canvas * 0.22
let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: canvas, height: canvas),
                    cornerWidth: bgCorner, cornerHeight: bgCorner, transform: nil)
ctx.setFillColor(red: 0xD9/255.0, green: 0x77/255.0, blue: 0x57/255.0, alpha: 1.0)
ctx.addPath(bgPath)
ctx.fillPath()

// --- Egg shell ---
let eggCX = canvas / 2
let eggCY = canvas / 2
let eggW = canvas * 0.62
let eggH = canvas * 0.72

// Egg shape via bezier — narrower top, wider bottom
func eggPath() -> CGMutablePath {
    let p = CGMutablePath()
    let t = eggCY - eggH / 2  // top
    let b = eggCY + eggH / 2  // bottom
    let l = eggCX - eggW / 2  // left at widest
    let r = eggCX + eggW / 2  // right at widest

    p.move(to: CGPoint(x: eggCX, y: t))
    // top-right (tighter curve)
    p.addCurve(to: CGPoint(x: r, y: eggCY + eggH * 0.02),
               control1: CGPoint(x: eggCX + eggW * 0.30, y: t),
               control2: CGPoint(x: r, y: eggCY - eggH * 0.28))
    // bottom-right
    p.addCurve(to: CGPoint(x: eggCX, y: b),
               control1: CGPoint(x: r, y: eggCY + eggH * 0.32),
               control2: CGPoint(x: eggCX + eggW * 0.32, y: b))
    // bottom-left
    p.addCurve(to: CGPoint(x: l, y: eggCY + eggH * 0.02),
               control1: CGPoint(x: eggCX - eggW * 0.32, y: b),
               control2: CGPoint(x: l, y: eggCY + eggH * 0.32))
    // top-left (tighter curve)
    p.addCurve(to: CGPoint(x: eggCX, y: t),
               control1: CGPoint(x: l, y: eggCY - eggH * 0.28),
               control2: CGPoint(x: eggCX - eggW * 0.30, y: t))
    p.closeSubpath()
    return p
}

// Egg shell — salmon pink gradient (light top-left, dark bottom-right)
ctx.saveGState()
ctx.addPath(eggPath())
ctx.clip()

// Gradient: shellPinkLight → shellPink → shellPinkDark
let gradColors = [
    CGColor(red: 0xF8/255.0, green: 0xB0/255.0, blue: 0xA0/255.0, alpha: 1.0),
    CGColor(red: 0xF0/255.0, green: 0x90/255.0, blue: 0x80/255.0, alpha: 1.0),
    CGColor(red: 0xC8/255.0, green: 0x6A/255.0, blue: 0x58/255.0, alpha: 1.0),
]
let grad = CGGradient(colorsSpace: colorSpace, colors: gradColors as CFArray, locations: [0, 0.5, 1])!
ctx.drawLinearGradient(grad,
    start: CGPoint(x: eggCX - eggW * 0.4, y: eggCY - eggH * 0.4),
    end: CGPoint(x: eggCX + eggW * 0.4, y: eggCY + eggH * 0.4),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
ctx.restoreGState()

// Subtle edge highlight
ctx.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 0.25)
ctx.setLineWidth(3)
ctx.addPath(eggPath())
ctx.strokePath()

// --- Black crab centered on egg ---
let viewW: CGFloat = 66
let viewH: CGFloat = 52
let crabScale = canvas * 0.45 / viewW
let crabXOff = eggCX - (viewW * crabScale) / 2
let crabYOff = eggCY - (viewH * crabScale) / 2 - canvas * 0.04

func crabRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
    ctx.setFillColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
    ctx.fill(CGRect(x: crabXOff + x * crabScale, y: crabYOff + y * crabScale,
                    width: w * crabScale, height: h * crabScale))
}

// Antennae
crabRect(0, 13, 6, 13)
crabRect(60, 13, 6, 13)
// Body
crabRect(6, 0, 54, 39)
// Legs
for lx: CGFloat in [6, 18, 42, 54] {
    crabRect(lx, 39, 6, 13)
}
// Eyes (cutout — use egg gradient color as approximation)
ctx.setFillColor(red: 0xF0/255.0, green: 0x90/255.0, blue: 0x80/255.0, alpha: 1.0)
ctx.fill(CGRect(x: crabXOff + 14 * crabScale, y: crabYOff + 12 * crabScale, width: 6 * crabScale, height: 7 * crabScale))
ctx.fill(CGRect(x: crabXOff + 46 * crabScale, y: crabYOff + 12 * crabScale, width: 6 * crabScale, height: 7 * crabScale))

// --- Three black buttons below crab ---
let btnY = crabYOff + viewH * crabScale + canvas * 0.06
let btnR: CGFloat = canvas * 0.022
let btnSpacing = canvas * 0.055
for i in -1...1 {
    let bx = eggCX + CGFloat(i) * btnSpacing
    let btnPath = CGPath(ellipseIn: CGRect(x: bx - btnR, y: btnY - btnR, width: btnR * 2, height: btnR * 2), transform: nil)
    ctx.setFillColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0)
    ctx.addPath(btnPath)
    ctx.fillPath()
}

guard let image = ctx.makeImage() else { exit(1) }
let outputURL = URL(fileURLWithPath: "/tmp/AppIcon_1024.png")
guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, "public.png" as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { exit(1) }
print("Icon written to \(outputURL.path)")
SWIFT_EOF

echo "Running Swift icon generator..."
swift /tmp/generate_icon.swift

echo "Creating .iconset folder..."
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

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
