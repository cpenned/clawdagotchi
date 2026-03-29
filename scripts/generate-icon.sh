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

// Dark internal cavity
ctx.saveGState()
ctx.addPath(eggPath())
ctx.clip()
ctx.setFillColor(red: 0x08/255.0, green: 0x08/255.0, blue: 0x08/255.0, alpha: 1.0)
ctx.fill(CGRect(x: 0, y: 0, width: canvas, height: canvas))
ctx.restoreGState()

// Clear retro shell — neutral/white, low opacity
ctx.saveGState()
ctx.addPath(eggPath())
ctx.clip()
ctx.setFillColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.18)
ctx.fill(CGRect(x: 0, y: 0, width: canvas, height: canvas))
ctx.restoreGState()

// Shell edge stroke
ctx.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 0.3)
ctx.setLineWidth(4)
ctx.addPath(eggPath())
ctx.strokePath()

// --- Screen bezel ---
let scrW = canvas * 0.48
let scrH = canvas * 0.34
let scrX = eggCX - scrW / 2
let scrY = eggCY - eggH * 0.18

// Outer bezel (dark)
let bezelPath = CGPath(roundedRect: CGRect(x: scrX - 14, y: scrY - 12, width: scrW + 28, height: scrH + 24),
                       cornerWidth: 18, cornerHeight: 18, transform: nil)
ctx.setFillColor(red: 0x15/255.0, green: 0x15/255.0, blue: 0x15/255.0, alpha: 0.9)
ctx.addPath(bezelPath)
ctx.fillPath()

// Screen (dark LCD)
let screenPath = CGPath(roundedRect: CGRect(x: scrX, y: scrY, width: scrW, height: scrH),
                        cornerWidth: 10, cornerHeight: 10, transform: nil)
ctx.setFillColor(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0, alpha: 1.0)
ctx.addPath(screenPath)
ctx.fillPath()

// --- Crab on screen ---
let viewW: CGFloat = 66
let viewH: CGFloat = 52
let crabScale = min(scrW * 0.65 / viewW, scrH * 0.65 / viewH)
let crabXOff = scrX + (scrW - viewW * crabScale) / 2
let crabYOff = scrY + (scrH - viewH * crabScale) / 2

func crabRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, r: CGFloat, g: CGFloat, b: CGFloat) {
    ctx.setFillColor(red: r, green: g, blue: b, alpha: 1.0)
    ctx.fill(CGRect(x: crabXOff + x * crabScale, y: crabYOff + y * crabScale,
                    width: w * crabScale, height: h * crabScale))
}

let crabR: CGFloat = 0xD9/255.0, crabG: CGFloat = 0x77/255.0, crabB: CGFloat = 0x57/255.0  // #D97757 orange

// Antennae
crabRect(0, 13, 6, 13, r: crabR, g: crabG, b: crabB)
crabRect(60, 13, 6, 13, r: crabR, g: crabG, b: crabB)
// Body
crabRect(6, 0, 54, 39, r: crabR, g: crabG, b: crabB)
// Legs
for lx: CGFloat in [6, 18, 42, 54] {
    crabRect(lx, 39, 6, 13, r: crabR, g: crabG, b: crabB)
}
// Eyes
crabRect(14, 12, 6, 7, r: 0x1A/255.0, g: 0x1A/255.0, b: 0x1A/255.0)
crabRect(46, 12, 6, 7, r: 0x1A/255.0, g: 0x1A/255.0, b: 0x1A/255.0)

// --- Three buttons below screen ---
let btnY = scrY + scrH + canvas * 0.08
let btnR: CGFloat = canvas * 0.028
let btnSpacing = canvas * 0.06
for i in -1...1 {
    let bx = eggCX + CGFloat(i) * btnSpacing
    let btnPath = CGPath(ellipseIn: CGRect(x: bx - btnR, y: btnY - btnR, width: btnR * 2, height: btnR * 2), transform: nil)
    ctx.setFillColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0)
    ctx.addPath(btnPath)
    ctx.fillPath()
    // Highlight
    let hlPath = CGPath(ellipseIn: CGRect(x: bx - btnR * 0.6, y: btnY - btnR * 0.8, width: btnR * 1.2, height: btnR * 0.8), transform: nil)
    ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 0.15)
    ctx.addPath(hlPath)
    ctx.fillPath()
}

// --- CLAWDAGOTCHI text ---
let textY = scrY - canvas * 0.04
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: canvas * 0.028, weight: .heavy),
    .foregroundColor: NSColor(red: 1, green: 1, blue: 1, alpha: 0.3),
]
let text = NSAttributedString(string: "CLAWDAGOTCHI", attributes: attrs)
let textSize = text.size()
let line = CTLineCreateWithAttributedString(text)
ctx.saveGState()
// Flip back for text (CTLine draws in unflipped coords)
ctx.translateBy(x: 0, y: canvas)
ctx.scaleBy(x: 1, y: -1)
ctx.textPosition = CGPoint(x: eggCX - textSize.width / 2, y: canvas - textY)
CTLineDraw(line, ctx)
ctx.restoreGState()

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
