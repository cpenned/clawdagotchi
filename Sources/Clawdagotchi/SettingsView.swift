import SwiftUI

struct SettingsView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        TabView {
            appearanceTab
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            levelTab
                .tabItem { Label("Level Up", systemImage: "star.fill") }
            statsTab
                .tabItem { Label("Stats", systemImage: "chart.bar") }
            soundTab
                .tabItem { Label("Sound", systemImage: "speaker.wave.2") }
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 360, height: 500)
        .padding(.top, 8)
    }

    // MARK: - Appearance

    private var appearanceTab: some View {
        Form {
            Section("Pet Name") {
                TextField("Name", text: $settings.botName)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Character Color") {
                Picker("", selection: $settings.useCustomCrabColor) {
                    HStack(spacing: 6) {
                        Circle().fill(Color(red: 0xD9 / 255.0, green: 0x77 / 255.0, blue: 0x57 / 255.0)).frame(width: 10, height: 10)
                        Text("Always salmon")
                    }.tag(false)
                    HStack(spacing: 6) {
                        Circle().fill(settings.shellStyle.crabColor).frame(width: 10, height: 10)
                        Text("Match theme")
                    }.tag(true)
                }
                .pickerStyle(.radioGroup)
            }

            Section("Shell Style") {
                Picker("Style", selection: $settings.shellStyle) {
                    ForEach(ShellStyle.allCases, id: \.rawValue) { style in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(style.tintColor)
                                .frame(width: 12, height: 12)
                            Text(style.displayName)
                        }
                        .tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Size") {
                HStack {
                    Image(systemName: "minus.magnifyingglass")
                        .foregroundStyle(.secondary)
                    Slider(value: $settings.widgetScale, in: 0.5...1.5, step: 0.1)
                    Image(systemName: "plus.magnifyingglass")
                        .foregroundStyle(.secondary)
                }
                Text("\(Int(settings.widgetScale * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Section("Screen Background") {
                Picker("Theme", selection: $settings.backgroundTheme) {
                    ForEach(BackgroundTheme.allCases, id: \.rawValue) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Seasonal") {
                Toggle("Seasonal accessories", isOn: $settings.seasonalAccessories)
                if let seasonal = CrabAccessory.seasonalAccessory() {
                    Text("Active now: \(seasonal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No seasonal event right now")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Picker("Preview", selection: $previewSeasonal) {
                    Text("None").tag(Optional<CrabAccessory>.none)
                    Text("Santa Hat (Dec)").tag(Optional<CrabAccessory>.some(.santaHat))
                    Text("Pumpkin (Oct)").tag(Optional<CrabAccessory>.some(.pumpkin))
                    Text("Bunny Ears (Apr)").tag(Optional<CrabAccessory>.some(.bunnyEars))
                    Text("Heart (Feb)").tag(Optional<CrabAccessory>.some(.heartBow))
                    Text("Confetti (Jan 1)").tag(Optional<CrabAccessory>.some(.partyPopper))
                }
                .pickerStyle(.menu)

                if previewSeasonal != nil {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.screenDark)
                            .frame(height: 80)
                        CrabView(
                            size: 40,
                            color: AppSettings.shared.activeCrabColor,
                            eyeColor: Color.screenDark,
                            eyeStyle: .normal,
                            accessories: seasonalPreviewAccessories,
                            accessoryColor: .white
                        )
                    }
                }
            }

            Section("Float on Top") {
                Picker("Keep on top", selection: $settings.floatPolicy) {
                    ForEach(FloatPolicy.allCases, id: \.rawValue) { policy in
                        Text(policy.displayName).tag(policy)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Visibility") {
                Toggle("Show in Dock", isOn: $settings.showDockIcon)
                Toggle("Show floating widget", isOn: $settings.showWidget)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Level Up

    @State private var previewLevel: Double = Double(AppSettings.shared.level)
    @State private var showingResetConfirm: Bool = false
    @State private var previewSeasonal: CrabAccessory? = nil

    private var seasonalPreviewAccessories: [CrabAccessory] {
        var items = CrabAccessory.allUnlocked(for: AppSettings.shared.level, seasonalEnabled: false)
        if let seasonal = previewSeasonal {
            // Replace head slot with seasonal
            items.removeAll { [.partyHat, .topHat, .crown].contains($0) }
            items.append(seasonal)
        }
        return items
    }

    private var levelTab: some View {
        Form {
            Section("Preview Levels") {
                VStack(spacing: 12) {
                    // Crab preview
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.screenDark)
                            .frame(height: 100)

                        CrabView(
                            size: 50,
                            color: AppSettings.shared.activeCrabColor,
                            eyeColor: Color.screenDark,
                            eyeStyle: .normal,
                            accessories: CrabAccessory.allUnlocked(for: Int(previewLevel)),
                            accessoryColor: .white
                        )
                    }

                    // Level slider
                    HStack {
                        Text("LV 1")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Slider(value: $previewLevel, in: 1...8, step: 1)
                        Text("LV 8")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Level info
                    let lvl = Int(previewLevel)
                    let acc = CrabAccessory.forLevel(lvl)
                    let threshold = lvl <= TamagotchiViewModel.levelThresholds.count
                        ? (lvl > 1 ? TamagotchiViewModel.levelThresholds[lvl - 1] : 0)
                        : TamagotchiViewModel.levelThresholds.last!
                    let unlocked = lvl <= AppSettings.shared.level

                    VStack(spacing: 4) {
                        Text("Level \(lvl)")
                            .font(.headline)

                        if acc != .none {
                            Text("Unlocks: \(acc)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text("Requires: \(threshold) XP")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if unlocked {
                            Text("Unlocked!")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            let remaining = threshold - AppSettings.shared.xp
                            Text("\(remaining) XP to go")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Current Progress") {
                HStack {
                    Text("Level")
                    Spacer()
                    Text("\(AppSettings.shared.level)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total XP")
                    Spacer()
                    Text("\(AppSettings.shared.xp)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Next level")
                    Spacer()
                    Text(nextThresholdText + " XP")
                        .foregroundStyle(.secondary)
                }
                Button("Reset Progress", role: .destructive) {
                    showingResetConfirm = true
                }
                .alert("Reset Progress?", isPresented: $showingResetConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) {
                        TamagotchiViewModel.shared?.resetProgress()
                        previewLevel = 1
                    }
                } message: {
                    Text("This will reset your level to 1 and XP to 0. This cannot be undone.")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Stats

    private var statsTab: some View {
        Form {
            Section("Streak") {
                HStack {
                    Text("Current streak")
                    Spacer()
                    Text("\(AppSettings.shared.streak) days")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Last login")
                    Spacer()
                    Text(AppSettings.shared.lastLoginDate.isEmpty ? "Never" : AppSettings.shared.lastLoginDate)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Claude Code") {
                statRow("Sessions completed", AppSettings.shared.totalSessions)
                statRow("Tools used", AppSettings.shared.totalToolUses)
                statRow("Permissions approved", AppSettings.shared.totalPermissionsApproved)
                statRow("Permissions denied", AppSettings.shared.totalPermissionsDenied)
            }

            Section("Pet Care") {
                statRow("Pokes", AppSettings.shared.totalPokes)
                statRow("Feeds", AppSettings.shared.totalFeeds)
                statRow("Pets", AppSettings.shared.totalPets)
                statRow("Poops cleaned", AppSettings.shared.totalPoopsCleaned)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func statRow(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Sound

    private var soundTab: some View {
        Form {
            Section("Sound Effects") {
                Toggle("Enable sounds", isOn: $settings.soundEnabled)
                if settings.soundEnabled {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(.secondary)
                        Slider(value: $settings.soundVolume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if settings.soundEnabled {
                Section("Sounds per action") {
                    ForEach(SoundAction.allCases, id: \.rawValue) { action in
                        SoundPickerRow(action: action)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Help

    private var nextThresholdText: String {
        let thresholds = TamagotchiViewModel.levelThresholds
        let level = AppSettings.shared.level
        if level >= thresholds.count { return "MAX" }
        return "\(thresholds[level])"
    }

    private var aboutTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                aboutSection("What is Clawdagotchi?",
                    "A floating desktop pet that lives on your screen and reacts to your Claude Code sessions. " +
                    "It tracks tool usage, permissions, and session activity through Claude Code hooks. " +
                    "Take care of it — feed it, pet it, and clean up after it!"
                )

                aboutSection("Your Crab", """
Level \(AppSettings.shared.level) — \(CrabAccessory.forLevel(AppSettings.shared.level)) unlocked
XP: \(AppSettings.shared.xp) / \(nextThresholdText)
""")

                aboutSection("Session Tracking", """
                Idle — gentle bob, periodic blink
                Thinking — eyes look side to side (PreToolUse)
                Working — wide eyes, walking legs (PostToolUse)
                Done — happy squish eyes, bounce (Stop)
                Permission — alert eyes, approve/deny buttons
                Buttons glow to show active session count (up to 3).
                """)

                aboutSection("Pet Care", """
                Feed (middle button) — restores hunger bar
                Pet (right button) — restores happiness, cleans poop
                Poke (left button) — restores happiness, wakes up
                Hunger and happiness drain over time.
                Poops accumulate every ~15 min — pet to clean!
                """)

                aboutSection("Moods", """
                Sleeping — eyes close, zzz (after 2 min idle)
                Hungry — small eyes, trembles (hunger bar low)
                Angry — wide glare (happiness empty)
                Pooping — squish face, leaves a mess
                """)

                aboutSection("Permissions", """
                When Claude Code needs approval, the screen shows the project name and tool details.
                Left button (red) = Deny
                Right button (green) = Allow
                Permissions auto-clear after 30s if handled in terminal.
                """)

                aboutSection("Setup", """
                1. Run: bash install_hooks.sh
                2. Launch the app
                3. Use Claude Code — the crab reacts!
                """)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Preview Moods")
                        .font(.headline)
                    HStack(spacing: 8) {
                        moodPreviewButton("Sleep", .sleeping)
                        moodPreviewButton("Hungry", .hungry)
                        moodPreviewButton("Angry", .angry)
                        moodPreviewButton("Poop", .pooping)
                    }
                    Text("Triggers the mood on the live widget for 4 seconds.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                aboutSection("Your Crab", """
Born: \(AppSettings.shared.birthDateFormatted)
Age: \(AppSettings.shared.ageInDays) days
""")

                Button("Export Screenshot...") {
                    ScreenshotExporter.export()
                }

                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Button("Check for Updates...") {
                            UpdateChecker.shared.checkNow()
                        }
                        Button("⭐ Star on GitHub") {
                            if let url = URL(string: "https://github.com/cpenned/clawdagotchi") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }

                    Text("Clawdagotchi v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("An independent fan project. Not affiliated with, sponsored by, or endorsed by Anthropic.")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }

    private func moodPreviewButton(_ label: String, _ mood: MoodState) -> some View {
        Button(label) {
            TamagotchiViewModel.shared?.previewMood(mood)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func aboutSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct SoundPickerRow: View {
    let action: SoundAction
    @State private var selected: String

    init(action: SoundAction) {
        self.action = action
        self._selected = State(initialValue: SoundManager.shared.soundName(for: action))
    }

    var body: some View {
        HStack {
            Text(action.label)
            Spacer()
            Picker("", selection: $selected) {
                ForEach(SoundManager.availableSounds, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .frame(width: 120)
            .onChange(of: selected) { _, newValue in
                SoundManager.shared.setSoundName(newValue, for: action)
                SoundManager.shared.preview(newValue)
            }
        }
    }
}
