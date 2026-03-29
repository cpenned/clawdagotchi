import SwiftUI

struct TamagotchiView: View {
    let state: PetState
    let sessionCount: Int
    let pendingPermission: PendingPermission?
    let funReaction: TamagotchiViewModel.FunReaction?
    var onApprove: () -> Void = {}
    var onDeny: () -> Void = {}
    var onPoke: () -> Void = {}
    var onPet: () -> Void = {}

    @State private var bobOffset: CGFloat = 0
    @State private var eyeOffset: CGFloat = 0
    @State private var currentEyeStyle: EyeStyle = .normal
    @State private var animGeneration: Int = 0
    @State private var blinkTimer: Task<Void, Never>?
    @State private var permissionPulse: Bool = false

    private let eggWidth: CGFloat = 190
    private let eggHeight: CGFloat = 250
    private let screenWidth: CGFloat = 110
    private let screenHeight: CGFloat = 90
    private let padding: CGFloat = 30

    var body: some View {
        ZStack {
            eggShadow
            internalsLayer
            translucentShell
            shellEdgeHighlight
            specularHighlight
            brandLabel
            screwDots
            screenInset
            lcdScreen
            buttons
        }
        .frame(width: eggWidth + padding * 2, height: eggHeight + padding * 2)
        .onChange(of: state) { _, newState in
            resetAnimations()
            startAnimations(for: newState)
        }
        .onChange(of: funReaction) { _, reaction in
            if let reaction { applyFunReaction(reaction) }
        }
        .onAppear { startAnimations(for: state) }
        .onDisappear { blinkTimer?.cancel() }
    }

    // MARK: - Nothing-style transparent shell

    private var eggShadow: some View {
        EggShape()
            .fill(Color.black.opacity(0.3))
            .frame(width: eggWidth, height: eggHeight)
            .offset(y: 5)
            .blur(radius: 14)
    }

    private var internalsLayer: some View {
        // Dark cavity + visible circuit board internals
        ZStack {
            // Internal cavity (dark background)
            EggShape()
                .fill(Color(white: 0.08))
                .frame(width: eggWidth - 4, height: eggHeight - 4)

            // Circuit board traces and components
            InternalsView(width: eggWidth, height: eggHeight)
                .clipShape(EggShape())
                .frame(width: eggWidth - 4, height: eggHeight - 4)
        }
    }

    private var translucentShell: some View {
        // Semi-transparent pink shell — Nothing-style see-through plastic
        EggShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color.shellPinkLight.opacity(0.35),
                        Color.shellPink.opacity(0.25),
                        Color.shellPinkDark.opacity(0.30),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: eggWidth, height: eggHeight)
    }

    private var shellEdgeHighlight: some View {
        EggShape()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.4),
                        Color.shellPink.opacity(0.3),
                        Color.white.opacity(0.15),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .frame(width: eggWidth, height: eggHeight)
    }

    private var specularHighlight: some View {
        Ellipse()
            .fill(RadialGradient(
                colors: [Color.white.opacity(0.3), Color.white.opacity(0.0)],
                center: .center, startRadius: 0, endRadius: 40
            ))
            .frame(width: 70, height: 28)
            .offset(x: -30, y: -(eggHeight * 0.30))
            .allowsHitTesting(false)
    }

    private var brandLabel: some View {
        Text("CLAWDAGOTCHI")
            .font(.system(size: 7, weight: .heavy, design: .monospaced))
            .tracking(2)
            .foregroundStyle(Color.white.opacity(0.35))
            .offset(y: -(eggHeight * 0.24))
    }

    // Visible screw holes at corners of screen area
    private var screwDots: some View {
        let screwColor = Color(white: 0.35)
        let dx: CGFloat = screenWidth / 2 + 14
        let dy: CGFloat = screenHeight / 2 + 12
        let offsetY: CGFloat = -24
        return ZStack {
            Circle().fill(screwColor).frame(width: 4, height: 4).offset(x: -dx, y: offsetY - dy)
            Circle().fill(screwColor).frame(width: 4, height: 4).offset(x: dx, y: offsetY - dy)
            Circle().fill(screwColor).frame(width: 4, height: 4).offset(x: -dx, y: offsetY + dy)
            Circle().fill(screwColor).frame(width: 4, height: 4).offset(x: dx, y: offsetY + dy)
            // Cross-slot on each screw
            ForEach(0..<4, id: \.self) { i in
                let px: CGFloat = i < 2 ? -dx : dx
                let py: CGFloat = (i % 2 == 0) ? offsetY - dy : offsetY + dy
                Group {
                    Rectangle().fill(Color(white: 0.2)).frame(width: 3, height: 0.5)
                    Rectangle().fill(Color(white: 0.2)).frame(width: 0.5, height: 3)
                }
                .offset(x: px, y: py)
            }
        }
    }

    // MARK: - Screen inset

    private var screenInset: some View {
        ZStack {
            // Outer dark bezel ring
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.12))
                .frame(width: screenWidth + 16, height: screenHeight + 14)

            // Inner bevel
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.6), Color.black.opacity(0.3)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: screenWidth + 8, height: screenHeight + 6)

            if state == .permissionNeeded {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(permissionPulse ? 0.6 : 0.2), lineWidth: 2)
                    .frame(width: screenWidth + 8, height: screenHeight + 6)
            }

            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    LinearGradient(
                        colors: [Color.black.opacity(0.5), Color.clear, Color.white.opacity(0.08)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .frame(width: screenWidth + 4, height: screenHeight + 2)
        }
        .offset(y: -24)
    }

    // MARK: - LCD screen

    private var lcdScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.screenDark)

            PixelGridOverlay()
                .clipShape(RoundedRectangle(cornerRadius: 5))

            crabCharacter

            screenText
                .offset(y: screenHeight / 2 - 12)
        }
        .frame(width: screenWidth, height: screenHeight)
        .offset(y: -24)
    }

    private var isWalking: Bool {
        state == .working || funReaction == .pet
    }

    private var crabCharacter: some View {
        CrabView(
            size: 46,
            color: Color(white: 0.55),
            eyeColor: Color.screenDark,
            eyeStyle: currentEyeStyle,
            animateLegs: isWalking
        )
        .offset(y: bobOffset - 4)
    }

    private var screenText: some View {
        Group {
            if state == .permissionNeeded, let perm = pendingPermission {
                VStack(spacing: 1) {
                    Text(perm.tool)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.orange.opacity(0.7))
                    Text("Allow?")
                        .font(.system(size: 6, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            } else {
                Text(stateLabelText)
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
            }
        }
    }

    private var stateLabelText: String {
        switch state {
        case .idle: "zzz"
        case .thinking: "..."
        case .working: ">>>"
        case .done: "^_^"
        case .permissionNeeded: ""
        }
    }

    // MARK: - Interactive buttons

    private var buttons: some View {
        HStack(spacing: 14) {
            if state == .permissionNeeded {
                interactiveButton(baseColor: Color(red: 0.7, green: 0.2, blue: 0.2),
                                  glowColor: .red, lit: true, action: onDeny)
                interactiveButton(baseColor: Color(white: 0.25),
                                  glowColor: .orange, lit: true, action: {})
                interactiveButton(baseColor: Color(red: 0.15, green: 0.5, blue: 0.2),
                                  glowColor: .green, lit: true, action: onApprove)
            } else {
                interactiveButton(baseColor: Color(white: 0.25),
                                  glowColor: .shellPinkLight, lit: sessionCount >= 1, action: onPoke)
                interactiveButton(baseColor: Color(white: 0.25),
                                  glowColor: .shellPinkLight, lit: sessionCount >= 2, action: {})
                interactiveButton(baseColor: Color(white: 0.25),
                                  glowColor: .shellPinkLight, lit: sessionCount >= 3, action: onPet)
            }
        }
        .offset(y: eggHeight / 2 - 46)
    }

    private func interactiveButton(
        baseColor: Color, glowColor: Color, lit: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.black.opacity(0.4)).frame(width: 16, height: 16).offset(y: 1.5)
                Circle().fill(
                    LinearGradient(colors: [baseColor, baseColor.opacity(0.6)],
                                   startPoint: .top, endPoint: .bottom)
                ).frame(width: 15, height: 15)
                if lit {
                    Circle().fill(glowColor.opacity(0.4)).frame(width: 15, height: 15).blur(radius: 4)
                }
                Circle().fill(
                    LinearGradient(colors: [Color.white.opacity(lit ? 0.4 : 0.2), Color.clear],
                                   startPoint: .top, endPoint: .center)
                ).frame(width: 13, height: 13)
                Circle().stroke(Color.black.opacity(0.5), lineWidth: 0.5).frame(width: 15, height: 15)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.3), value: lit)
    }

    // MARK: - Animations

    private func resetAnimations() {
        animGeneration += 1
        blinkTimer?.cancel()
        bobOffset = 0
        eyeOffset = 0
        currentEyeStyle = .normal
        permissionPulse = false
    }

    private func startAnimations(for petState: PetState) {
        let gen = animGeneration
        switch petState {
        case .idle:
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { bobOffset = 3 }
            startBlinkLoop(gen: gen, interval: 3.0)
        case .thinking:
            currentEyeStyle = .normal
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { eyeOffset = 0.8 }
            startBlinkLoop(gen: gen, interval: 2.0)
        case .working:
            currentEyeStyle = .wide
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { bobOffset = 2 }
        case .done:
            currentEyeStyle = .squish
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4).repeatCount(3, autoreverses: true)) { bobOffset = -6 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                guard self.animGeneration == gen else { return }
                withAnimation(.easeInOut(duration: 0.3)) { currentEyeStyle = .normal; bobOffset = 0 }
            }
        case .permissionNeeded:
            currentEyeStyle = .wide
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { permissionPulse = true }
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) { bobOffset = 1 }
        }
    }

    private func applyFunReaction(_ reaction: TamagotchiViewModel.FunReaction) {
        switch reaction {
        case .poke:
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { bobOffset = -10; currentEyeStyle = .wide }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { bobOffset = 0; currentEyeStyle = .squish }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { currentEyeStyle = .normal }
            }
        case .pet:
            withAnimation(.easeInOut(duration: 0.2)) { currentEyeStyle = .squish }
        }
    }

    private func startBlinkLoop(gen: Int, interval: TimeInterval) {
        blinkTimer = Task { @MainActor in
            while !Task.isCancelled && animGeneration == gen {
                try? await Task.sleep(for: .seconds(interval))
                guard animGeneration == gen else { return }
                withAnimation(.easeInOut(duration: 0.08)) { currentEyeStyle = .blink }
                try? await Task.sleep(for: .seconds(0.12))
                guard animGeneration == gen else { return }
                withAnimation(.easeInOut(duration: 0.08)) { currentEyeStyle = .normal }
            }
        }
    }
}

// MARK: - Nothing-style internals (circuit board, traces, components)

struct InternalsView: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2

            let traceColor = Color(red: 0.18, green: 0.22, blue: 0.18)
            let componentColor = Color(white: 0.15)
            let copperColor = Color(red: 0.35, green: 0.28, blue: 0.15)
            let redAccent = Color(red: 0.6, green: 0.12, blue: 0.1)

            // PCB base texture — subtle grid
            let gridSpacing: CGFloat = 8
            var gy: CGFloat = 0
            while gy < size.height {
                var gx: CGFloat = 0
                while gx < size.width {
                    let dot = CGRect(x: gx, y: gy, width: 0.5, height: 0.5)
                    context.fill(Path(dot), with: .color(traceColor.opacity(0.3)))
                    gx += gridSpacing
                }
                gy += gridSpacing
            }

            // Main circuit traces (copper-colored lines)
            let traces: [(CGPoint, CGPoint)] = [
                // Horizontal runs
                (CGPoint(x: cx - 60, y: cy - 70), CGPoint(x: cx + 60, y: cy - 70)),
                (CGPoint(x: cx - 50, y: cy - 60), CGPoint(x: cx - 20, y: cy - 60)),
                (CGPoint(x: cx + 20, y: cy - 60), CGPoint(x: cx + 50, y: cy - 60)),
                (CGPoint(x: cx - 70, y: cy + 40), CGPoint(x: cx + 70, y: cy + 40)),
                (CGPoint(x: cx - 40, y: cy + 55), CGPoint(x: cx + 40, y: cy + 55)),
                (CGPoint(x: cx - 60, y: cy + 70), CGPoint(x: cx - 20, y: cy + 70)),
                (CGPoint(x: cx + 20, y: cy + 70), CGPoint(x: cx + 60, y: cy + 70)),
                // Vertical runs
                (CGPoint(x: cx - 60, y: cy - 70), CGPoint(x: cx - 60, y: cy - 40)),
                (CGPoint(x: cx + 60, y: cy - 70), CGPoint(x: cx + 60, y: cy - 40)),
                (CGPoint(x: cx - 40, y: cy + 40), CGPoint(x: cx - 40, y: cy + 55)),
                (CGPoint(x: cx + 40, y: cy + 40), CGPoint(x: cx + 40, y: cy + 55)),
                (CGPoint(x: cx, y: cy + 55), CGPoint(x: cx, y: cy + 80)),
                // Diagonal runs
                (CGPoint(x: cx - 60, y: cy - 40), CGPoint(x: cx - 40, y: cy - 20)),
                (CGPoint(x: cx + 60, y: cy - 40), CGPoint(x: cx + 40, y: cy - 20)),
            ]

            for (start, end) in traces {
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(path, with: .color(copperColor.opacity(0.5)),
                               style: StrokeStyle(lineWidth: 1))
            }

            // Thicker power traces
            let powerTraces: [(CGPoint, CGPoint)] = [
                (CGPoint(x: cx - 30, y: cy + 80), CGPoint(x: cx - 30, y: cy + 100)),
                (CGPoint(x: cx + 30, y: cy + 80), CGPoint(x: cx + 30, y: cy + 100)),
            ]
            for (start, end) in powerTraces {
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(path, with: .color(copperColor.opacity(0.4)),
                               style: StrokeStyle(lineWidth: 2))
            }

            // IC chip (main processor) — top area
            let chipRect = CGRect(x: cx - 14, y: cy - 75, width: 28, height: 16)
            context.fill(Path(chipRect), with: .color(componentColor))
            context.stroke(Path(chipRect), with: .color(copperColor.opacity(0.3)),
                           style: StrokeStyle(lineWidth: 0.5))
            // IC pins
            for i in 0..<5 {
                let pinX = chipRect.minX + 3 + CGFloat(i) * 5.5
                let topPin = CGRect(x: pinX, y: chipRect.minY - 2, width: 2, height: 2)
                let botPin = CGRect(x: pinX, y: chipRect.maxY, width: 2, height: 2)
                context.fill(Path(topPin), with: .color(copperColor.opacity(0.6)))
                context.fill(Path(botPin), with: .color(copperColor.opacity(0.6)))
            }

            // Small SMD components (resistors/capacitors)
            let smds: [CGRect] = [
                CGRect(x: cx - 50, y: cy - 45, width: 6, height: 3),
                CGRect(x: cx - 38, y: cy - 45, width: 6, height: 3),
                CGRect(x: cx + 32, y: cy - 45, width: 6, height: 3),
                CGRect(x: cx + 44, y: cy - 45, width: 6, height: 3),
                CGRect(x: cx - 55, y: cy + 45, width: 3, height: 6),
                CGRect(x: cx + 52, y: cy + 45, width: 3, height: 6),
                CGRect(x: cx - 18, y: cy + 62, width: 6, height: 3),
                CGRect(x: cx + 12, y: cy + 62, width: 6, height: 3),
            ]
            for smd in smds {
                context.fill(Path(smd), with: .color(componentColor))
                context.stroke(Path(smd), with: .color(copperColor.opacity(0.4)),
                               style: StrokeStyle(lineWidth: 0.3))
            }

            // Red LED indicator (Nothing signature)
            let ledRect = CGRect(x: cx + 35, y: cy + 75, width: 5, height: 5)
            context.fill(Path(ledRect), with: .color(redAccent.opacity(0.8)))
            // LED glow
            let ledGlow = Path(ellipseIn: ledRect.insetBy(dx: -3, dy: -3))
            context.fill(ledGlow, with: .color(redAccent.opacity(0.15)))

            // Wireless coil (bottom area)
            let coilCenter = CGPoint(x: cx, y: cy + 90)
            for i in 0..<3 {
                let r = 10 + CGFloat(i) * 5
                let coilPath = Path(ellipseIn: CGRect(
                    x: coilCenter.x - r, y: coilCenter.y - r * 0.5,
                    width: r * 2, height: r
                ))
                context.stroke(coilPath, with: .color(copperColor.opacity(0.25)),
                               style: StrokeStyle(lineWidth: 0.8))
            }

            // Via holes (small dots where traces go through layers)
            let vias: [CGPoint] = [
                CGPoint(x: cx - 40, y: cy - 20),
                CGPoint(x: cx + 40, y: cy - 20),
                CGPoint(x: cx - 20, y: cy + 40),
                CGPoint(x: cx + 20, y: cy + 40),
                CGPoint(x: cx, y: cy + 55),
                CGPoint(x: cx - 60, y: cy - 40),
                CGPoint(x: cx + 60, y: cy - 40),
            ]
            for via in vias {
                let viaPath = Path(ellipseIn: CGRect(x: via.x - 2, y: via.y - 2, width: 4, height: 4))
                context.fill(viaPath, with: .color(copperColor.opacity(0.5)))
                let holePath = Path(ellipseIn: CGRect(x: via.x - 0.8, y: via.y - 0.8, width: 1.6, height: 1.6))
                context.fill(holePath, with: .color(Color(white: 0.05)))
            }

            // Tiny text labels on PCB
            context.draw(
                Text("v2.0").font(.system(size: 4, design: .monospaced)).foregroundStyle(copperColor.opacity(0.3)),
                at: CGPoint(x: cx + 50, y: cy + 85)
            )
            context.draw(
                Text("PWR").font(.system(size: 3, design: .monospaced)).foregroundStyle(copperColor.opacity(0.25)),
                at: CGPoint(x: cx - 30, y: cy + 103)
            )
            context.draw(
                Text("GND").font(.system(size: 3, design: .monospaced)).foregroundStyle(copperColor.opacity(0.25)),
                at: CGPoint(x: cx + 30, y: cy + 103)
            )
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Pixel grid overlay

struct PixelGridOverlay: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 4
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let dot = CGRect(x: x, y: y, width: 1, height: 1)
                    context.fill(Path(dot), with: .color(.white.opacity(0.03)))
                    x += spacing
                }
                y += spacing
            }
        }
    }
}
