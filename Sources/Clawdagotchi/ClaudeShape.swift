import SwiftUI

// MARK: - Background themes

enum BackgroundTheme: String, CaseIterable, Sendable {
    case none, stars, matrix, waves, circuit, bubbles

    var displayName: String {
        switch self {
        case .none: "None"
        case .stars: "Stars"
        case .matrix: "Matrix"
        case .waves: "Waves"
        case .circuit: "Circuit"
        case .bubbles: "Bubbles"
        }
    }
}

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
    case headphones = 7
    case starAura = 8
    case santaHat = 10
    case pumpkin = 11
    case bunnyEars = 12
    case heartBow = 13
    case partyPopper = 14

    static func forLevel(_ level: Int) -> CrabAccessory {
        CrabAccessory(rawValue: min(level, 8)) ?? .none
    }

    static func seasonalAccessory() -> CrabAccessory? {
        let cal = Calendar.current
        let month = cal.component(.month, from: Date())
        let day = cal.component(.day, from: Date())

        switch (month, day) {
        case (1, 1): return .partyPopper
        case (2, 1...14): return .heartBow
        case (4, 1...20): return .bunnyEars
        case (10, _): return .pumpkin
        case (12, _): return .santaHat
        default: return nil
        }
    }

    static func allUnlocked(for level: Int, seasonalEnabled: Bool = true) -> [CrabAccessory] {
        var items: [CrabAccessory] = []
        if level >= 2 { items.append(.bowTie) }
        if level >= 4 { items.append(.sunglasses) }

        // Head item: seasonal overrides level-based
        if seasonalEnabled, let seasonal = seasonalAccessory() {
            if seasonal == .partyPopper {
                // partyPopper is body effect, not head — still show head item
                items.append(seasonal)
            } else {
                items.append(seasonal)  // seasonal replaces head slot
            }
        } else {
            // Normal head progression
            if level >= 6 { items.append(.crown) }
            else if level >= 5 { items.append(.topHat) }
            else if level >= 3 { items.append(.partyHat) }
        }

        if level >= 7 { items.append(.headphones) }
        if level >= 8 { items.append(.starAura) }
        return items
    }
}

// MARK: - Canvas crab (claude-island style with dynamic eyes)

struct CrabView: View {
    let size: CGFloat
    var color: Color = .gray
    var eyeColor: Color = .black
    var eyeStyle: EyeStyle = .normal
    var animateLegs: Bool = false
    var accessories: [CrabAccessory] = []
    var accessoryColor: Color = .white

    @State private var legPhase: Int = 0
    private let legTimer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    // Geometry constants — extra room for accessories (hats above, sparkles to sides)
    private let viewW: CGFloat = 86  // 66 + 10 padding each side
    private let viewH: CGFloat = 80  // 52 + 22 headroom + 6 legroom
    private let crabOffsetX: CGFloat = 10  // center crab in wider viewbox
    private let crabOffsetY: CGFloat = 22  // shift crab down for hat/headphone room

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / viewH
            let xOff = (canvasSize.width - viewW * scale) / 2 + crabOffsetX * scale
            let yOff = (canvasSize.height - viewH * scale) / 2 + crabOffsetY * scale

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

            // MARK: Accessories (draw all unlocked)
            for acc in accessories {
            switch acc {
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
                context.fill(leftTri, with: .color(accessoryColor))
                var rightTri = Path()
                rightTri.move(to: CGPoint(x: bcx, y: bcy))
                rightTri.addLine(to: CGPoint(x: bcx + bw, y: bcy - bh))
                rightTri.addLine(to: CGPoint(x: bcx + bw, y: bcy + bh))
                rightTri.closeSubpath()
                context.fill(rightTri, with: .color(accessoryColor))
                context.fill(Path(CGRect(x: bcx - scale, y: bcy - scale, width: 2 * scale, height: 2 * scale)), with: .color(accessoryColor))

            case .partyHat:
                // Larger cone hat
                var hat = Path()
                hat.move(to: CGPoint(x: xOff + 33 * scale, y: yOff + (-12) * scale))
                hat.addLine(to: CGPoint(x: xOff + 22 * scale, y: yOff + 2 * scale))
                hat.addLine(to: CGPoint(x: xOff + 44 * scale, y: yOff + 2 * scale))
                hat.closeSubpath()
                context.fill(hat, with: .color(accessoryColor))
                // Pom-pom on top
                let pomRect = CGRect(x: xOff + 30 * scale, y: yOff + (-15) * scale, width: 6 * scale, height: 5 * scale)
                context.fill(Path(ellipseIn: pomRect), with: .color(accessoryColor))

            case .sunglasses:
                // Left lens box around left eye
                context.stroke(r(CGRect(x: 11, y: 9, width: 14, height: 10)), with: .color(accessoryColor),
                               style: StrokeStyle(lineWidth: 1.5 * scale))
                // Right lens box around right eye
                context.stroke(r(CGRect(x: 43, y: 9, width: 14, height: 10)), with: .color(accessoryColor),
                               style: StrokeStyle(lineWidth: 1.5 * scale))
                // Bridge between lenses
                context.fill(r(CGRect(x: 25, y: 13, width: 18, height: 2)), with: .color(accessoryColor))

            case .topHat:
                // Brim
                context.fill(r(CGRect(x: 22, y: -1, width: 22, height: 3)), with: .color(accessoryColor))
                // Crown (shorter to avoid clipping)
                context.fill(r(CGRect(x: 26, y: -8, width: 14, height: 7)), with: .color(accessoryColor))

            case .crown:
                var crown = Path()
                crown.move(to: CGPoint(x: xOff + 18 * scale, y: yOff + 0 * scale))
                crown.addLine(to: CGPoint(x: xOff + 23 * scale, y: yOff + (-8) * scale))
                crown.addLine(to: CGPoint(x: xOff + 28 * scale, y: yOff + (-4) * scale))
                crown.addLine(to: CGPoint(x: xOff + 33 * scale, y: yOff + (-12) * scale))
                crown.addLine(to: CGPoint(x: xOff + 38 * scale, y: yOff + (-4) * scale))
                crown.addLine(to: CGPoint(x: xOff + 43 * scale, y: yOff + (-8) * scale))
                crown.addLine(to: CGPoint(x: xOff + 48 * scale, y: yOff + 0 * scale))
                crown.closeSubpath()
                context.fill(crown, with: .color(accessoryColor))

            case .headphones:
                // Headband arc over the top of head
                var band = Path()
                band.addArc(center: CGPoint(x: xOff + 33 * scale, y: yOff + 6 * scale),
                            radius: 22 * scale,
                            startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
                context.stroke(band, with: .color(accessoryColor),
                               style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round))
                // Left ear cup
                context.fill(r(CGRect(x: 4, y: 8, width: 6, height: 10)), with: .color(accessoryColor))
                // Right ear cup
                context.fill(r(CGRect(x: 56, y: 8, width: 6, height: 10)), with: .color(accessoryColor))

            case .starAura:
                // 6 sparkle crosses around the body
                let sparkles: [(CGFloat, CGFloat)] = [
                    (-4, 3), (66, 3), (-3, 35), (67, 35), (10, -5), (56, -5)
                ]
                for (sx, sy) in sparkles {
                    let cx2 = xOff + sx * scale
                    let cy2 = yOff + sy * scale
                    let arm = 3 * scale
                    // Vertical line
                    var v = Path()
                    v.move(to: CGPoint(x: cx2, y: cy2 - arm))
                    v.addLine(to: CGPoint(x: cx2, y: cy2 + arm))
                    context.stroke(v, with: .color(accessoryColor.opacity(0.7)),
                                   style: StrokeStyle(lineWidth: 1 * scale, lineCap: .round))
                    // Horizontal line
                    var h = Path()
                    h.move(to: CGPoint(x: cx2 - arm, y: cy2))
                    h.addLine(to: CGPoint(x: cx2 + arm, y: cy2))
                    context.stroke(h, with: .color(accessoryColor.opacity(0.7)),
                                   style: StrokeStyle(lineWidth: 1 * scale, lineCap: .round))
                }

            case .santaHat:
                let santaRed = Color(red: 0.8, green: 0.15, blue: 0.1)
                // Red triangle hat
                var santaHatPath = Path()
                santaHatPath.move(to: CGPoint(x: xOff + 33 * scale, y: yOff + (-14) * scale))
                santaHatPath.addLine(to: CGPoint(x: xOff + 21 * scale, y: yOff + 2 * scale))
                santaHatPath.addLine(to: CGPoint(x: xOff + 45 * scale, y: yOff + 2 * scale))
                santaHatPath.closeSubpath()
                context.fill(santaHatPath, with: .color(santaRed))
                // White trim at base
                context.fill(r(CGRect(x: 19, y: 0, width: 28, height: 4)), with: .color(Color.white))
                // White pom-pom on top
                let pomSanta = CGRect(x: xOff + 29 * scale, y: yOff + (-18) * scale, width: 8 * scale, height: 7 * scale)
                context.fill(Path(ellipseIn: pomSanta), with: .color(Color.white))

            case .pumpkin:
                let pumpkinOrange = Color(red: 0.9, green: 0.5, blue: 0.1)
                // Orange rounded rectangle on head
                let pumpkinRect = CGRect(x: xOff + 24 * scale, y: yOff + (-8) * scale, width: 18 * scale, height: 12 * scale)
                context.fill(Path(roundedRect: pumpkinRect, cornerRadius: 4 * scale), with: .color(pumpkinOrange))
                // Green stem on top
                context.fill(r(CGRect(x: 31, y: -12, width: 4, height: 5)), with: .color(Color.green))

            case .bunnyEars:
                let earPink = Color(red: 1.0, green: 0.7, blue: 0.8)
                // Left ear — white outer, pink inner
                context.fill(r(CGRect(x: 19, y: -18, width: 8, height: 16)), with: .color(Color.white))
                context.fill(r(CGRect(x: 21, y: -16, width: 4, height: 12)), with: .color(earPink))
                // Right ear — white outer, pink inner
                context.fill(r(CGRect(x: 39, y: -18, width: 8, height: 16)), with: .color(Color.white))
                context.fill(r(CGRect(x: 41, y: -16, width: 4, height: 12)), with: .color(earPink))

            case .heartBow:
                let heartPink = Color(red: 1.0, green: 0.3, blue: 0.5)
                let hcx = xOff + 33 * scale
                let hcy = yOff + (-10) * scale
                let hr = CGFloat(5) * scale
                // Two circles + triangle for heart shape
                let leftCircleRect = CGRect(x: hcx - hr, y: hcy - hr / 2, width: hr, height: hr)
                let rightCircleRect = CGRect(x: hcx, y: hcy - hr / 2, width: hr, height: hr)
                context.fill(Path(ellipseIn: leftCircleRect), with: .color(heartPink))
                context.fill(Path(ellipseIn: rightCircleRect), with: .color(heartPink))
                var heartTri = Path()
                heartTri.move(to: CGPoint(x: hcx - hr, y: hcy))
                heartTri.addLine(to: CGPoint(x: hcx + hr, y: hcy))
                heartTri.addLine(to: CGPoint(x: hcx, y: hcy + hr * 1.2))
                heartTri.closeSubpath()
                context.fill(heartTri, with: .color(heartPink))

            case .partyPopper:
                let confettiColors: [Color] = [.red, .yellow, .blue, .green, Color(red: 1, green: 0.5, blue: 0), .purple]
                let positions: [(CGFloat, CGFloat)] = [
                    (-2, 5), (68, 8), (5, 42), (60, 38), (20, -2), (50, -3), (10, 28), (58, 22)
                ]
                for (i, (px, py)) in positions.enumerated() {
                    let col = confettiColors[i % confettiColors.count]
                    context.fill(r(CGRect(x: px, y: py, width: 4, height: 3)), with: .color(col.opacity(0.5)))
                }
            }
            } // end for acc
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
