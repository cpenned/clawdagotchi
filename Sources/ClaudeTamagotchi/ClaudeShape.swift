import SwiftUI

// MARK: - Tamagotchi egg shell

struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        path.move(to: CGPoint(x: w * 0.50, y: 0))

        path.addCurve(
            to: CGPoint(x: w, y: h * 0.52),
            control1: CGPoint(x: w * 0.80, y: 0),
            control2: CGPoint(x: w, y: h * 0.22)
        )

        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h),
            control1: CGPoint(x: w, y: h * 0.82),
            control2: CGPoint(x: w * 0.82, y: h)
        )

        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.52),
            control1: CGPoint(x: w * 0.18, y: h),
            control2: CGPoint(x: 0, y: h * 0.82)
        )

        path.addCurve(
            to: CGPoint(x: w * 0.50, y: 0),
            control1: CGPoint(x: 0, y: h * 0.22),
            control2: CGPoint(x: w * 0.20, y: 0)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - 8-bit pixel art crab

struct CrabView: View {
    let pixelSize: CGFloat
    var color: Color = .gray

    private let grid: [[Int]] = [
        [0,1,0,0,0,0,0,0,0,1,0],
        [1,1,0,0,0,0,0,0,0,1,1],
        [0,1,0,1,1,1,1,1,0,1,0],
        [0,0,1,1,1,1,1,1,1,0,0],
        [0,1,1,0,1,1,1,0,1,1,0],
        [0,1,1,1,1,1,1,1,1,1,0],
        [0,0,1,1,1,1,1,1,1,0,0],
        [0,1,0,1,0,0,0,1,0,1,0],
        [1,0,0,0,1,0,1,0,0,0,1],
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
                        context.fill(Path(rect), with: .color(color))
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
    static let shellPink = Color(red: 0xF0 / 255.0, green: 0x90 / 255.0, blue: 0x80 / 255.0)
    static let shellPinkLight = Color(red: 0xF8 / 255.0, green: 0xB0 / 255.0, blue: 0xA0 / 255.0)
    static let shellPinkDark = Color(red: 0xC8 / 255.0, green: 0x6A / 255.0, blue: 0x58 / 255.0)
    static let screenDark = Color(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x1A / 255.0)
    static let screenBezel = Color(red: 0x2A / 255.0, green: 0x2A / 255.0, blue: 0x2A / 255.0)
}
