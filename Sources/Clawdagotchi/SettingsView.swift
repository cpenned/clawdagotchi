import SwiftUI

struct SettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var selectedTab: SettingsTab = .appearance
    @State private var hooksInstalled: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Color(white: 0.11).frame(width: 1)
            tabContent
        }
        .frame(width: 580, height: 520)
        .background(Color.screenDark)
        .preferredColorScheme(.dark)
    }

    private var xpFraction: CGFloat {
        let thresholds = TamagotchiViewModel.levelThresholds
        let level = settings.level
        guard level < thresholds.count else { return 1.0 }
        let target = CGFloat(thresholds[level])
        return target > 0 ? min(CGFloat(settings.xp) / target, 1.0) : 1.0
    }

    private var sidebar: some View {
        VStack(alignment: .center, spacing: 0) {
            // Crab
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.118))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color(white: 0.165), lineWidth: 1)
                    )
                    .frame(width: 80, height: 76)
                CrabView(
                    size: 60,
                    color: settings.activeCrabColor,
                    eyeColor: Color.screenDark,
                    eyeStyle: .normal,
                    accessories: CrabAccessory.allUnlocked(
                        for: settings.level,
                        seasonalEnabled: settings.seasonalAccessories
                    ),
                    accessoryColor: .white
                )
            }
            .padding(.bottom, 12)

            // Bot name
            Text(settings.botName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.salmon)
                .padding(.bottom, 2)

            // Level
            Text("Level \(settings.level)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color(white: 0.4))
                .padding(.bottom, 6)

            // XP bar
            ZStack(alignment: .leading) {
                Capsule().fill(Color(white: 0.145)).frame(width: 100, height: 3)
                Capsule().fill(Color.salmon).frame(width: 100 * xpFraction, height: 3)
            }
            .padding(.bottom, 3)

            Text("\(settings.xp) / \(nextThresholdText) XP")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color(white: 0.27))
                .padding(.bottom, 14)

            // Streak
            if settings.streak > 0 {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 10))
                    Text("\(settings.streak) day streak")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(white: 0.53))
                }
                .padding(.bottom, 20)
            } else {
                Spacer().frame(height: 20)
            }

            // Tab buttons
            VStack(spacing: 2) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 9, weight: selectedTab == tab ? .semibold : .regular, design: .monospaced))
                            .foregroundStyle(selectedTab == tab ? Color.white : Color(white: 0.4))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(selectedTab == tab ? Color.salmon : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            // Bottom links
            VStack(spacing: 6) {
                Button {
                    ScreenshotExporter.export()
                } label: {
                    Text("Screenshot")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(white: 0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(Color(white: 0.145))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    UpdateChecker.shared.checkNow()
                } label: {
                    Text("Check for Updates")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(white: 0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(Color(white: 0.145))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    if let url = URL(string: "https://github.com/cpenned/clawdagotchi") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("⭐ Star on GitHub")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.salmon)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(Color.salmon.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 14)
        }
        .padding(.top, 20)
        .frame(width: 160)
        .frame(maxHeight: .infinity)
        .background(Color(white: 0.086))
    }

    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .appearance: appearanceTab
            case .levelUp: levelTab
            case .stats: statsTab
            case .badges: achievementsTab
            case .sound: soundTab
            case .about: aboutTab
            }
        }
    }

    // MARK: - Appearance

    private var appearanceTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                settingsSection("Pet Name") {
                    TextField("Name", text: $settings.botName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }

                settingsSection("Character Color") {
                    Button {
                        settings.useCustomCrabColor = false
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.salmon)
                                .frame(width: 8, height: 8)
                            Text("Always salmon")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white)
                            Spacer()
                            if !settings.useCustomCrabColor {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.salmon)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Color(white: 0.12).frame(height: 1)

                    Button {
                        settings.useCustomCrabColor = true
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(settings.shellStyle.crabColor)
                                .frame(width: 8, height: 8)
                            Text("Match theme")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white)
                            Spacer()
                            if settings.useCustomCrabColor {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.salmon)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                settingsSection("Shell Style") {
                    ForEach(Array(ShellStyle.allCases.enumerated()), id: \.element.rawValue) { index, style in
                        if index > 0 { Color(white: 0.12).frame(height: 1) }
                        Button {
                            settings.shellStyle = style
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(style.tintColor)
                                    .frame(width: 8, height: 8)
                                Text(style.displayName)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white)
                                Spacer()
                                if settings.shellStyle == style {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.salmon)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                settingsSection("Size") {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "minus.magnifyingglass")
                                .foregroundStyle(Color(white: 0.5))
                            Slider(value: $settings.widgetScale, in: 0.5...1.5, step: 0.1)
                                .tint(Color.salmon)
                            Image(systemName: "plus.magnifyingglass")
                                .foregroundStyle(Color(white: 0.5))
                        }
                        Text("\(Int(settings.widgetScale * 100))%")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.salmon)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }

                settingsSection("Screen Background") {
                    ForEach(Array(BackgroundTheme.allCases.enumerated()), id: \.element.rawValue) { index, theme in
                        if index > 0 { Color(white: 0.12).frame(height: 1) }
                        Button {
                            settings.backgroundTheme = theme
                        } label: {
                            HStack {
                                Text(theme.displayName)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white)
                                Spacer()
                                if settings.backgroundTheme == theme {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.salmon)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                settingsSection("Seasonal") {
                    VStack(alignment: .leading, spacing: 0) {
                        Toggle("Seasonal accessories", isOn: $settings.seasonalAccessories)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white)
                            .tint(Color.salmon)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)

                        Color(white: 0.12).frame(height: 1)

                        if let seasonal = CrabAccessory.seasonalAccessory() {
                            Text("Active now: \(String(describing: seasonal))")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color(white: 0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        } else {
                            Text("No seasonal event right now")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color(white: 0.33))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }

                        Color(white: 0.12).frame(height: 1)

                        Picker("Preview", selection: $previewSeasonal) {
                            Text("None").tag(Optional<CrabAccessory>.none)
                            Text("Santa Hat (Dec)").tag(Optional<CrabAccessory>.some(.santaHat))
                            Text("Pumpkin (Oct)").tag(Optional<CrabAccessory>.some(.pumpkin))
                            Text("Bunny Ears (Apr)").tag(Optional<CrabAccessory>.some(.bunnyEars))
                            Text("Heart (Feb)").tag(Optional<CrabAccessory>.some(.heartBow))
                            Text("Confetti (Jan 1)").tag(Optional<CrabAccessory>.some(.partyPopper))
                        }
                        .pickerStyle(.menu)
                        .font(.system(size: 11))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                        if previewSeasonal != nil {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
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
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                        }
                    }
                }

                settingsSection("Lifecycle") {
                    VStack(alignment: .leading, spacing: 0) {
                        Toggle("Weekend protection", isOn: $settings.weekendProtection)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white)
                            .tint(Color.salmon)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)

                        Color(white: 0.12).frame(height: 1)

                        Text("When on, the death clock pauses on Saturdays and Sundays (local time).")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color(white: 0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                }

                settingsSection("Float on Top") {
                    ForEach(Array(FloatPolicy.allCases.enumerated()), id: \.element.rawValue) { index, policy in
                        if index > 0 { Color(white: 0.12).frame(height: 1) }
                        Button {
                            settings.floatPolicy = policy
                        } label: {
                            HStack {
                                Text(policy.displayName)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white)
                                Spacer()
                                if settings.floatPolicy == policy {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.salmon)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                settingsSection("Visibility") {
                    Toggle("Show in Dock", isOn: $settings.showDockIcon)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white)
                        .tint(Color.salmon)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                    Color(white: 0.12).frame(height: 1)

                    Toggle("Show floating widget", isOn: $settings.showWidget)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white)
                        .tint(Color.salmon)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
            .padding(12)
        }
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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                settingsSection("Preview Levels") {
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
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

                        HStack {
                            Text("LV 1")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color(white: 0.4))
                            Slider(value: $previewLevel, in: 1...8, step: 1)
                                .tint(Color.salmon)
                            Text("LV 8")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color(white: 0.4))
                        }

                        let lvl = Int(previewLevel)
                        let acc = CrabAccessory.forLevel(lvl)
                        let threshold = lvl <= TamagotchiViewModel.levelThresholds.count
                            ? (lvl > 1 ? TamagotchiViewModel.levelThresholds[lvl - 1] : 0)
                            : TamagotchiViewModel.levelThresholds.last!
                        let unlocked = lvl <= AppSettings.shared.level

                        VStack(spacing: 4) {
                            Text("Level \(lvl)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.white)

                            if acc != .none {
                                Text("Unlocks: \(String(describing: acc))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(white: 0.6))
                            }

                            Text("Requires: \(threshold) XP")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color(white: 0.4))

                            if unlocked {
                                Text("Unlocked!")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Color.green)
                            } else {
                                let remaining = threshold - AppSettings.shared.xp
                                Text("\(remaining) XP to go")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Color.salmon)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }

                settingsSection("Current Progress") {
                    settingsRow("Level", value: "\(AppSettings.shared.level)")
                    Color(white: 0.12).frame(height: 1)
                    settingsRow("Total XP", value: "\(AppSettings.shared.xp)")
                    Color(white: 0.12).frame(height: 1)
                    settingsRow("Next level", value: nextThresholdText + " XP")
                    Color(white: 0.12).frame(height: 1)
                    Button("Reset Level") {
                        showingResetConfirm = true
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .buttonStyle(.plain)
                    .alert("Reset Level?", isPresented: $showingResetConfirm) {
                        Button("Cancel", role: .cancel) {}
                        Button("Reset", role: .destructive) {
                            TamagotchiViewModel.shared?.resetProgress()
                            previewLevel = 1
                        }
                    } message: {
                        Text("Your level and XP will reset to 1 and 0. You can earn your way back up through Claude Code activity.")
                    }
                }
            }
            .padding(12)
        }
    }

    // MARK: - Stats

    private var statsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                settingsSection("Streak") {
                    settingsRow("Current streak", value: "\(AppSettings.shared.streak) days")
                    Color(white: 0.12).frame(height: 1)
                    settingsRow("Last login", value: AppSettings.shared.lastLoginDate.isEmpty ? "Never" : AppSettings.shared.lastLoginDate)
                }

                settingsSection("Claude Code") {
                    settingsRow("Sessions completed", value: "\(AppSettings.shared.totalSessions)")
                    Color(white: 0.12).frame(height: 1)
                    settingsRow("Tools used", value: "\(AppSettings.shared.totalToolUses)")
                }

                settingsSection("Points") {
                    settingsRow("All-time XP earned", value: "\(AppSettings.shared.totalXPEarned) XP")
                }

                settingsSection("Pet Care") {
                    settingsRow("Pokes", value: "\(AppSettings.shared.totalPokes)", badge: "+1 XP")
                    Color(white: 0.12).frame(height: 1)
                    settingsRow("Feeds", value: "\(AppSettings.shared.totalFeeds)", badge: "+1 XP")
                    Color(white: 0.12).frame(height: 1)
                    settingsRow("Pets", value: "\(AppSettings.shared.totalPets)", badge: "+1 XP")
                    Color(white: 0.12).frame(height: 1)
                    settingsRow("Poops cleaned", value: "\(AppSettings.shared.totalPoopsCleaned)")
                }

                settingsSection("Claude Code") {
                    settingsRow("Permissions approved", value: "\(AppSettings.shared.totalPermissionsApproved)", badge: "+5 XP")
                    Color(white: 0.12).frame(height: 1)
                    settingsRow("Permissions denied", value: "\(AppSettings.shared.totalPermissionsDenied)", badge: "+3 XP")
                }
            }
            .padding(12)
        }
    }

    // MARK: - Achievements

    private var achievementsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                settingsSection("\(AppSettings.shared.unlockedAchievements.count) / \(AchievementManager.all.count) Unlocked") {
                    ForEach(Array(AchievementManager.all.enumerated()), id: \.element.id) { index, achievement in
                        if index > 0 { Color(white: 0.12).frame(height: 1) }
                        let unlocked = AppSettings.shared.unlockedAchievements.contains(achievement.id)
                        HStack {
                            Image(systemName: unlocked ? "trophy.fill" : "trophy")
                                .foregroundStyle(unlocked ? Color.yellow : Color(white: 0.33))
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(achievement.name)
                                    .font(.system(size: 11))
                                    .foregroundStyle(unlocked ? Color.white : Color(white: 0.5))
                                Text(achievement.description)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(white: 0.4))
                            }
                            Spacer()
                            if unlocked {
                                Text("+\(achievement.xpBonus) XP")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(Color.green)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(12)
        }
    }

    // MARK: - Sound

    private var soundTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                settingsSection("Sound Effects") {
                    Toggle("Enable sounds", isOn: $settings.soundEnabled)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white)
                        .tint(Color.salmon)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                    Color(white: 0.12).frame(height: 1)
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(Color(white: 0.5))
                        Slider(value: $settings.soundVolume, in: 0...1)
                            .tint(Color.salmon)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(Color(white: 0.5))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .disabled(!settings.soundEnabled)
                    .opacity(settings.soundEnabled ? 1 : 0.4)
                }

                settingsSection("Sounds Per Action") {
                    ForEach(Array(SoundAction.allCases.enumerated()), id: \.element.rawValue) { index, action in
                        if index > 0 { Color(white: 0.12).frame(height: 1) }
                        SoundPickerRow(action: action)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                    }
                }
                .disabled(!settings.soundEnabled)
                .opacity(settings.soundEnabled ? 1 : 0.4)
            }
            .padding(12)
        }
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
                darkAboutSection("What is Clawdagotchi?",
                    "A floating desktop pet that lives on your screen and reacts to your Claude Code sessions. " +
                    "It tracks tool usage, permissions, and session activity through Claude Code hooks. " +
                    "Take care of it — feed it, pet it, and clean up after it!"
                )

                darkAboutSection("Session Tracking", """
Idle — gentle bob, periodic blink
Thinking — eyes look side to side (PreToolUse)
Working — wide eyes, walking legs (PostToolUse)
Done — happy squish eyes, bounce (Stop)
Permission — alert eyes, approve/deny buttons
Buttons glow to show active session count (up to 3).
""")

                darkAboutSection("Pet Care", """
Feed (left button) — restores hunger bar
Pet (right button) — restores happiness, cleans poop
Poke (middle button) — wakes up, clears angry mood
Hunger and happiness drain over time.
Poops accumulate every ~15 min — pet to clean!
""")

                darkAboutSection("Moods", """
Sleeping — eyes close, zzz (after 2 min idle)
Hungry — small eyes, trembles (hunger bar low)
Angry — wide glare (happiness empty)
Pooping — squish face, leaves a mess
""")

                darkAboutSection("Permissions", """
When Claude Code needs approval, the screen shows the project name and tool details.
Left button (red) = Deny
Right button (green) = Allow
""")

                VStack(alignment: .leading, spacing: 8) {
                    Text("CLAUDE CODE HOOKS")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(white: 0.33))
                        .tracking(1.5)
                    HStack {
                        Text(hooksInstalled ? "Installed" : "Not installed")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(hooksInstalled ? Color.salmon : Color(white: 0.4))
                        Spacer()
                        if !hooksInstalled {
                            Button("Install Hooks") {
                                do {
                                    try HookInstaller.install()
                                    hooksInstalled = true
                                } catch {
                                    let alert = NSAlert()
                                    alert.messageText = "Installation Failed"
                                    alert.informativeText = error.localizedDescription
                                    alert.alertStyle = .critical
                                    alert.addButton(withTitle: "OK")
                                    alert.runModal()
                                }
                            }
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.salmon)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Color(white: 0.145))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .onAppear { hooksInstalled = HookInstaller.areHooksInstalled() }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview Moods")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(white: 0.33))
                        .tracking(1.5)
                    HStack(spacing: 6) {
                        moodPreviewButton("Sleep", .sleeping)
                        moodPreviewButton("Hungry", .hungry)
                        moodPreviewButton("Angry", .angry)
                        moodPreviewButton("Poop", .pooping)
                    }
                    Text("Triggers the mood on the live widget for 4 seconds.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(white: 0.33))
                }

                VStack(spacing: 8) {
                    Text("Clawdagotchi v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(white: 0.25))

                    Text("An independent fan project. Not affiliated with, sponsored by, or endorsed by Anthropic.")
                        .font(.system(size: 9))
                        .foregroundStyle(Color(white: 0.2))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(12)
        }
    }

    private func moodPreviewButton(_ label: String, _ mood: MoodState) -> some View {
        Button(label) {
            TamagotchiViewModel.shared?.previewMood(mood)
        }
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(white: 0.2))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .buttonStyle(.plain)
    }

    private func darkAboutSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(white: 0.33))
                .tracking(1.5)
            Text(body)
                .font(.system(size: 11))
                .foregroundStyle(Color(white: 0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(white: 0.33))
                .tracking(1.5)
            VStack(spacing: 0) {
                content()
            }
            .background(Color(white: 0.145))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func settingsRow(_ label: String, value: String, badge: String? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.white)
            if let badge {
                Text(badge)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.green)
            }
            Spacer()
            Text(value)
                .font(.system(size: 11))
                .foregroundStyle(Color(white: 0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

enum SettingsTab: String, CaseIterable {
    case appearance = "Appearance"
    case levelUp = "Level Up"
    case stats = "Stats"
    case badges = "Badges"
    case sound = "Sound"
    case about = "About"
}

struct SoundPickerRow: View {
    let action: SoundAction
    @State private var selected: SoundEntry
    @State private var customSounds: [SoundEntry] = SoundManager.shared.customSounds

    private static let browseSentinel = SoundEntry.system("__browse__")

    init(action: SoundAction) {
        self.action = action
        self._selected = State(initialValue: SoundManager.shared.soundEntry(for: action))
    }

    var body: some View {
        HStack {
            Text(action.label)
            Spacer()
            Picker("", selection: $selected) {
                ForEach(SoundManager.availableSounds, id: \.self) { name in
                    Text(name).tag(SoundEntry.system(name))
                }
                if !customSounds.isEmpty {
                    Divider()
                    ForEach(customSounds, id: \.self) { entry in
                        Text(entry.displayName).tag(entry)
                    }
                }
                Divider()
                Text("Browse…").tag(Self.browseSentinel)
            }
            .frame(width: 140)
            .onChange(of: selected) { _, newValue in
                if newValue == Self.browseSentinel {
                    browseForSound()
                } else {
                    SoundManager.shared.setSoundEntry(newValue, for: action)
                    SoundManager.shared.preview(newValue)
                }
            }
        }
    }

    private func browseForSound() {
        let panel = NSOpenPanel()
        panel.title = "Choose a sound file"
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else {
            selected = SoundManager.shared.soundEntry(for: action)
            return
        }

        let entry = SoundManager.shared.addCustomSound(url: url)
        customSounds = SoundManager.shared.customSounds
        selected = entry
        SoundManager.shared.setSoundEntry(entry, for: action)
        SoundManager.shared.preview(entry)
    }
}
