import SwiftUI

// MARK: - Tamagotchi egg shell

struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        path.move(to: CGPoint(x: w * 0.50, y: 0))
        path.addCurve(to: CGPoint(x: w, y: h * 0.52),
                       control1: CGPoint(x: w * 0.80, y: 0),
                       control2: CGPoint(x: w, y: h * 0.22))
        path.addCurve(to: CGPoint(x: w * 0.50, y: h),
                       control1: CGPoint(x: w, y: h * 0.82),
                       control2: CGPoint(x: w * 0.82, y: h))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.52),
                       control1: CGPoint(x: w * 0.18, y: h),
                       control2: CGPoint(x: 0, y: h * 0.82))
        path.addCurve(to: CGPoint(x: w * 0.50, y: 0),
                       control1: CGPoint(x: 0, y: h * 0.22),
                       control2: CGPoint(x: w * 0.20, y: 0))
        path.closeSubpath()
        return path
    }
}

// MARK: - Eye styles (clawd-mochi inspired)

enum EyeStyle: Equatable {
    case normal
    case blink
    case squish
    case wide
}

// MARK: - 8-bit pixel art character with dynamic eyes

struct CrabView: View {
    let pixelSize: CGFloat
    var bodyColor: Color = .gray
    var eyeColor: Color = .black
    var eyeStyle: EyeStyle = .normal
    var eyeOffsetX: CGFloat = 0

    // 14 wide x 10 tall — body only (eyes drawn separately)
    // 0 = empty, 1 = body
    private let grid: [[Int]] = [
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

    // Eye positions in grid coordinates
    private let leftEyeCol: CGFloat = 4
    private let rightEyeCol: CGFloat = 8
    private let eyeRow: CGFloat = 2.5

    var body: some View {
        Canvas { context, size in
            let cols = grid[0].count
            let rows = grid.count
            let totalW = CGFloat(cols) * pixelSize
            let totalH = CGFloat(rows) * pixelSize
            let ox = (size.width - totalW) / 2
            let oy = (size.height - totalH) / 2

            // Draw body
            for row in 0..<rows {
                for col in 0..<cols {
                    guard grid[row][col] == 1 else { continue }
                    let rect = CGRect(
                        x: ox + CGFloat(col) * pixelSize,
                        y: oy + CGFloat(row) * pixelSize,
                        width: pixelSize, height: pixelSize
                    )
                    context.fill(Path(rect), with: .color(bodyColor))
                }
            }

            // Draw eyes based on style
            let lx = ox + (leftEyeCol + eyeOffsetX) * pixelSize
            let rx = ox + (rightEyeCol + eyeOffsetX) * pixelSize
            let ey = oy + eyeRow * pixelSize

            switch eyeStyle {
            case .normal:
                let leftRect = CGRect(x: lx, y: ey, width: pixelSize * 2, height: pixelSize * 1.5)
                let rightRect = CGRect(x: rx, y: ey, width: pixelSize * 2, height: pixelSize * 1.5)
                context.fill(Path(leftRect), with: .color(eyeColor))
                context.fill(Path(rightRect), with: .color(eyeColor))

            case .blink:
                let leftRect = CGRect(x: lx, y: ey + pixelSize * 0.5, width: pixelSize * 2, height: pixelSize * 0.5)
                let rightRect = CGRect(x: rx, y: ey + pixelSize * 0.5, width: pixelSize * 2, height: pixelSize * 0.5)
                context.fill(Path(leftRect), with: .color(eyeColor))
                context.fill(Path(rightRect), with: .color(eyeColor))

            case .squish:
                // > < chevron eyes
                let armH = pixelSize * 1.5
                let reachW = pixelSize * 1.2
                let lcx = lx + pixelSize
                let rcx = rx + pixelSize
                let cy = ey + pixelSize * 0.75

                // Left eye: >
                var leftChev = Path()
                leftChev.move(to: CGPoint(x: lcx - reachW/2, y: cy - armH/2))
                leftChev.addLine(to: CGPoint(x: lcx + reachW/2, y: cy))
                leftChev.addLine(to: CGPoint(x: lcx - reachW/2, y: cy + armH/2))
                context.stroke(leftChev, with: .color(eyeColor),
                               style: StrokeStyle(lineWidth: pixelSize * 0.6, lineCap: .round, lineJoin: .round))

                // Right eye: <
                var rightChev = Path()
                rightChev.move(to: CGPoint(x: rcx + reachW/2, y: cy - armH/2))
                rightChev.addLine(to: CGPoint(x: rcx - reachW/2, y: cy))
                rightChev.addLine(to: CGPoint(x: rcx + reachW/2, y: cy + armH/2))
                context.stroke(rightChev, with: .color(eyeColor),
                               style: StrokeStyle(lineWidth: pixelSize * 0.6, lineCap: .round, lineJoin: .round))

            case .wide:
                let leftRect = CGRect(x: lx, y: ey - pixelSize * 0.25, width: pixelSize * 2, height: pixelSize * 2)
                let rightRect = CGRect(x: rx, y: ey - pixelSize * 0.25, width: pixelSize * 2, height: pixelSize * 2)
                context.fill(Path(leftRect), with: .color(eyeColor))
                context.fill(Path(rightRect), with: .color(eyeColor))
            }
        }
        .frame(
            width: CGFloat(grid[0].count) * pixelSize + 4,
            height: CGFloat(grid.count) * pixelSize + 4
        )
    }
}

// MARK: - Colors

extension Color {
    static let shellPink = Color(red: 0xF0 / 255.0, green: 0x90 / 255.0, blue: 0x80 / 255.0)
    static let shellPinkLight = Color(red: 0xF8 / 255.0, green: 0xB0 / 255.0, blue: 0xA0 / 255.0)
    static let shellPinkDark = Color(red: 0xC8 / 255.0, green: 0x6A / 255.0, blue: 0x58 / 255.0)
    static let screenDark = Color(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x1A / 255.0)
}
