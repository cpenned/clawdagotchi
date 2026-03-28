import SwiftUI

// MARK: - Tamagotchi egg shell

struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // Egg: narrower top, wider bottom, symmetric
        path.move(to: CGPoint(x: w * 0.50, y: 0))

        // Top-right curve (tighter)
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.52),
            control1: CGPoint(x: w * 0.80, y: 0),
            control2: CGPoint(x: w, y: h * 0.22)
        )

        // Bottom-right curve (wider)
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h),
            control1: CGPoint(x: w, y: h * 0.82),
            control2: CGPoint(x: w * 0.82, y: h)
        )

        // Bottom-left curve
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.52),
            control1: CGPoint(x: w * 0.18, y: h),
            control2: CGPoint(x: 0, y: h * 0.82)
        )

        // Top-left curve (tighter)
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: 0),
            control1: CGPoint(x: 0, y: h * 0.22),
            control2: CGPoint(x: w * 0.20, y: 0)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Scalloped screen bezel

struct ScallopBezel: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let scallop: CGFloat = 6
        var path = Path()

        // Wavy rectangle — scallops on each edge
        let inset: CGFloat = 2
        let left = inset
        let right = w - inset
        let top = inset
        let bottom = h - inset

        // Top edge (left to right, scallops outward = upward)
        path.move(to: CGPoint(x: left, y: top))
        let topSteps = 5
        let topStep = (right - left) / CGFloat(topSteps)
        for i in 0..<topSteps {
            let x0 = left + CGFloat(i) * topStep
            let x1 = x0 + topStep
            path.addQuadCurve(
                to: CGPoint(x: x1, y: top),
                control: CGPoint(x: (x0 + x1) / 2, y: top - scallop)
            )
        }

        // Right edge (top to bottom)
        let rightSteps = 4
        let rightStep = (bottom - top) / CGFloat(rightSteps)
        for i in 0..<rightSteps {
            let y0 = top + CGFloat(i) * rightStep
            let y1 = y0 + rightStep
            path.addQuadCurve(
                to: CGPoint(x: right, y: y1),
                control: CGPoint(x: right + scallop, y: (y0 + y1) / 2)
            )
        }

        // Bottom edge (right to left)
        for i in 0..<topSteps {
            let x0 = right - CGFloat(i) * topStep
            let x1 = x0 - topStep
            path.addQuadCurve(
                to: CGPoint(x: x1, y: bottom),
                control: CGPoint(x: (x0 + x1) / 2, y: bottom + scallop)
            )
        }

        // Left edge (bottom to top)
        for i in 0..<rightSteps {
            let y0 = bottom - CGFloat(i) * rightStep
            let y1 = y0 - rightStep
            path.addQuadCurve(
                to: CGPoint(x: left, y: y1),
                control: CGPoint(x: left - scallop, y: (y0 + y1) / 2)
            )
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - 8-bit pixel art crab

struct CrabView: View {
    let pixelSize: CGFloat

    // 11 wide x 9 tall pixel grid
    // 1 = filled, 0 = empty
    private let grid: [[Int]] = [
        [0,1,0,0,0,0,0,0,0,1,0],  // claws top
        [1,1,0,0,0,0,0,0,0,1,1],  // claws
        [0,1,0,1,1,1,1,1,0,1,0],  // claws meet body
        [0,0,1,1,1,1,1,1,1,0,0],  // body top
        [0,1,1,0,1,1,1,0,1,1,0],  // body with eyes
        [0,1,1,1,1,1,1,1,1,1,0],  // body
        [0,0,1,1,1,1,1,1,1,0,0],  // body bottom
        [0,1,0,1,0,0,0,1,0,1,0],  // legs outer
        [1,0,0,0,1,0,1,0,0,0,1],  // legs tips
    ]

    var body: some View {
        Canvas { context, size in
            let cols = grid[0].count
            let rows = grid.count
            let totalW = CGFloat(cols) * pixelSize
            let totalH = CGFloat(rows) * pixelSize
            let offsetX = (size.width - totalW) / 2
            let offsetY = (size.height - totalH) / 2

            for row in 0..<rows {
                for col in 0..<cols {
                    if grid[row][col] == 1 {
                        let rect = CGRect(
                            x: offsetX + CGFloat(col) * pixelSize,
                            y: offsetY + CGFloat(row) * pixelSize,
                            width: pixelSize,
                            height: pixelSize
                        )
                        context.fill(Path(rect), with: .color(.black))
                    }
                }
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
    static let claudePink = Color(red: 0xF0 / 255.0, green: 0x90 / 255.0, blue: 0x80 / 255.0)
    static let claudePinkDark = Color(red: 0xD0 / 255.0, green: 0x68 / 255.0, blue: 0x58 / 255.0)
    static let lcdGreen = Color(red: 0x9B / 255.0, green: 0xBC / 255.0, blue: 0x0F / 255.0)
    static let lcdGreenLight = Color(red: 0xC4 / 255.0, green: 0xCF / 255.0, blue: 0x56 / 255.0)
}
