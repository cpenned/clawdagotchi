import SwiftUI

struct TamagotchiView: View {
    let state: PetState
    let sessionCount: Int

    @State private var bobOffset: CGFloat = 0
    @State private var pulseOpacity: Double = 1.0
    @State private var bounceScale: CGFloat = 1.0
    @State private var donePop: CGFloat = 1.0
    @State private var showCheckmark = false
    @State private var sparkleRotation: Double = 0
    @State private var animGeneration: Int = 0

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                characterBody
                eyesOverlay
                if sessionCount > 1 {
                    sessionBadge
                }
                if state == .working {
                    sparkles
                }
                if showCheckmark {
                    checkmark
                }
            }
            .frame(width: 120, height: 120)

            if state == .thinking {
                ThinkingDotsView()
            }
        }
        .onChange(of: state) { _, newState in
            resetAnimations()
            startAnimations(for: newState)
        }
        .onAppear {
            startAnimations(for: state)
        }
    }

    // MARK: - Character body

    private var characterBody: some View {
        ClaudeShape()
            .fill(Color.claudeOrange)
            .frame(width: 80, height: 80)
            .scaleEffect(state == .working ? bounceScale : (state == .done ? donePop : 1.0))
            .opacity(state == .thinking ? pulseOpacity : 1.0)
            .offset(y: state == .idle ? bobOffset : 0)
    }

    // MARK: - Eyes

    private var eyesOverlay: some View {
        Group {
            switch state {
            case .idle:
                idleEyes
            case .thinking:
                thinkingEyes
            case .working:
                workingEyes
            case .done:
                doneEyes
            }
        }
        .offset(y: state == .idle ? bobOffset : 0)
    }

    private var idleEyes: some View {
        HStack(spacing: 18) {
            SleepyEye()
            SleepyEye()
        }
        .offset(y: -4)
    }

    private var thinkingEyes: some View {
        HStack(spacing: 18) {
            Circle().fill(.white).frame(width: 6, height: 6)
            Circle().fill(.white).frame(width: 6, height: 6)
        }
        .offset(y: -4)
    }

    private var workingEyes: some View {
        HStack(spacing: 14) {
            Circle().fill(.white).frame(width: 10, height: 10)
            Circle().fill(.white).frame(width: 10, height: 10)
        }
        .offset(y: -4)
    }

    private var doneEyes: some View {
        SmileArc()
            .stroke(.white, lineWidth: 2)
            .frame(width: 24, height: 8)
            .scaleEffect(y: -1)
            .offset(y: 2)
    }

    // MARK: - Session badge

    private var sessionBadge: some View {
        Text("\(sessionCount)")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(Circle().fill(.orange))
            .offset(x: 34, y: -34)
    }

    // MARK: - Sparkles (working)

    private var sparkles: some View {
        ForEach(0..<6, id: \.self) { i in
            Text("\u{2726}")
                .font(.system(size: 10))
                .foregroundStyle(Color.claudeOrange.opacity(0.7))
                .offset(sparkleOffset(index: i))
                .rotationEffect(.degrees(sparkleRotation + Double(i) * 60))
        }
    }

    private func sparkleOffset(index: Int) -> CGSize {
        let angle = (Double(index) / 6.0) * .pi * 2 + sparkleRotation * .pi / 180
        return CGSize(width: cos(angle) * 50, height: sin(angle) * 50)
    }

    // MARK: - Checkmark (done)

    private var checkmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 22))
            .foregroundStyle(.green)
            .offset(y: -50)
            .transition(.opacity)
    }

    // MARK: - Animation control

    private func resetAnimations() {
        animGeneration += 1
        bobOffset = 0
        pulseOpacity = 1.0
        bounceScale = 1.0
        donePop = 1.0
        showCheckmark = false
        sparkleRotation = 0
    }

    private func startAnimations(for petState: PetState) {
        switch petState {
        case .idle:
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                bobOffset = 8
            }
        case .thinking:
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.6
            }
        case .working:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).repeatForever(autoreverses: true)) {
                bounceScale = 1.12
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        case .done:
            let gen = animGeneration
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                donePop = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard self.animGeneration == gen else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    donePop = 1.0
                }
            }
            withAnimation { showCheckmark = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard self.animGeneration == gen else { return }
                withAnimation { showCheckmark = false }
            }
        }
    }
}

// MARK: - Sub-shapes

struct SleepyEye: View {
    var body: some View {
        SmileArc()
            .stroke(.white, lineWidth: 2)
            .frame(width: 12, height: 5)
    }
}

struct SmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY),
            radius: rect.width / 2,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        return path
    }
}

struct ThinkingDotsView: View {
    @State private var dot1: Double = 0
    @State private var dot2: Double = 0
    @State private var dot3: Double = 0

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(Color.claudeOrange).frame(width: 8, height: 8).opacity(dot1)
            Circle().fill(Color.claudeOrange).frame(width: 8, height: 8).opacity(dot2)
            Circle().fill(Color.claudeOrange).frame(width: 8, height: 8).opacity(dot3)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                dot1 = 1
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2)) {
                dot2 = 1
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.4)) {
                dot3 = 1
            }
        }
    }
}
