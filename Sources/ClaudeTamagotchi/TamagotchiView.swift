import SwiftUI

struct TamagotchiView: View {
    let state: PetState
    let sessionCount: Int

    @State private var bobOffset: CGFloat = 0
    @State private var eyeOffset: CGFloat = 0
    @State private var currentEyeStyle: EyeStyle = .normal
    @State private var animGeneration: Int = 0
    @State private var blinkTimer: Task<Void, Never>?

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
        }
        .frame(width: eggWidth + padding * 2, height: eggHeight + padding * 2)
        .onChange(of: state) { _, newState in
            resetAnimations()
            startAnimations(for: newState)
        }
        .onAppear {
            startAnimations(for: state)
        }
        .onDisappear {
            blinkTimer?.cancel()
        }
    }

    // MARK: - Egg shell

    private var egg: some View {
        ZStack {
            EggShape()
                .fill(Color.black.opacity(0.25))
                .frame(width: eggWidth, height: eggHeight)
                .offset(y: 5)
                .blur(radius: 12)

            EggShape()
                .fill(
                    LinearGradient(
                        colors: [.shellPinkLight, .shellPink, .shellPinkDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: eggWidth, height: eggHeight)

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

    private var specularHighlight: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [Color.white.opacity(0.45), Color.white.opacity(0.0)],
                    center: .center, startRadius: 0, endRadius: 40
                )
            )
            .frame(width: 70, height: 30)
            .offset(x: -30, y: -(eggHeight * 0.30))
            .allowsHitTesting(false)
    }

    private var brandLabel: some View {
        Text("TAMAGOTCHI")
            .font(.system(size: 8, weight: .heavy, design: .rounded))
            .tracking(2)
            .foregroundStyle(Color.shellPinkDark.opacity(0.7))
            .offset(y: -(eggHeight * 0.24))
    }

    // MARK: - Screen inset

    private var screenInset: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.shellPinkDark.opacity(0.8))
                .frame(width: screenWidth + 16, height: screenHeight + 14)

            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.4), Color.black.opacity(0.15)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: screenWidth + 8, height: screenHeight + 6)

            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    LinearGradient(
                        colors: [Color.black.opacity(0.5), Color.clear, Color.white.opacity(0.1)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1.5
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

            stateLabel
                .offset(y: screenHeight / 2 - 10)
        }
        .frame(width: screenWidth, height: screenHeight)
        .offset(y: -24)
    }

    private var crabCharacter: some View {
        CrabView(
            pixelSize: 5,
            bodyColor: Color(white: 0.55),
            eyeColor: Color.screenDark,
            eyeStyle: currentEyeStyle,
            eyeOffsetX: eyeOffset
        )
        .offset(y: bobOffset - 2)
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

    // MARK: - Buttons (light up per active session)

    private var buttons: some View {
        HStack(spacing: 14) {
            tamaButton(lit: sessionCount >= 1)
            tamaButton(lit: sessionCount >= 2)
            tamaButton(lit: sessionCount >= 3)
        }
        .offset(y: eggHeight / 2 - 46)
    }

    private func tamaButton(lit: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 16, height: 16)
                .offset(y: 1.5)

            Circle()
                .fill(
                    lit
                    ? LinearGradient(
                        colors: [Color.shellPinkLight, Color.shellPinkDark],
                        startPoint: .top, endPoint: .bottom)
                    : LinearGradient(
                        colors: [Color(white: 0.35), Color(white: 0.18)],
                        startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 15, height: 15)

            if lit {
                Circle()
                    .fill(Color.shellPinkLight.opacity(0.5))
                    .frame(width: 15, height: 15)
                    .blur(radius: 4)
            }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(lit ? 0.4 : 0.25), Color.clear],
                        startPoint: .top, endPoint: .center
                    )
                )
                .frame(width: 13, height: 13)

            Circle()
                .stroke(Color.black.opacity(0.5), lineWidth: 0.5)
                .frame(width: 15, height: 15)
        }
        .animation(.easeInOut(duration: 0.3), value: lit)
    }

    // MARK: - Animations

    private func resetAnimations() {
        animGeneration += 1
        blinkTimer?.cancel()
        bobOffset = 0
        eyeOffset = 0
        currentEyeStyle = .normal
    }

    private func startAnimations(for petState: PetState) {
        let gen = animGeneration

        switch petState {
        case .idle:
            // Gentle bob + periodic blink
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bobOffset = 3
            }
            startBlinkLoop(gen: gen, interval: 3.0)

        case .thinking:
            // Eyes look side to side
            currentEyeStyle = .normal
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                eyeOffset = 0.8
            }
            startBlinkLoop(gen: gen, interval: 2.0)

        case .working:
            // Wide eyes + faster bob
            currentEyeStyle = .wide
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                bobOffset = 2
            }

        case .done:
            // Happy squish eyes + bounce
            currentEyeStyle = .squish
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4).repeatCount(3, autoreverses: true)) {
                bobOffset = -6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                guard self.animGeneration == gen else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentEyeStyle = .normal
                    bobOffset = 0
                }
            }
        }
    }

    private func startBlinkLoop(gen: Int, interval: TimeInterval) {
        blinkTimer = Task { @MainActor in
            while !Task.isCancelled && animGeneration == gen {
                try? await Task.sleep(for: .seconds(interval))
                guard animGeneration == gen else { return }

                withAnimation(.easeInOut(duration: 0.08)) {
                    currentEyeStyle = .blink
                }
                try? await Task.sleep(for: .seconds(0.12))
                guard animGeneration == gen else { return }

                withAnimation(.easeInOut(duration: 0.08)) {
                    currentEyeStyle = .normal
                }
            }
        }
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
