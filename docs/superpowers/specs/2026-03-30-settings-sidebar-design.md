# Settings Sidebar Redesign

**Goal:** Replace the top pill tab bar in the Settings window with a left sidebar containing the crab, pet identity info, and vertical tab navigation — making the crab a first-class citizen in the UI.

**Architecture:** Change `SettingsView` layout from `VStack` (tab bar on top + content below) to `HStack` (sidebar + content). The sidebar is a fixed-width panel. All tab content views remain unchanged except the About tab. Changes confined to `SettingsView.swift`.

**Tech Stack:** Swift 6, SwiftUI, macOS 15+

---

## Window Size

Change `.frame(width: 440, height: 500)` → `.frame(width: 580, height: 520)`.

---

## Sidebar (160px wide)

Fixed-width left panel, `#161616` background, 1px `#2a2a2a` right border.

Content (top to bottom, centered):

1. **Crab** — `CrabView(size: 60, color: AppSettings.shared.activeCrabColor, ...)` with current accessories, in a `#1e1e1e` rounded rect (80×76, cornerRadius 8, 1px `#2a2a2a` border). No leg animation.
2. **Bot name** — `AppSettings.shared.botName`, salmon `#D97757`, 13pt, weight `.semibold`
3. **Level** — `"Level \(AppSettings.shared.level)"`, `Color(white: 0.4)`, 9pt monospaced
4. **XP bar** — 100px wide, 3px tall, `#252525` track, salmon fill at `CGFloat(AppSettings.shared.xp) / CGFloat(nextXPThreshold)`. Label below: `"\(xp) / \(nextXPThreshold) XP"`, 8pt, `Color(white: 0.27)`
5. **Streak** — 🔥 icon + `"\(AppSettings.shared.streak) day streak"`, 9pt monospaced, `Color(white: 0.53)`. Hidden if `streak == 0`.
6. **Vertical tab list** — `VStack(spacing: 2)` of tab buttons, `padding(.horizontal, 8)`. Active tab: salmon background, white text, `cornerRadius(4)`, weight `.semibold`. Inactive: `Color(white: 0.4)` text, clear background. Font: 9pt monospaced.

`nextXPThreshold` is the existing `nextThresholdText` computed var (already in `SettingsView`). Reuse it directly for the XP label: `"\(AppSettings.shared.xp) / \(nextThresholdText) XP"`.

---

## Content Area

`flex:1` (fills remaining width after sidebar). Background `Color.screenDark` (`#1A1A1A`). Contains a `ScrollView` wrapping the selected tab's content view — same as current layout.

Remove the old `tabBar` view entirely. The `tabContent` switch stays the same.

---

## About Tab — Revised

Remove the `darkAboutSection("Your Crab", ...)` block (level, XP, born, age) — this info now lives in the sidebar.

Keep and reorder sections:

1. **WHAT IS CLAWDAGOTCHI?** — existing text, unchanged
2. **SESSION TRACKING** — existing text, unchanged
3. **PET CARE** — existing text, unchanged
4. **MOODS** — existing text, unchanged
5. **PERMISSIONS** — existing text, unchanged
6. **PREVIEW MOODS** — existing 4 mood buttons (Sleep, Hungry, Angry, Poop), existing implementation unchanged
7. **CLAUDE CODE HOOKS** — existing hook status row (installed/not installed + install button), unchanged
8. **Footer** — "Export Screenshot..." button, "Check for Updates..." + "⭐ Star on GitHub" buttons, version string, disclaimer text — all existing, unchanged

Remove the old `darkAboutSection("Setup", ...)` (already replaced by hook status in the previous feature).

---

## App Menu

Currently the app uses `.commandsRemoved()` (no macOS menu bar). Replace with explicit `commands { ... }` that:

- Removes the default File, Edit, Window, and Help menus (`CommandGroup(replacing:) {}`)
- Adds "Star on GitHub" under the app menu after "About":

```swift
CommandGroup(after: .appInfo) {
    Button("Star on GitHub") {
        NSWorkspace.shared.open(URL(string: "https://github.com/cpenned/clawdagotchi")!)
    }
}
```

Result: app menu shows only "About Clawdagotchi", "Star on GitHub", and "Quit Clawdagotchi". All other menus removed.

---

## File Map

| File | Change |
|------|--------|
| `Sources/Clawdagotchi/SettingsView.swift` | Restructure layout; revise About tab |
| `Sources/Clawdagotchi/ClaudeTamagotchiApp.swift` | Replace `.commandsRemoved()` with explicit menu commands |

No other files change.

---

## Out of Scope

- Animating the sidebar crab
- Changing any settings logic
- Changing any tab content other than About
- Adding/removing tabs
