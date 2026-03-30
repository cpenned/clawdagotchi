# Settings Sidebar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the top pill tab bar in Settings with a left sidebar containing the crab, pet identity info, and vertical tab navigation, and add "Star on GitHub" to the app menu.

**Architecture:** Change `SettingsView.body` from a `VStack` (tab bar + content) to an `HStack` (sidebar + content). Remove the old `tabBar` computed var and `PillTabButtonStyle`. Add a `sidebar` computed var. Revise `aboutTab` to remove "Your Crab" section and reorder content. Update window frame from 440×500 to 580×520. Update `ClaudeTamagotchiApp` to replace `.commandsRemoved()` with explicit `commands`.

**Tech Stack:** Swift 6, SwiftUI, macOS 15+

---

## File Map

| File | Change |
|------|--------|
| `Sources/Clawdagotchi/SettingsView.swift` | New sidebar layout, revised About tab, remove PillTabButtonStyle |
| `Sources/Clawdagotchi/ClaudeTamagotchiApp.swift` | Replace `.commandsRemoved()` with explicit menu commands |

---

### Task 1: Replace top tab bar with sidebar layout

**Files:**
- Modify: `Sources/Clawdagotchi/SettingsView.swift`

This is the core structural change. The `body` switches from `VStack` to `HStack`. A new `sidebar` computed var replaces `tabBar`. `PillTabButtonStyle` is deleted (tabs are now plain buttons in the sidebar). Window grows from 440×500 → 580×520.

- [ ] **Step 1: Read the current file to understand exact line numbers**

```bash
head -50 Sources/Clawdagotchi/SettingsView.swift
```

- [ ] **Step 2: Replace `body`, remove `tabBar`, remove `PillTabButtonStyle`, add `sidebar`**

Replace the current `body` (lines 8–17):
```swift
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
```

Delete the entire `tabBar` computed var (the `private var tabBar: some View { ... }` block, currently lines 19–35).

Delete the entire `PillTabButtonStyle` struct at the bottom of the file.

Add this new `sidebar` computed var after `body`:

```swift
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
                color: AppSettings.shared.activeCrabColor,
                eyeColor: Color.screenDark,
                eyeStyle: .normal,
                accessories: CrabAccessory.allUnlocked(
                    for: AppSettings.shared.level,
                    seasonalEnabled: AppSettings.shared.seasonalAccessories
                ),
                accessoryColor: .white
            )
        }
        .padding(.bottom, 12)

        // Bot name
        Text(AppSettings.shared.botName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.salmon)
            .padding(.bottom, 2)

        // Level
        Text("Level \(AppSettings.shared.level)")
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(Color(white: 0.4))
            .padding(.bottom, 6)

        // XP bar
        let xpFraction: CGFloat = {
            let thresholds = TamagotchiViewModel.levelThresholds
            let level = AppSettings.shared.level
            guard level < thresholds.count else { return 1.0 }
            let target = CGFloat(thresholds[level])
            return target > 0 ? min(CGFloat(AppSettings.shared.xp) / target, 1.0) : 1.0
        }()
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(white: 0.145)).frame(height: 3)
                Capsule().fill(Color.salmon).frame(width: geo.size.width * xpFraction, height: 3)
            }
        }
        .frame(width: 100, height: 3)
        .padding(.bottom, 3)

        Text("\(AppSettings.shared.xp) / \(nextThresholdText) XP")
            .font(.system(size: 8, design: .monospaced))
            .foregroundStyle(Color(white: 0.27))
            .padding(.bottom, 14)

        // Streak
        if AppSettings.shared.streak > 0 {
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 10))
                Text("\(AppSettings.shared.streak) day streak")
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
                Button(tab.rawValue) {
                    selectedTab = tab
                }
                .font(.system(size: 9, weight: selectedTab == tab ? .semibold : .regular, design: .monospaced))
                .foregroundStyle(selectedTab == tab ? Color.white : Color(white: 0.4))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(selectedTab == tab ? Color.salmon : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)

        Spacer()
    }
    .padding(.top, 20)
    .frame(width: 160)
    .frame(maxHeight: .infinity)
    .background(Color(white: 0.086))
}
```

- [ ] **Step 3: Build to verify**

```bash
swift build 2>&1 | tail -8
```

Expected: `Build complete!` — fix any errors before continuing.

- [ ] **Step 4: Commit**

```bash
git add Sources/Clawdagotchi/SettingsView.swift
git commit -m "feat: replace top tab bar with sidebar layout in Settings"
```

---

### Task 2: Revise About tab — remove "Your Crab", reorder sections

**Files:**
- Modify: `Sources/Clawdagotchi/SettingsView.swift`

The "Your Crab" section (level, XP, born, age) is now redundant — that info lives in the sidebar. Remove it. The rest of the About tab stays, just without that block.

- [ ] **Step 1: Remove the `darkAboutSection("Your Crab", ...)` block**

Find and delete this block in `aboutTab` (currently lines 533–538):

```swift
                darkAboutSection("Your Crab", """
Level \(AppSettings.shared.level) — \(CrabAccessory.forLevel(AppSettings.shared.level)) unlocked
XP: \(AppSettings.shared.xp) / \(nextThresholdText)
Born: \(AppSettings.shared.birthDateFormatted)
Age: \(AppSettings.shared.ageInDays) days
""")
```

Delete that block entirely. The remaining sections stay in their current order.

- [ ] **Step 2: Build to verify**

```bash
swift build 2>&1 | tail -5
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/Clawdagotchi/SettingsView.swift
git commit -m "feat: remove redundant Your Crab section from About tab"
```

---

### Task 3: Add app menu with "Star on GitHub"

**Files:**
- Modify: `Sources/Clawdagotchi/ClaudeTamagotchiApp.swift`

The app currently uses `.commandsRemoved()` which strips the entire macOS menu bar. Replace with explicit commands that keep only the essential app menu items (About + Star on GitHub + Quit) and remove File, Edit, Window, Help.

- [ ] **Step 1: Replace `ClaudeTamagotchiApp.swift`**

```swift
import SwiftUI
import AppKit

@main
struct ClawdagotchiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = TamagotchiViewModel()

    var body: some Scene {
        Window("Clawdagotchi", id: "main") {
            ContentView(viewModel: viewModel)
                .background(WindowConfigurator(hasPermissionPending: viewModel.pendingPermission != nil))
                .onAppear { viewModel.start() }
                .onDisappear { viewModel.stop() }
        }
        .windowStyle(.plain)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 290, height: 350)
        .commands {
            // Remove default menus we don't use
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .windowList) {}
            CommandGroup(replacing: .windowArrangement) {}
            CommandGroup(replacing: .help) {}
            // Add Star on GitHub after About
            CommandGroup(after: .appInfo) {
                Button("Star on GitHub") {
                    if let url = URL(string: "https://github.com/cpenned/clawdagotchi") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }

        Settings {
            SettingsView()
        }
    }
}

struct WindowConfigurator: NSViewRepresentable {
    let hasPermissionPending: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isMovableByWindowBackground = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            applyFloatLevel(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        applyFloatLevel(to: window)
    }

    private func applyFloatLevel(to window: NSWindow) {
        let policy = AppSettings.shared.floatPolicy
        switch policy {
        case .always:
            window.level = .floating
        case .permissionOnly:
            window.level = hasPermissionPending ? .floating : .normal
        case .never:
            window.level = .normal
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
swift build 2>&1 | tail -5
```

Expected: `Build complete!`

- [ ] **Step 3: Smoke test the menu**

```bash
swift build && bash build_app.sh && open Clawdagotchi.app
```

Click on the app to focus it. Check the macOS menu bar — should see: Clawdagotchi menu (About, Star on GitHub, Quit). No File, Edit, Window, or Help menus should be visible.

- [ ] **Step 4: Commit**

```bash
git add Sources/Clawdagotchi/ClaudeTamagotchiApp.swift
git commit -m "feat: add Star on GitHub to app menu, remove unused menu items"
```
