import SwiftUI

struct SettingsView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        TabView {
            appearanceTab
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            soundTab
                .tabItem { Label("Sound", systemImage: "speaker.wave.2") }
            helpTab
                .tabItem { Label("Help", systemImage: "questionmark.circle") }
        }
        .frame(width: 360, height: 440)
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
                        Circle().fill(Color(red: 0.94, green: 0.56, blue: 0.50)).frame(width: 10, height: 10)
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
                Toggle("Show menubar icon", isOn: $settings.showMenubarIcon)
                Toggle("Show floating widget", isOn: $settings.showWidget)
            }
        }
        .formStyle(.grouped)
        .padding()
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

    private var helpTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                helpSection("What is Clawdagotchi?",
                    "A floating desktop pet that reacts to your Claude Code sessions in real-time. " +
                    "It listens for hook events and shows what Claude is doing as animated crab expressions."
                )

                helpSection("Crab States (Claude Activity)", """
                Idle — gentle bob, periodic blink
                Thinking — eyes look side to side
                Working — wide eyes, walking legs
                Done — happy squish eyes, bounce
                Permission — alert eyes, pulsing border
                """)

                helpSection("Crab Moods (Idle Behaviors)", """
                Normal — happy and content
                Sleeping — eyes close, zzz rises (2 min idle)
                Hungry — small eyes, trembles (5 min unfed)
                Angry — wide glare, still (8 min no interaction)
                Pooping — squish face, "oops" (random)
                Any button press or Claude event wakes it up!
                """)

                helpSection("Buttons (Normal Mode)", """
                Left — Poke (surprised jump, "hey! >_<")
                Middle — Feed (nom nom eating)
                Right — Pet (happy walk, "~ happy ~")
                Buttons glow pink per active session count.
                """)

                helpSection("Buttons (Permission Mode)", """
                Left (red) — Deny the permission
                Middle (orange) — Info
                Right (green) — Allow the permission
                Screen scrolls what the tool wants to do.
                """)

                helpSection("Setup", """
                1. Build: bash build_app.sh
                2. Install hooks: bash install_hooks.sh
                3. Use Claude Code normally — the crab reacts!
                """)

                HStack {
                    Spacer()
                    Text("Clawdagotchi v2.0.0")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
            .padding()
        }
    }

    private func helpSection(_ title: String, _ body: String) -> some View {
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
                ForEach(availableSounds, id: \.self) { name in
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
