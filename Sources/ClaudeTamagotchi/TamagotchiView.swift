import SwiftUI

struct TamagotchiView: View {
    let state: PetState
    let sessionCount: Int

    @State private var bobOffset: CGFloat = 0
    @State private var crabWalk: CGFloat = 0
    @State private var pulseOpacity: Double = 1.0
    @State private var bounceY: CGFloat = 0
    @State private var showCheckmark = false
    @State private var animGeneration: Int = 0

    private let eggWidth: CGFloat = 200
    private let eggHeight: CGFloat = 260
    private let screenWidth: CGFloat = 120
    private let screenHeight: CGFloat = 100

    var body: some View {
        ZStack {
            // Egg shell
            egg

            // Screen bezel
            bezel

            // LCD screen with crab
            lcdScreen

            // Buttons
            buttons

            // Session badge
            if sessionCount > 1 {
                sessionBadge
            }
        }
        .frame(width: eggWidth + 10, height: eggHeight + 10)
        .onChange(of: state) { _, newState in
            resetAnimations()
            startAnimations(for: newState)
        }
        .onAppear {
            startAnimations(for: state)
        }
    }

    // MARK: - Egg shell

    private var egg: some View {
        EggShape()
            .fill(Color.claudePink)
            .frame(width: eggWidth, height: eggHeight)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }

    // MARK: - Scalloped bezel

    private var bezel: some View {
        ScallopBezel()
            .fill(Color.claudePinkDark)
            .frame(width: screenWidth + 24, height: screenHeight + 20)
            .offset(y: -28)
    }

    // MARK: - LCD screen

    private var lcdScreen: some View {
        ZStack {
            // Green LCD background
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.lcdGreenLight)

            // Scanlines
            ScanlineOverlay()
                .clipShape(RoundedRectangle(cornerRadius: 4))

            // Status icons row (top)
            statusIcons
                .offset(y: -(screenHeight / 2 - 10))

            // Crab character
            crabCharacter

            // State indicator at bottom
            stateLabel
                .offset(y: screenHeight / 2 - 10)
        }
        .frame(width: screenWidth, height: screenHeight)
        .offset(y: -28)
    }

    private var crabCharacter: some View {
        CrabView(pixelSize: 5)
            .opacity(state == .thinking ? pulseOpacity : 1.0)
            .offset(
                x: state == .working ? crabWalk : 0,
                y: state == .idle ? bobOffset : (state == .done ? bounceY : 0)
            )
    }

    private var statusIcons: some View {
        HStack(spacing: 8) {
            PixelIcon(symbol: "fork.knife").frame(width: 10, height: 10)
            PixelIcon(symbol: "face.smiling").frame(width: 10, height: 10)
            PixelIcon(symbol: "scissors").frame(width: 10, height: 10)
            PixelIcon(symbol: "syringe").frame(width: 10, height: 10)
        }
        .font(.system(size: 7))
        .foregroundStyle(Color.black.opacity(0.3))
    }

    private var stateLabel: some View {
        Text(stateLabelText)
            .font(.system(size: 7, weight: .medium, design: .monospaced))
            .foregroundStyle(Color.black.opacity(0.4))
    }

    private var stateLabelText: String {
        switch state {
        case .idle: "zzz"
        case .thinking: "..."
        case .working: ">>>"
        case .done: "^_^"
        }
    }

    // MARK: - Buttons

    private var buttons: some View {
        HStack(spacing: 16) {
            Circle().fill(.black).frame(width: 14, height: 14)
            Circle().fill(.black).frame(width: 14, height: 14)
            Circle().fill(.black).frame(width: 14, height: 14)
        }
        .offset(y: eggHeight / 2 - 42)
    }

    // MARK: - Session badge

    private var sessionBadge: some View {
        Text("\(sessionCount)")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(Circle().fill(.black))
            .offset(x: eggWidth / 2 - 16, y: -(eggHeight / 2 - 30))
    }

    // MARK: - Animations

    private func resetAnimations() {
        animGeneration += 1
        bobOffset = 0
        crabWalk = 0
        pulseOpacity = 1.0
        bounceY = 0
        showCheckmark = false
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

// MARK: - Scanlines overlay

struct ScanlineOverlay: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 3
            var y: CGFloat = 0
            while y < size.height {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                context.fill(Path(rect), with: .color(.black.opacity(0.06)))
                y += spacing
            }
        }
    }
}

// MARK: - Pixel icons (decorative)

struct PixelIcon: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
    }
}
