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

// Pixel grid: 14 wide x 10 tall (crab body silhouette)
// 1 = crab color (white), 0 = transparent
let grid: [[Int]] = [
    [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,1,1,0,1,1,0,1,1,0,0,0],
    [0,0,0,1,1,0,1,1,0,1,1,0,0,0],
]

// Eye positions: col 4-5 row 3, col 8-9 row 3
let eyeCells: Set<String> = ["3,4","3,5","3,8","3,9"]

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

// Calculate pixel grid dimensions
// Use ~55% of canvas width for the crab
let gridCols = 14
let gridRows = 10
let crabWidth = canvas * 0.55
let pixelSize = crabWidth / CGFloat(gridCols)
let crabHeight = pixelSize * CGFloat(gridRows)

// Center the crab
let xOffset = (canvas - crabWidth) / 2
let yOffset = (canvas - crabHeight) / 2

for (row, rowData) in grid.enumerated() {
    for (col, cell) in rowData.enumerated() {
        guard cell == 1 else { continue }
        let key = "\(row),\(col)"
        let isEye = eyeCells.contains(key)
        let px = xOffset + CGFloat(col) * pixelSize
        let py = yOffset + CGFloat(row) * pixelSize
        let rect = CGRect(x: px, y: py, width: pixelSize, height: pixelSize)
        if isEye {
            // Dark eyes: near-black
            ctx.setFillColor(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0, alpha: 1.0)
        } else {
            // White/cream body
            ctx.setFillColor(red: 0xFF/255.0, green: 0xF5/255.0, blue: 0xED/255.0, alpha: 1.0)
        }
        ctx.fill(rect)
    }
}

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
