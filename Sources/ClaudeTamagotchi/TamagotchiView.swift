import SwiftUI

struct TamagotchiView: View {
    let state: PetState
    let sessionCount: Int

    @State private var bobOffset: CGFloat = 0
    @State private var crabWalk: CGFloat = 0
    @State private var pulseOpacity: Double = 1.0
    @State private var bounceY: CGFloat = 0
    @State private var animGeneration: Int = 0

    private let eggWidth: CGFloat = 190
    private let eggHeight: CGFloat = 250
    private let screenWidth: CGFloat = 110
    private let screenHeight: CGFloat = 90
    private let padding: CGFloat = 30

    var body: some View {
        ZStack {
            egg
            specularHighlight
            brandLabel
            screenInset
            lcdScreen
            buttons
            if sessionCount > 1 {
                sessionBadge
            }
        }
        .frame(width: eggWidth + padding * 2, height: eggHeight + padding * 2)
        .onChange(of: state) { _, newState in
            resetAnimations()
            startAnimations(for: newState)
        }
        .onAppear {
            startAnimations(for: state)
        }
    }

    // MARK: - Egg shell (realistic plastic)

    private var egg: some View {
        ZStack {
            // Base shadow layer
            EggShape()
                .fill(Color.black.opacity(0.25))
                .frame(width: eggWidth, height: eggHeight)
                .offset(y: 5)
                .blur(radius: 12)

            // Main body with plastic gradient
            EggShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.shellPinkLight,
                            Color.shellPink,
                            Color.shellPinkDark
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: eggWidth, height: eggHeight)

            // Rim highlight (edge catch light)
            EggShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: eggWidth, height: eggHeight)
        }
    }

    // MARK: - Specular highlight (glossy plastic reflection)

    private var specularHighlight: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.45),
                        Color.white.opacity(0.0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 40
                )
            )
            .frame(width: 70, height: 30)
            .offset(x: -30, y: -(eggHeight * 0.30))
            .allowsHitTesting(false)
    }

    // MARK: - Brand label

    private var brandLabel: some View {
        Text("TAMAGOTCHI")
            .font(.system(size: 8, weight: .heavy, design: .rounded))
            .tracking(2)
            .foregroundStyle(Color.shellPinkDark.opacity(0.7))
            .offset(y: -(eggHeight * 0.24))
    }

    // MARK: - Screen inset (recessed bezel)

    private var screenInset: some View {
        ZStack {
            // Outer dark ring (depth shadow)
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.shellPinkDark.opacity(0.8))
                .frame(width: screenWidth + 16, height: screenHeight + 14)

            // Inner bevel (lighter inside edge)
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: screenWidth + 8, height: screenHeight + 6)

            // Inner shadow top edge
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.5),
                            Color.clear,
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
                .frame(width: screenWidth + 4, height: screenHeight + 2)
        }
        .offset(y: -24)
    }

    // MARK: - LCD screen (dark modern)

    private var lcdScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.screenDark)

            // Subtle pixel grid
            PixelGridOverlay()
                .clipShape(RoundedRectangle(cornerRadius: 5))

            // Crab
            crabCharacter

            // State text
            stateLabel
                .offset(y: screenHeight / 2 - 10)
        }
        .frame(width: screenWidth, height: screenHeight)
        .offset(y: -24)
    }

    private var crabCharacter: some View {
        CrabView(pixelSize: 5, color: Color(white: 0.55))
            .opacity(state == .thinking ? pulseOpacity : 1.0)
            .offset(
                x: state == .working ? crabWalk : 0,
                y: state == .idle ? bobOffset : (state == .done ? bounceY : -2)
            )
    }

    private var stateLabel: some View {
        Text(stateLabelText)
            .font(.system(size: 7, weight: .medium, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.2))
    }

    private var stateLabelText: String {
        switch state {
        case .idle: "zzz"
        case .thinking: "..."
        case .working: ">>>"
        case .done: "^_^"
        }
    }

    // MARK: - Buttons (3D realistic)

    private var buttons: some View {
        HStack(spacing: 14) {
            tamaButton
            tamaButton
            tamaButton
        }
        .offset(y: eggHeight / 2 - 46)
    }

    private var tamaButton: some View {
        ZStack {
            // Button shadow
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 16, height: 16)
                .offset(y: 1.5)

            // Button body
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.35),
                            Color(white: 0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 15, height: 15)

            // Top highlight
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(width: 13, height: 13)

            // Rim
            Circle()
                .stroke(Color.black.opacity(0.5), lineWidth: 0.5)
                .frame(width: 15, height: 15)
        }
    }

    // MARK: - Session badge

    private var sessionBadge: some View {
        Text("\(sessionCount)")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .frame(width: 16, height: 16)
            .background(Circle().fill(Color(white: 0.3)))
            .offset(x: eggWidth / 2 - 14, y: -(eggHeight / 2 - 28))
    }

    // MARK: - Animations

    private func resetAnimations() {
        animGeneration += 1
        bobOffset = 0
        crabWalk = 0
        pulseOpacity = 1.0
        bounceY = 0
    }

    private func startAnimations(for petState: PetState) {
        let gen = animGeneration
        switch petState {
        case .idle:
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bobOffset = 4
            }
        case .thinking:
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.3
            }
        case .working:
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                crabWalk = 12
            }
        case .done:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4).repeatCount(3, autoreverses: true)) {
                bounceY = -8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard self.animGeneration == gen else { return }
                withAnimation { bounceY = 0 }
            }
        }
    }
}

// MARK: - Pixel grid overlay (modern dark screen texture)

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
