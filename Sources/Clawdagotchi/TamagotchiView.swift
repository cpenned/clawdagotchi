import SwiftUI

struct TamagotchiView: View {
    let state: PetState
    let sessionCount: Int
    let pendingPermission: PendingPermission?
    let pendingPermissionCount: Int
    let hunger: Double
    let happiness: Double
    let moodState: MoodState
    let poopCount: Int
    let greetingMessage: String
    let funReaction: TamagotchiViewModel.FunReaction?
    var onApprove: () -> Void = {}
    var onDeny: () -> Void = {}
    var onPoke: () -> Void = {}
    var onFeed: () -> Void = {}
    var onPet: () -> Void = {}

    @State private var bobOffset: CGFloat = 0
    @State private var eyeOffset: CGFloat = 0
    @State private var currentEyeStyle: EyeStyle = .normal
    @State private var animGeneration: Int = 0
    @State private var blinkTimer: Task<Void, Never>?
    @State private var permissionPulse: Bool = false
    @State private var scrollMessage: String = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var showScrollMessage: Bool = false
    @State private var permScrollOffset: CGFloat = 0
    @State private var permScrollTimer: Task<Void, Never>?
    @State private var zzzOffset: CGFloat = 0
    @State private var zzzOpacity: Double = 0
    @State private var zzzTimer: Task<Void, Never>?
    @State private var hasShownGreeting: Bool = false
    @State private var angrySteamOffset: CGFloat = 0
    @State private var angrySteamOpacity: Double = 0
    @State private var angrySteamTimer: Task<Void, Never>?

    private let eggWidth: CGFloat = 190
    private let eggHeight: CGFloat = 250
    private let screenWidth: CGFloat = 110
    private let screenHeight: CGFloat = 90
    private let padding: CGFloat = 40

    private var style: ShellStyle { AppSettings.shared.shellStyle }

    var body: some View {
        ZStack {
            // Layer 1: Drop shadow
            eggDropShadow
            // Layer 2: Internal cavity
            internalCavity
            // Layer 3: Internals (circuit board)
            internalsLayer
            // Layer 4: Shell wall thickness
            shellWallThickness
            // Layer 5: Translucent shell
            translucentShell
            // Layer 6: Inner glow
            innerGlow
            // Layer 7: Surface texture
            surfaceTexture
            // Layer 8: Edge refraction
            edgeRefraction
            // Layer 9: Specular highlight
            specularHighlight
            brandLabel
            screwDots
            screenInset
            lcdScreen
            buttons
        }
        .frame(width: eggWidth + padding * 2, height: eggHeight + padding * 2)
        .rotation3DEffect(.degrees(3), axis: (x: 1, y: -0.5, z: 0), perspective: 0.8)
        .onChange(of: state) { _, newState in
            resetAnimations()
            startAnimations(for: newState)
        }
        .onChange(of: funReaction) { _, reaction in
            if let reaction { applyFunReaction(reaction) }
        }
        .onAppear {
            startAnimations(for: state)
            if !hasShownGreeting && !greetingMessage.isEmpty {
                hasShownGreeting = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showMarquee(greetingMessage)
                }
            }
        }
        .onDisappear { blinkTimer?.cancel(); zzzTimer?.cancel() }
        .onChange(of: moodState) { _, newMood in
            applyMoodAnimation(newMood)
        }
    }

    // MARK: - Shell layers

    private var eggDropShadow: some View {
        EggShape()
            .fill(Color.black.opacity(0.45))
            .frame(width: eggWidth, height: eggHeight)
            .offset(y: 8)
            .blur(radius: 18)
    }

    private var internalCavity: some View {
        EggShape()
            .fill(Color(white: 0.06))
            .frame(width: eggWidth - 6, height: eggHeight - 6)
    }

    private var internalsLayer: some View {
        InternalsView(width: eggWidth, height: eggHeight)
            .clipShape(EggShape())
            .frame(width: eggWidth - 6, height: eggHeight - 6)
            .opacity(style.internalsOpacity)
    }

    private var shellWallThickness: some View {
        ZStack {
            EggShape()
                .stroke(style.tintColor.opacity(0.25), lineWidth: 1)
                .frame(width: eggWidth, height: eggHeight)
            EggShape()
                .stroke(style.tintColor.opacity(0.18), lineWidth: 1)
                .frame(width: eggWidth - 8, height: eggHeight - 8)
        }
    }

    private var translucentShell: some View {
        EggShape()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: style.highlightColor.opacity(style.tintOpacity + 0.1), location: 0.0),
                        .init(color: style.tintColor.opacity(style.tintOpacity), location: 0.5),
                        .init(color: style.shadowColor.opacity(style.tintOpacity + 0.05), location: 1.0),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: eggWidth, height: eggHeight)
    }

    private var innerGlow: some View {
        EggShape()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: style.tintColor.opacity(0.08), location: 0.0),
                        .init(color: Color.clear, location: 0.7),
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: eggWidth * 0.55
                )
            )
            .frame(width: eggWidth, height: eggHeight)
            .allowsHitTesting(false)
    }

    private var surfaceTexture: some View {
        Canvas { context, size in
            // Deterministic plastic grain — no randomness per frame
            let cols = Int(size.width / 4)
            let rows = Int(size.height / 4)
            for row in 0..<rows {
                for col in 0..<cols {
                    // Simple hash for deterministic "random" placement
                    let seed = (row * 7919 + col * 6271) % 100
                    guard seed < 14 else { continue }
                    let x = CGFloat(col) * 4 + CGFloat(seed % 4)
                    let y = CGFloat(row) * 4 + CGFloat((seed / 4) % 4)
                    let dot = CGRect(x: x, y: y, width: 1, height: 1)
                    let opacity = seed < 7 ? 0.012 : 0.018
                    context.fill(Path(dot), with: .color(Color.white.opacity(opacity)))
                }
            }
        }
        .clipShape(EggShape())
        .frame(width: eggWidth, height: eggHeight)
        .allowsHitTesting(false)
    }

    private var edgeRefraction: some View {
        EggShape()
            .stroke(
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.75), location: 0.0),
                        .init(color: Color.white.opacity(0.30), location: 0.18),
                        .init(color: Color.clear, location: 0.45),
                        .init(color: Color.clear, location: 0.72),
                        .init(color: style.edgeHighlight.opacity(0.22), location: 1.0),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .frame(width: eggWidth, height: eggHeight)
            .allowsHitTesting(false)
    }

    private var specularHighlight: some View {
        Ellipse()
            .fill(RadialGradient(
                colors: [Color.white.opacity(style.specularIntensity), Color.white.opacity(0.0)],
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
            .foregroundStyle(style.labelColor)
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
            // Outer dark bezel with subtle metallic gradient
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.18), Color(white: 0.10)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: screenWidth + 16, height: screenHeight + 14)

            // Inner bevel shadow
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.7), Color.black.opacity(0.35)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: screenWidth + 8, height: screenHeight + 6)

            if state == .permissionNeeded {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(permissionPulse ? 0.6 : 0.2), lineWidth: 2)
                    .frame(width: screenWidth + 8, height: screenHeight + 6)
            }

            // Gasket ring
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black.opacity(0.8), lineWidth: 0.5)
                .frame(width: screenWidth + 2, height: screenHeight)

            // Inner edge bevel
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

            // Inner shadow at top (shadow cast by bezel)
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.35), Color.clear],
                        startPoint: .top, endPoint: .init(x: 0.5, y: 0.25)
                    )
                )

            PixelGridOverlay()
                .clipShape(RoundedRectangle(cornerRadius: 5))

            statusBars
                .offset(y: -(screenHeight / 2 - 10))

            crabCharacter

            // Rising zzz when sleeping
            if moodState == .sleeping {
                risingZzz
            }

            // Angry steam
            if moodState == .angry {
                angrySteam
            }

            // Poops pile up — pet to clean one at a time
            ForEach(0..<min(poopCount, 5), id: \.self) { i in
                PixelPoop()
                    .offset(
                        x: screenWidth / 2 - 18 - CGFloat(i) * 10,
                        y: screenHeight / 2 - 22
                    )
            }

            screenText
                .offset(y: screenHeight / 2 - 12)

        }
        .frame(width: screenWidth, height: screenHeight)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .offset(y: -24)
    }

    private var isWalking: Bool {
        state == .working || funReaction == .pet
    }

    private var crabCharacter: some View {
        CrabView(
            size: 42,
            color: AppSettings.shared.activeCrabColor,
            eyeColor: Color.screenDark,
            eyeStyle: currentEyeStyle,
            animateLegs: isWalking
        )
        .offset(y: bobOffset)
    }

    private var statusBars: some View {
        HStack(spacing: 4) {
            Text(AppSettings.shared.botName)
                .font(.system(size: 5, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.25))

            Spacer()

            PixelStatBar(value: hunger, label: "FD")
            PixelStatBar(value: happiness, label: "HP")
        }
        .frame(width: screenWidth - 12)
    }

    private var screenText: some View {
        Group {
            if state == .permissionNeeded, let perm = pendingPermission {
                VStack(spacing: 2) {
                    Text(perm.project.isEmpty ? "Allow \(perm.tool)?" : perm.project)
                        .font(.system(size: 6, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.orange.opacity(0.7))

                    // Scrolling detail of what's being requested
                    Text(permissionDetailText(perm))
                        .font(.system(size: 5, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .fixedSize()
                        .offset(x: permScrollOffset)

                    if pendingPermissionCount > 1 {
                        Text("1 of \(pendingPermissionCount)")
                            .font(.system(size: 5, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.15))
                    }
                }
                .onAppear { startPermissionScroll(perm) }
                .onChange(of: perm.id) { _, _ in
                    if let p = pendingPermission { startPermissionScroll(p) }
                }
            } else if showScrollMessage {
                Text(scrollMessage)
                    .font(.system(size: 6, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .fixedSize()
                    .offset(x: scrollOffset)
            } else {
                Text(stateLabelText)
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
            }
        }
        .frame(width: screenWidth - 10, alignment: .center)
        .clipped()
    }

    private func permissionDetailText(_ perm: PendingPermission) -> String {
        if perm.toolInput.isEmpty { return perm.tool }
        return perm.toolInput
    }

    private func startPermissionScroll(_ perm: PendingPermission) {
        permScrollTimer?.cancel()
        permScrollOffset = 0

        let text = permissionDetailText(perm)
        // Approximate: 3.5px per character at size 5 monospaced
        let textWidth = CGFloat(text.count) * 3.5
        let available = screenWidth - 20

        guard textWidth > available else { return }

        permScrollTimer = Task { @MainActor in
            while !Task.isCancelled {
                permScrollOffset = available / 2 + 10
                withAnimation(.linear(duration: max(4.0, Double(text.count) * 0.18))) {
                    permScrollOffset = -(textWidth + 10)
                }
                try? await Task.sleep(for: .seconds(max(5.0, Double(text.count) * 0.18 + 1.0)))
            }
        }
    }

    private func showMarquee(_ message: String) {
        scrollMessage = message
        showScrollMessage = true

        let textWidth = CGFloat(message.count) * 4.0
        let available = screenWidth - 20

        if textWidth > available {
            let duration = max(4.0, Double(message.count) * 0.2)
            scrollOffset = screenWidth / 2 + 20
            withAnimation(.linear(duration: duration)) {
                scrollOffset = -(screenWidth / 2 + 20)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
                showScrollMessage = false
            }
        } else {
            scrollOffset = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                showScrollMessage = false
            }
        }
    }

    private var stateLabelText: String {
        if state == .idle {
            switch moodState {
            case .sleeping: return "zzz..."
            case .hungry: return "i'm hungry!"
            case .angry: return "hmph!"
            case .pooping: return "oops"
            case .normal: return "~"
            }
        }
        switch state {
        case .idle: return "~"
        case .thinking: return "..."
        case .working: return ">>>"
        case .done: return "^_^"
        case .permissionNeeded: return ""
        }
    }

    // MARK: - Rising zzz animation

    private var risingZzz: some View {
        Text("z z z")
            .font(.system(size: 6, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.white.opacity(zzzOpacity))
            .offset(x: 20, y: -15 + zzzOffset)
    }

    private func startZzzAnimation() {
        zzzTimer?.cancel()
        zzzTimer = Task { @MainActor in
            while !Task.isCancelled {
                zzzOffset = 0
                zzzOpacity = 0.4
                withAnimation(.easeOut(duration: 2.0)) {
                    zzzOffset = -20
                    zzzOpacity = 0
                }
                try? await Task.sleep(for: .seconds(2.5))
            }
        }
    }

    // MARK: - Angry steam animation

    private var angrySteam: some View {
        PixelAnger()
            .opacity(angrySteamOpacity)
            .offset(x: -18, y: -20 + angrySteamOffset)
    }

    private func startAngrySteamAnimation() {
        angrySteamTimer?.cancel()
        angrySteamTimer = Task { @MainActor in
            while !Task.isCancelled {
                angrySteamOffset = 0
                angrySteamOpacity = 0.8
                withAnimation(.easeOut(duration: 1.5)) {
                    angrySteamOffset = -15
                    angrySteamOpacity = 0
                }
                try? await Task.sleep(for: .seconds(3.0))
            }
        }
    }

    private func stopAngrySteamAnimation() {
        angrySteamTimer?.cancel()
        angrySteamOpacity = 0
    }

    private func stopZzzAnimation() {
        zzzTimer?.cancel()
        zzzOpacity = 0
    }

    // MARK: - Mood animations

    private func applyMoodAnimation(_ mood: MoodState) {
        switch mood {
        case .sleeping:
            withAnimation(.easeInOut(duration: 0.3)) { currentEyeStyle = .sleepy }
            // Override idle bob to much slower
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                bobOffset = 2
            }
            startZzzAnimation()

        case .hungry:
            stopZzzAnimation()
            stopAngrySteamAnimation()
            withAnimation(.easeInOut(duration: 0.2)) { currentEyeStyle = .tiny }
            withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                bobOffset = 0.5
            }

        case .angry:
            stopZzzAnimation()
            withAnimation(.easeInOut(duration: 0.2)) { currentEyeStyle = .wide }
            bobOffset = 0
            startAngrySteamAnimation()

        case .pooping:
            stopZzzAnimation()
            stopAngrySteamAnimation()
            withAnimation(.easeInOut(duration: 0.2)) { currentEyeStyle = .squish }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                showMarquee("oops")
            }

        case .normal:
            stopZzzAnimation()
            stopAngrySteamAnimation()
            withAnimation(.easeInOut(duration: 0.3)) { currentEyeStyle = .normal }
            // Restore normal idle bob
            if state == .idle {
                resetAnimations()
                startAnimations(for: .idle)
            }
        }
    }

    // MARK: - Interactive buttons

    private var buttons: some View {
        HStack(spacing: 14) {
            if state == .permissionNeeded {
                interactiveButton(baseColor: Color(red: 0.7, green: 0.2, blue: 0.2),
                                  glowColor: .red, lit: true, isCenter: false, action: onDeny)
                interactiveButton(baseColor: Color(white: 0.25),
                                  glowColor: .orange, lit: true, isCenter: true, action: {})
                interactiveButton(baseColor: Color(red: 0.15, green: 0.5, blue: 0.2),
                                  glowColor: .green, lit: true, isCenter: false, action: onApprove)
            } else {
                interactiveButton(baseColor: Color(white: 0.25),
                                  glowColor: .shellPinkLight, lit: sessionCount >= 1, isCenter: false, action: onPoke)
                interactiveButton(baseColor: Color(white: 0.25),
                                  glowColor: .shellPinkLight, lit: sessionCount >= 2, isCenter: true, action: onFeed)
                interactiveButton(baseColor: Color(white: 0.25),
                                  glowColor: .shellPinkLight, lit: sessionCount >= 3, isCenter: false, action: onPet)
            }
        }
        .offset(y: eggHeight / 2 - 46)
    }

    private func interactiveButton(
        baseColor: Color, glowColor: Color, lit: Bool, isCenter: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                // Metallic contact pad visible through shell
                Circle()
                    .fill(Color(white: 0.45).opacity(0.3))
                    .frame(width: 22, height: 22)

                // Drop shadow
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 19, height: 19)
                    .offset(y: 2)
                    .blur(radius: 3)

                // Button body
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [baseColor, baseColor.opacity(0.65)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 18, height: 18)

                if lit {
                    Circle()
                        .fill(glowColor.opacity(0.45))
                        .frame(width: 18, height: 18)
                        .blur(radius: 5)
                }

                // Rim stroke
                Circle()
                    .stroke(Color.black.opacity(0.55), lineWidth: 0.5)
                    .frame(width: 18, height: 18)

                // Surface highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(lit ? 0.45 : 0.22), Color.clear],
                            startPoint: .top, endPoint: .center
                        )
                    )
                    .frame(width: 16, height: 16)

                // Center button tactile dot
                if isCenter {
                    Circle()
                        .fill(Color.white.opacity(0.30))
                        .frame(width: 2, height: 2)
                }
            }
        }
        .offset(y: isCenter ? 0 : -6)
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
        permScrollTimer?.cancel()
        permScrollOffset = 0
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
            showMarquee("hey! >_<")
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { bobOffset = -10; currentEyeStyle = .wide }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { bobOffset = 0; currentEyeStyle = .squish }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { currentEyeStyle = .normal }
            }
        case .pet:
            showMarquee("~ happy ~")
            withAnimation(.easeInOut(duration: 0.2)) { currentEyeStyle = .squish }

        case .feed:
            showMarquee("nom nom nom")
            Task { @MainActor in
                for _ in 0..<4 {
                    withAnimation(.easeInOut(duration: 0.1)) { currentEyeStyle = .blink; bobOffset = -3 }
                    try? await Task.sleep(for: .seconds(0.15))
                    withAnimation(.easeInOut(duration: 0.1)) { currentEyeStyle = .squish; bobOffset = 0 }
                    try? await Task.sleep(for: .seconds(0.15))
                }
                withAnimation(.easeInOut(duration: 0.2)) { currentEyeStyle = .normal }
            }
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

// MARK: - Dense realistic internals (circuit board)

struct InternalsView: View {
    let width: CGFloat
    let height: CGFloat

    @State private var ledPulse: Bool = false

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2

            let copperColor = Color(red: 0.45, green: 0.35, blue: 0.18)
            let componentColor = Color(white: 0.13)
            let silkColor = Color(white: 0.55).opacity(0.55)
            let redAccent = Color(red: 0.6, green: 0.12, blue: 0.1)

            // --- Ground plane: cross-hatch diagonal lines ---
            let hatchSpacing: CGFloat = 10
            let diagLen: CGFloat = size.width + size.height
            var d: CGFloat = -diagLen
            while d < diagLen {
                var p1 = Path(); p1.move(to: CGPoint(x: d, y: 0)); p1.addLine(to: CGPoint(x: d + size.height, y: size.height))
                context.stroke(p1, with: .color(copperColor.opacity(0.06)), style: StrokeStyle(lineWidth: 0.4))
                var p2 = Path(); p2.move(to: CGPoint(x: d + size.height, y: 0)); p2.addLine(to: CGPoint(x: d, y: size.height))
                context.stroke(p2, with: .color(copperColor.opacity(0.06)), style: StrokeStyle(lineWidth: 0.4))
                d += hatchSpacing
            }

            // --- Helper to draw right-angle routed trace ---
            func trace(_ pts: [CGPoint], width: CGFloat = 1.0, opacity: CGFloat = 0.55) {
                guard pts.count >= 2 else { return }
                var path = Path()
                path.move(to: pts[0])
                for i in 1..<pts.count { path.addLine(to: pts[i]) }
                context.stroke(path, with: .color(copperColor.opacity(opacity)), style: StrokeStyle(lineWidth: width, lineJoin: .round))
            }

            // --- Signal traces (0.5px) ---
            trace([CGPoint(x: cx-60, y: cy-85), CGPoint(x: cx-60, y: cy-70), CGPoint(x: cx-35, y: cy-70)], width: 0.5)
            trace([CGPoint(x: cx+60, y: cy-85), CGPoint(x: cx+60, y: cy-70), CGPoint(x: cx+35, y: cy-70)], width: 0.5)
            trace([CGPoint(x: cx-20, y: cy-60), CGPoint(x: cx-20, y: cy-45), CGPoint(x: cx-40, y: cy-45)], width: 0.5)
            trace([CGPoint(x: cx+20, y: cy-60), CGPoint(x: cx+20, y: cy-45), CGPoint(x: cx+40, y: cy-45)], width: 0.5)
            trace([CGPoint(x: cx-10, y: cy-60), CGPoint(x: cx-10, y: cy-30)], width: 0.5)
            trace([CGPoint(x: cx+10, y: cy-60), CGPoint(x: cx+10, y: cy-30)], width: 0.5)
            trace([CGPoint(x: cx-55, y: cy-10), CGPoint(x: cx-55, y: cy+10), CGPoint(x: cx-40, y: cy+10)], width: 0.5)
            trace([CGPoint(x: cx+55, y: cy-10), CGPoint(x: cx+55, y: cy+10), CGPoint(x: cx+40, y: cy+10)], width: 0.5)
            trace([CGPoint(x: cx-30, y: cy+20), CGPoint(x: cx-30, y: cy+40), CGPoint(x: cx-50, y: cy+40)], width: 0.5)
            trace([CGPoint(x: cx+30, y: cy+20), CGPoint(x: cx+30, y: cy+40), CGPoint(x: cx+50, y: cy+40)], width: 0.5)
            trace([CGPoint(x: cx-15, y: cy+20), CGPoint(x: cx-15, y: cy+55)], width: 0.5)
            trace([CGPoint(x: cx+15, y: cy+20), CGPoint(x: cx+15, y: cy+55)], width: 0.5)
            trace([CGPoint(x: cx-50, y: cy+55), CGPoint(x: cx-50, y: cy+70), CGPoint(x: cx-30, y: cy+70)], width: 0.5)
            trace([CGPoint(x: cx+50, y: cy+55), CGPoint(x: cx+50, y: cy+70), CGPoint(x: cx+30, y: cy+70)], width: 0.5)
            trace([CGPoint(x: cx-60, y: cy-40), CGPoint(x: cx-60, y: cy-20), CGPoint(x: cx-45, y: cy-20)], width: 0.5)
            trace([CGPoint(x: cx+60, y: cy-40), CGPoint(x: cx+60, y: cy-20), CGPoint(x: cx+45, y: cy-20)], width: 0.5)
            trace([CGPoint(x: cx, y: cy-30), CGPoint(x: cx, y: cy-10), CGPoint(x: cx-25, y: cy-10)], width: 0.5)
            trace([CGPoint(x: cx, y: cy+20), CGPoint(x: cx, y: cy+40)], width: 0.5)

            // --- Power traces (1.5px) ---
            trace([CGPoint(x: cx-70, y: cy+30), CGPoint(x: cx+70, y: cy+30)], width: 1.5, opacity: 0.45)
            trace([CGPoint(x: cx-70, y: cy+30), CGPoint(x: cx-70, y: cy+85)], width: 1.5, opacity: 0.45)
            trace([CGPoint(x: cx+70, y: cy+30), CGPoint(x: cx+70, y: cy+75)], width: 1.5, opacity: 0.45)

            // --- Ground bus (2.5px) ---
            trace([CGPoint(x: cx-75, y: cy+55), CGPoint(x: cx+75, y: cy+55)], width: 2.5, opacity: 0.35)
            trace([CGPoint(x: cx, y: cy+55), CGPoint(x: cx, y: cy+95)], width: 2.5, opacity: 0.35)

            // --- Main QFP IC chip (U1) with pins on all 4 sides ---
            let chipW: CGFloat = 36
            let chipH: CGFloat = 36
            let chipX = cx - chipW / 2
            let chipY = cy - chipH / 2 - 20
            let chipRect = CGRect(x: chipX, y: chipY, width: chipW, height: chipH)
            context.fill(Path(chipRect), with: .color(componentColor))
            context.stroke(Path(chipRect), with: .color(copperColor.opacity(0.35)), style: StrokeStyle(lineWidth: 0.75))
            // Pin 1 marker dot
            let pin1dot = Path(ellipseIn: CGRect(x: chipX + 2, y: chipY + 2, width: 3, height: 3))
            context.fill(pin1dot, with: .color(copperColor.opacity(0.5)))
            // Top pins (6)
            for i in 0..<6 {
                let px = chipX + 3 + CGFloat(i) * (chipW - 6) / 5
                let pinTop = CGRect(x: px - 1, y: chipY - 4, width: 2, height: 4)
                context.fill(Path(pinTop), with: .color(copperColor.opacity(0.65)))
            }
            // Bottom pins (6)
            for i in 0..<6 {
                let px = chipX + 3 + CGFloat(i) * (chipW - 6) / 5
                let pinBot = CGRect(x: px - 1, y: chipY + chipH, width: 2, height: 4)
                context.fill(Path(pinBot), with: .color(copperColor.opacity(0.65)))
            }
            // Left pins (6)
            for i in 0..<6 {
                let py = chipY + 3 + CGFloat(i) * (chipH - 6) / 5
                let pinLeft = CGRect(x: chipX - 4, y: py - 1, width: 4, height: 2)
                context.fill(Path(pinLeft), with: .color(copperColor.opacity(0.65)))
            }
            // Right pins (6)
            for i in 0..<6 {
                let py = chipY + 3 + CGFloat(i) * (chipH - 6) / 5
                let pinRight = CGRect(x: chipX + chipW, y: py - 1, width: 4, height: 2)
                context.fill(Path(pinRight), with: .color(copperColor.opacity(0.65)))
            }
            // U1 label
            context.draw(
                Text("U1").font(.system(size: 5, weight: .bold, design: .monospaced)).foregroundStyle(silkColor),
                at: CGPoint(x: cx, y: chipY + chipH / 2)
            )
            context.draw(
                Text("CLWD").font(.system(size: 3.5, design: .monospaced)).foregroundStyle(silkColor.opacity(0.7)),
                at: CGPoint(x: cx, y: chipY + chipH / 2 + 7)
            )

            // --- Secondary chip (U2) ---
            let chip2Rect = CGRect(x: cx + 42, y: cy - 50, width: 18, height: 14)
            context.fill(Path(chip2Rect), with: .color(componentColor))
            context.stroke(Path(chip2Rect), with: .color(copperColor.opacity(0.30)), style: StrokeStyle(lineWidth: 0.5))
            for i in 0..<3 {
                let px = chip2Rect.minX + 3 + CGFloat(i) * 6
                context.fill(Path(CGRect(x: px, y: chip2Rect.minY - 2.5, width: 1.5, height: 2.5)), with: .color(copperColor.opacity(0.55)))
                context.fill(Path(CGRect(x: px, y: chip2Rect.maxY, width: 1.5, height: 2.5)), with: .color(copperColor.opacity(0.55)))
            }
            context.draw(
                Text("U2").font(.system(size: 4, design: .monospaced)).foregroundStyle(silkColor),
                at: CGPoint(x: chip2Rect.midX, y: chip2Rect.midY)
            )

            // --- Crystal oscillator (Y1) ---
            let xtalRect = CGRect(x: cx - 75, y: cy - 60, width: 10, height: 6)
            context.fill(Path(xtalRect), with: .color(Color(white: 0.28)))
            context.stroke(Path(xtalRect), with: .color(copperColor.opacity(0.4)), style: StrokeStyle(lineWidth: 0.5))
            context.fill(Path(CGRect(x: xtalRect.minX - 2, y: xtalRect.midY - 0.75, width: 2, height: 1.5)), with: .color(copperColor.opacity(0.6)))
            context.fill(Path(CGRect(x: xtalRect.maxX, y: xtalRect.midY - 0.75, width: 2, height: 1.5)), with: .color(copperColor.opacity(0.6)))
            context.draw(
                Text("Y1").font(.system(size: 3.5, design: .monospaced)).foregroundStyle(silkColor),
                at: CGPoint(x: xtalRect.midX, y: xtalRect.minY - 4)
            )

            // --- Electrolytic capacitor (C1) ---
            let capCX: CGFloat = cx - 70
            let capCY: CGFloat = cy + 10
            let capCircle = Path(ellipseIn: CGRect(x: capCX - 5, y: capCY - 5, width: 10, height: 10))
            context.fill(capCircle, with: .color(Color(white: 0.22)))
            context.stroke(capCircle, with: .color(copperColor.opacity(0.35)), style: StrokeStyle(lineWidth: 0.5))
            let capLeadRect = CGRect(x: capCX - 2, y: capCY + 5, width: 4, height: 5)
            context.fill(Path(capLeadRect), with: .color(componentColor))
            context.fill(Path(CGRect(x: capCX - 0.5, y: capCY - 3.5, width: 1, height: 7)), with: .color(copperColor.opacity(0.4)))
            context.draw(
                Text("C1").font(.system(size: 3.5, design: .monospaced)).foregroundStyle(silkColor),
                at: CGPoint(x: capCX, y: capCY - 9)
            )

            // --- 12 SMD components (R1-R8, C2-C4, plus extra) ---
            let smds: [(CGRect, String)] = [
                (CGRect(x: cx - 55, y: cy - 45, width: 7, height: 3), "R1"),
                (CGRect(x: cx - 42, y: cy - 45, width: 7, height: 3), "R2"),
                (CGRect(x: cx + 32, y: cy - 45, width: 7, height: 3), "R3"),
                (CGRect(x: cx + 44, y: cy - 45, width: 7, height: 3), "R4"),
                (CGRect(x: cx - 58, y: cy + 42, width: 3, height: 7), "R5"),
                (CGRect(x: cx + 53, y: cy + 42, width: 3, height: 7), "R6"),
                (CGRect(x: cx - 22, y: cy + 60, width: 7, height: 3), "R7"),
                (CGRect(x: cx + 14, y: cy + 60, width: 7, height: 3), "R8"),
                (CGRect(x: cx - 58, y: cy - 25, width: 7, height: 3), "C2"),
                (CGRect(x: cx + 50, y: cy - 25, width: 7, height: 3), "C3"),
                (CGRect(x: cx - 30, y: cy - 80, width: 7, height: 3), "C4"),
                (CGRect(x: cx + 22, y: cy - 80, width: 7, height: 3), ""),
            ]
            for (smd, label) in smds {
                context.fill(Path(smd), with: .color(componentColor))
                context.stroke(Path(smd), with: .color(copperColor.opacity(0.40)), style: StrokeStyle(lineWidth: 0.4))
                // Solder pads at ends
                let padW: CGFloat = 2
                if smd.width > smd.height {
                    context.fill(Path(CGRect(x: smd.minX - padW, y: smd.midY - 1, width: padW, height: 2)), with: .color(copperColor.opacity(0.6)))
                    context.fill(Path(CGRect(x: smd.maxX, y: smd.midY - 1, width: padW, height: 2)), with: .color(copperColor.opacity(0.6)))
                } else {
                    context.fill(Path(CGRect(x: smd.midX - 1, y: smd.minY - padW, width: 2, height: padW)), with: .color(copperColor.opacity(0.6)))
                    context.fill(Path(CGRect(x: smd.midX - 1, y: smd.maxY, width: 2, height: padW)), with: .color(copperColor.opacity(0.6)))
                }
                if !label.isEmpty {
                    context.draw(
                        Text(label).font(.system(size: 3, design: .monospaced)).foregroundStyle(silkColor.opacity(0.7)),
                        at: CGPoint(x: smd.midX, y: smd.minY - 4)
                    )
                }
            }

            // --- Via holes (10+) ---
            let vias: [CGPoint] = [
                CGPoint(x: cx - 40, y: cy - 20),
                CGPoint(x: cx + 40, y: cy - 20),
                CGPoint(x: cx - 20, y: cy + 40),
                CGPoint(x: cx + 20, y: cy + 40),
                CGPoint(x: cx, y: cy + 55),
                CGPoint(x: cx - 60, y: cy - 40),
                CGPoint(x: cx + 60, y: cy - 40),
                CGPoint(x: cx - 30, y: cy - 70),
                CGPoint(x: cx + 30, y: cy - 70),
                CGPoint(x: cx - 55, y: cy + 15),
                CGPoint(x: cx + 55, y: cy + 15),
                CGPoint(x: cx, y: cy - 10),
            ]
            for via in vias {
                let ring = Path(ellipseIn: CGRect(x: via.x - 3, y: via.y - 3, width: 6, height: 6))
                context.fill(ring, with: .color(copperColor.opacity(0.55)))
                let hole = Path(ellipseIn: CGRect(x: via.x - 1.2, y: via.y - 1.2, width: 2.4, height: 2.4))
                context.fill(hole, with: .color(Color(white: 0.04)))
            }

            // --- Flex cable (ribbon of parallel lines from main chip toward screen) ---
            let flexY = chipY - 4
            let flexEndY = cy - 95
            for i in 0..<5 {
                let lx = cx - 8 + CGFloat(i) * 4
                var flex = Path()
                flex.move(to: CGPoint(x: lx, y: flexY))
                flex.addLine(to: CGPoint(x: lx, y: flexEndY))
                context.stroke(flex, with: .color(copperColor.opacity(0.30)), style: StrokeStyle(lineWidth: 0.5))
            }

            // --- Silkscreen text labels ---
            let labels: [(String, CGPoint)] = [
                ("v2.0", CGPoint(x: cx + 55, y: cy + 88)),
                ("GND",  CGPoint(x: cx - 25, y: cy + 60)),
                ("VCC",  CGPoint(x: cx + 25, y: cy + 60)),
                ("3V3",  CGPoint(x: cx - 68, y: cy + 35)),
                ("CLWD", CGPoint(x: cx - 72, y: cy - 68)),
            ]
            for (txt, pt) in labels {
                context.draw(
                    Text(txt).font(.system(size: 3.5, design: .monospaced)).foregroundStyle(silkColor.opacity(0.65)),
                    at: pt
                )
            }

            // --- Battery outline ---
            let batRect = CGRect(x: cx - 28, y: cy + 72, width: 56, height: 22)
            context.stroke(Path(batRect), with: .color(copperColor.opacity(0.30)), style: StrokeStyle(lineWidth: 0.75))
            // Battery positive nub
            let batNub = CGRect(x: batRect.maxX, y: batRect.midY - 4, width: 3, height: 8)
            context.fill(Path(batNub), with: .color(componentColor))
            context.stroke(Path(batNub), with: .color(copperColor.opacity(0.3)), style: StrokeStyle(lineWidth: 0.5))
            context.draw(
                Text("+").font(.system(size: 5, weight: .bold, design: .monospaced)).foregroundStyle(silkColor),
                at: CGPoint(x: batRect.minX + 7, y: batRect.midY)
            )
            context.draw(
                Text("−").font(.system(size: 5, weight: .bold, design: .monospaced)).foregroundStyle(silkColor),
                at: CGPoint(x: batRect.maxX - 7, y: batRect.midY)
            )

            // --- Test pads (TP1-TP4) ---
            let tpads: [(CGRect, String)] = [
                (CGRect(x: cx - 80, y: cy + 65, width: 5, height: 5), "TP1"),
                (CGRect(x: cx - 80, y: cy + 75, width: 5, height: 5), "TP2"),
                (CGRect(x: cx + 74, y: cy + 45, width: 5, height: 5), "TP3"),
                (CGRect(x: cx + 74, y: cy + 55, width: 5, height: 5), "TP4"),
            ]
            for (r, label) in tpads {
                context.fill(Path(r), with: .color(copperColor.opacity(0.45)))
                context.stroke(Path(r), with: .color(copperColor.opacity(0.20)), style: StrokeStyle(lineWidth: 0.3))
                context.draw(
                    Text(label).font(.system(size: 3, design: .monospaced)).foregroundStyle(silkColor.opacity(0.6)),
                    at: CGPoint(x: r.midX, y: r.minY - 4)
                )
            }

            // --- Antenna meandering trace (top-left corner) ---
            let antStartX: CGFloat = cx - 82
            let antStartY: CGFloat = cy - 85
            var ant = Path()
            ant.move(to: CGPoint(x: antStartX, y: antStartY))
            ant.addLine(to: CGPoint(x: antStartX + 14, y: antStartY))
            ant.addLine(to: CGPoint(x: antStartX + 14, y: antStartY + 8))
            ant.addLine(to: CGPoint(x: antStartX + 2, y: antStartY + 8))
            ant.addLine(to: CGPoint(x: antStartX + 2, y: antStartY + 16))
            ant.addLine(to: CGPoint(x: antStartX + 14, y: antStartY + 16))
            ant.addLine(to: CGPoint(x: antStartX + 14, y: antStartY + 24))
            ant.addLine(to: CGPoint(x: antStartX, y: antStartY + 24))
            context.stroke(ant, with: .color(copperColor.opacity(0.40)), style: StrokeStyle(lineWidth: 0.75, lineJoin: .round))

            // --- Red LED (with static glow, animated separately) ---
            let ledRect = CGRect(x: cx + 38, y: cy + 78, width: 6, height: 6)
            context.fill(Path(ledRect), with: .color(redAccent.opacity(0.85)))
            context.stroke(Path(ledRect), with: .color(redAccent.opacity(0.4)), style: StrokeStyle(lineWidth: 0.5))
            let ledGlow = Path(ellipseIn: ledRect.insetBy(dx: -5, dy: -5))
            context.fill(ledGlow, with: .color(redAccent.opacity(0.12)))

            // --- Wireless coil (bottom area) ---
            let coilCenter = CGPoint(x: cx, y: cy + 98)
            for i in 0..<3 {
                let r = 10 + CGFloat(i) * 5
                let coilPath = Path(ellipseIn: CGRect(x: coilCenter.x - r, y: coilCenter.y - r * 0.5, width: r * 2, height: r))
                context.stroke(coilPath, with: .color(copperColor.opacity(0.22)), style: StrokeStyle(lineWidth: 0.7))
            }
        }
        .frame(width: width, height: height)
        .overlay(
            // Animated LED glow overlay
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.6, green: 0.12, blue: 0.1).opacity(ledPulse ? 0.25 : 0.08))
                .frame(width: 16, height: 16)
                .blur(radius: 6)
                .offset(x: width / 2 - width / 2 + 38 + 3, y: height / 2 - height / 2 + 78 + 3)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                ledPulse = true
            }
        }
    }
}

// MARK: - Pixel grid overlay

// MARK: - 8-bit pixel poop

struct PixelPoop: View {
    // Ice cream swirl shape, flat bottom
    private let grid: [[Int]] = [
        [0,0,0,1,0,0,0],
        [0,0,1,1,1,0,0],
        [0,0,0,1,1,0,0],
        [0,0,1,1,0,0,0],
        [0,1,1,1,1,1,0],
        [0,1,1,1,1,1,0],
        [1,1,1,1,1,1,1],
        [1,1,1,1,1,1,1],
    ]

    var body: some View {
        Canvas { context, size in
            let px: CGFloat = 1.5
            let cols = grid[0].count
            let rows = grid.count
            let ox = (size.width - CGFloat(cols) * px) / 2
            let oy = size.height - CGFloat(rows) * px
            let brown = Color(red: 0.45, green: 0.30, blue: 0.18)
            for r in 0..<rows {
                for c in 0..<cols {
                    if grid[r][c] == 1 {
                        let rect = CGRect(x: ox + CGFloat(c) * px, y: oy + CGFloat(r) * px, width: px, height: px)
                        context.fill(Path(rect), with: .color(brown))
                    }
                }
            }
            // Wavy steam lines
            let steamX = ox + CGFloat(cols) * px / 2
            let steamBase = oy - 1
            for i in 0..<2 {
                let sx = steamX + CGFloat(i) * 3 - 1.5
                var steam = Path()
                steam.move(to: CGPoint(x: sx, y: steamBase))
                steam.addQuadCurve(to: CGPoint(x: sx, y: steamBase - 5),
                                   control: CGPoint(x: sx + 2, y: steamBase - 2.5))
                context.stroke(steam, with: .color(Color(white: 0.35)), style: StrokeStyle(lineWidth: 0.5))
            }
        }
        .frame(width: 14, height: 16)
    }
}

// MARK: - 8-bit anger symbol (cross/spark)

struct PixelAnger: View {
    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let color = Color(white: 0.5)
            let px: CGFloat = 1.5

            // X shape (anger cross)
            var d1 = Path()
            d1.move(to: CGPoint(x: cx - 3, y: cy - 3))
            d1.addLine(to: CGPoint(x: cx + 3, y: cy + 3))
            context.stroke(d1, with: .color(color), style: StrokeStyle(lineWidth: px))

            var d2 = Path()
            d2.move(to: CGPoint(x: cx + 3, y: cy - 3))
            d2.addLine(to: CGPoint(x: cx - 3, y: cy + 3))
            context.stroke(d2, with: .color(color), style: StrokeStyle(lineWidth: px))

            // Small dots at the tips
            for (dx, dy) in [(-4.0, -4.0), (4.0, -4.0), (-4.0, 4.0), (4.0, 4.0)] {
                let dot = CGRect(x: cx + dx - 0.5, y: cy + dy - 0.5, width: 1, height: 1)
                context.fill(Path(dot), with: .color(color))
            }
        }
        .frame(width: 14, height: 14)
    }
}

// MARK: - Pixel stat bar

struct PixelStatBar: View {
    let value: Double
    let label: String
    private let segments = 4
    private let barColor = Color.white.opacity(0.25)
    private let emptyColor = Color.white.opacity(0.06)

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.system(size: 5, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.2))
            HStack(spacing: 1) {
                ForEach(0..<segments, id: \.self) { i in
                    let filled = value > Double(i) / Double(segments)
                    Rectangle()
                        .fill(filled ? barColor : emptyColor)
                        .frame(width: 5, height: 3)
                }
            }
        }
    }
}

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
