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
    case sleepy
    case tiny
}

// MARK: - Crab accessories (unlocked by level)

enum CrabAccessory: Int, CaseIterable, Sendable {
    case none = 1
    case bowTie = 2
    case partyHat = 3
    case sunglasses = 4
    case topHat = 5
    case crown = 6
    case halo = 7
    case starAura = 8

    static func forLevel(_ level: Int) -> CrabAccessory {
        CrabAccessory(rawValue: min(level, 8)) ?? .none
    }
}

// MARK: - Canvas crab (claude-island style with dynamic eyes)

struct CrabView: View {
    let size: CGFloat
    var color: Color = .gray
    var eyeColor: Color = .black
    var eyeStyle: EyeStyle = .normal
    var animateLegs: Bool = false
    var accessory: CrabAccessory = .none

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

            case .sleepy:
                // Half-closed: thin slit with a line above (droopy lid)
                context.fill(r(CGRect(x: leftEyeX, y: eyeY + 3, width: 6, height: 3)), with: .color(eyeColor))
                context.fill(r(CGRect(x: rightEyeX, y: eyeY + 3, width: 6, height: 3)), with: .color(eyeColor))

            case .tiny:
                // Small dots (hungry look)
                context.fill(r(CGRect(x: leftEyeX + 1, y: eyeY + 2, width: 4, height: 4)), with: .color(eyeColor))
                context.fill(r(CGRect(x: rightEyeX + 1, y: eyeY + 2, width: 4, height: 4)), with: .color(eyeColor))
            }

            // MARK: Accessories
            switch accessory {
            case .none:
                break

            case .bowTie:
                let bcx = xOff + 33 * scale
                let bcy = yOff + 38 * scale
                let bw = CGFloat(4) * scale
                let bh = CGFloat(3) * scale
                var leftTri = Path()
                leftTri.move(to: CGPoint(x: bcx, y: bcy))
                leftTri.addLine(to: CGPoint(x: bcx - bw, y: bcy - bh))
                leftTri.addLine(to: CGPoint(x: bcx - bw, y: bcy + bh))
                leftTri.closeSubpath()
                context.fill(leftTri, with: .color(color))
                var rightTri = Path()
                rightTri.move(to: CGPoint(x: bcx, y: bcy))
                rightTri.addLine(to: CGPoint(x: bcx + bw, y: bcy - bh))
                rightTri.addLine(to: CGPoint(x: bcx + bw, y: bcy + bh))
                rightTri.closeSubpath()
                context.fill(rightTri, with: .color(color))
                context.fill(Path(CGRect(x: bcx - scale, y: bcy - scale, width: 2 * scale, height: 2 * scale)), with: .color(color))

            case .partyHat:
                var hat = Path()
                hat.move(to: CGPoint(x: xOff + 33 * scale, y: yOff + (-8) * scale))
                hat.addLine(to: CGPoint(x: xOff + 26 * scale, y: yOff + 0 * scale))
                hat.addLine(to: CGPoint(x: xOff + 40 * scale, y: yOff + 0 * scale))
                hat.closeSubpath()
                context.fill(hat, with: .color(color))

            case .sunglasses:
                context.fill(r(CGRect(x: 10, y: 11, width: 46, height: 3)), with: .color(eyeColor))
                context.fill(r(CGRect(x: 28, y: 11, width: 10, height: 3)), with: .color(eyeColor))

            case .topHat:
                context.fill(r(CGRect(x: 20, y: -2, width: 26, height: 3)), with: .color(eyeColor))
                context.fill(r(CGRect(x: 25, y: -14, width: 16, height: 12)), with: .color(eyeColor))

            case .crown:
                let goldenColor = Color(red: 1.0, green: 0.85, blue: 0.3)
                var crown = Path()
                crown.move(to: CGPoint(x: xOff + 22 * scale, y: yOff + (-2) * scale))
                crown.addLine(to: CGPoint(x: xOff + 26 * scale, y: yOff + (-8) * scale))
                crown.addLine(to: CGPoint(x: xOff + 30 * scale, y: yOff + (-4) * scale))
                crown.addLine(to: CGPoint(x: xOff + 33 * scale, y: yOff + (-10) * scale))
                crown.addLine(to: CGPoint(x: xOff + 36 * scale, y: yOff + (-4) * scale))
                crown.addLine(to: CGPoint(x: xOff + 40 * scale, y: yOff + (-8) * scale))
                crown.addLine(to: CGPoint(x: xOff + 44 * scale, y: yOff + (-2) * scale))
                crown.closeSubpath()
                context.fill(crown, with: .color(goldenColor))

            case .halo:
                let haloRect = CGRect(
                    x: xOff + (33 - 10) * scale,
                    y: yOff + (-10 - 3) * scale,
                    width: 20 * scale,
                    height: 6 * scale
                )
                context.stroke(
                    Path(ellipseIn: haloRect),
                    with: .color(color.opacity(0.6)),
                    style: StrokeStyle(lineWidth: 2 * scale)
                )

            case .starAura:
                let diamondPositions: [(CGFloat, CGFloat)] = [(0, 5), (62, 5), (5, 42), (57, 42)]
                let ds = CGFloat(2) * scale
                for (dx, dy) in diamondPositions {
                    let cx2 = xOff + dx * scale
                    let cy2 = yOff + dy * scale
                    var diamond = Path()
                    diamond.move(to: CGPoint(x: cx2, y: cy2 - ds))
                    diamond.addLine(to: CGPoint(x: cx2 + ds, y: cy2))
                    diamond.addLine(to: CGPoint(x: cx2, y: cy2 + ds))
                    diamond.addLine(to: CGPoint(x: cx2 - ds, y: cy2))
                    diamond.closeSubpath()
                    context.fill(diamond, with: .color(color))
                }
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
    static let shellPinkLight = Color(red: 0xF8 / 255.0, green: 0xB0 / 255.0, blue: 0xA0 / 255.0)
    static let screenDark = Color(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x1A / 255.0)
}
