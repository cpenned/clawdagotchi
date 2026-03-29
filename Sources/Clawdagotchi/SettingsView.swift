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

                helpSection("Crab Expressions", """
                Idle — gentle bob, periodic blink (zzz)
                Thinking — eyes look side to side (...)
                Working — wide eyes, walking legs (>>>)
                Done — happy squish eyes, bounce (^_^)
                Permission — alert eyes, pulsing border
                """)

                helpSection("Buttons (Normal Mode)", """
                Left — Poke the crab (surprised jump)
                Middle — (reserved)
                Right — Pet the crab (happy walk)
                Buttons glow pink per active session count.
                """)

                helpSection("Buttons (Permission Mode)", """
                Left (red) — Deny the permission
                Middle (orange) — Shows tool name
                Right (green) — Allow the permission
                The screen shows the tool requesting access.
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
