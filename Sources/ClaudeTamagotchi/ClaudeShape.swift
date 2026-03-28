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

// MARK: - Eye styles

enum EyeStyle: Equatable {
    case normal
    case blink
    case squish
    case wide
}

// MARK: - Canvas crab (claude-island style with dynamic eyes)

struct CrabView: View {
    let size: CGFloat
    var color: Color = .gray
    var eyeColor: Color = .black
    var eyeStyle: EyeStyle = .normal
    var animateLegs: Bool = false

    @State private var legPhase: Int = 0
    private let legTimer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    // Geometry constants (viewBox: 66 wide x 52 tall)
    private let viewW: CGFloat = 66
    private let viewH: CGFloat = 52

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / viewH
            let xOff = (canvasSize.width - viewW * scale) / 2
            let yOff = (canvasSize.height - viewH * scale) / 2

            func r(_ rect: CGRect) -> Path {
                Path(CGRect(
                    x: xOff + rect.origin.x * scale,
                    y: yOff + rect.origin.y * scale,
                    width: rect.width * scale,
                    height: rect.height * scale
                ))
            }

            // Antennae
            context.fill(r(CGRect(x: 0, y: 13, width: 6, height: 13)), with: .color(color))
            context.fill(r(CGRect(x: 60, y: 13, width: 6, height: 13)), with: .color(color))

            // Legs (4 legs with walking animation)
            let legXs: [CGFloat] = [6, 18, 42, 54]
            let baseH: CGFloat = 13
            let offsets: [[CGFloat]] = [
                [3, -3, 3, -3],
                [0, 0, 0, 0],
                [-3, 3, -3, 3],
                [0, 0, 0, 0],
            ]
            let phase = animateLegs ? offsets[legPhase % 4] : [0, 0, 0, 0]
            for (i, lx) in legXs.enumerated() {
                let lh = baseH + phase[i]
                context.fill(r(CGRect(x: lx, y: 39, width: 6, height: lh)), with: .color(color))
            }

            // Main body
            context.fill(r(CGRect(x: 6, y: 0, width: 54, height: 39)), with: .color(color))

            // Eyes
            let leftEyeX: CGFloat = 14
            let rightEyeX: CGFloat = 46
            let eyeY: CGFloat = 12

            switch eyeStyle {
            case .normal:
                context.fill(r(CGRect(x: leftEyeX, y: eyeY, width: 6, height: 7)), with: .color(eyeColor))
                context.fill(r(CGRect(x: rightEyeX, y: eyeY, width: 6, height: 7)), with: .color(eyeColor))

            case .blink:
                context.fill(r(CGRect(x: leftEyeX, y: eyeY + 3, width: 6, height: 2)), with: .color(eyeColor))
                context.fill(r(CGRect(x: rightEyeX, y: eyeY + 3, width: 6, height: 2)), with: .color(eyeColor))

            case .squish:
                // > < chevrons
                let armH: CGFloat = 8 * scale
                let reachW: CGFloat = 5 * scale
                let lcx = xOff + (leftEyeX + 3) * scale
                let rcx = xOff + (rightEyeX + 3) * scale
                let cy = yOff + (eyeY + 3.5) * scale

                var leftChev = Path()
                leftChev.move(to: CGPoint(x: lcx - reachW/2, y: cy - armH/2))
                leftChev.addLine(to: CGPoint(x: lcx + reachW/2, y: cy))
                leftChev.addLine(to: CGPoint(x: lcx - reachW/2, y: cy + armH/2))
                context.stroke(leftChev, with: .color(eyeColor),
                               style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round, lineJoin: .round))

                var rightChev = Path()
                rightChev.move(to: CGPoint(x: rcx + reachW/2, y: cy - armH/2))
                rightChev.addLine(to: CGPoint(x: rcx - reachW/2, y: cy))
                rightChev.addLine(to: CGPoint(x: rcx + reachW/2, y: cy + armH/2))
                context.stroke(rightChev, with: .color(eyeColor),
                               style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round, lineJoin: .round))

            case .wide:
                context.fill(r(CGRect(x: leftEyeX - 1, y: eyeY - 1, width: 8, height: 9)), with: .color(eyeColor))
                context.fill(r(CGRect(x: rightEyeX - 1, y: eyeY - 1, width: 8, height: 9)), with: .color(eyeColor))
            }
        }
        .frame(width: size * (viewW / viewH), height: size)
        .onReceive(legTimer) { _ in
            if animateLegs {
                legPhase = (legPhase + 1) % 4
            }
        }
    }
}

// MARK: - Colors

extension Color {
    static let shellPink = Color(red: 0xF0 / 255.0, green: 0x90 / 255.0, blue: 0x80 / 255.0)
    static let shellPinkLight = Color(red: 0xF8 / 255.0, green: 0xB0 / 255.0, blue: 0xA0 / 255.0)
    static let shellPinkDark = Color(red: 0xC8 / 255.0, green: 0x6A / 255.0, blue: 0x58 / 255.0)
    static let screenDark = Color(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x1A / 255.0)
}
