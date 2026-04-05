# Death & Rebirth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clawdagotchi dies if Claude goes quiet for a random 12–24h window, triggering a GAME OVER screen with survival stats, followed by a rebirth naming flow.

**Architecture:** Two new persisted fields on `AppSettings` track the last Claude hook timestamp and a randomized death threshold. On startup, `TamagotchiViewModel.start()` checks if the threshold has elapsed and sets `isDead = true`. `ContentView` renders a full-screen `DeathRebirthOverlay` when `isDead`, which handles the two-stage GAME OVER → naming flow, then calls `rebirth(newName:)` to reset state.

**Tech Stack:** Swift 6, SwiftUI, `@Observable`, `UserDefaults`

---

## Files

| Action | File | Responsibility |
|---|---|---|
| Modify | `Sources/Clawdagotchi/AppSettings.swift` | Add two new persisted fields |
| Modify | `Sources/Clawdagotchi/TamagotchiViewModel.swift` | Add `DeathStats`, `isDead`, `deathStats`, `checkForDeath()`, update `handleEvent()`, add `rebirth()` |
| Create | `Sources/Clawdagotchi/DeathRebirthOverlay.swift` | Full-screen two-stage death/rebirth UI |
| Modify | `Sources/Clawdagotchi/ContentView.swift` | Overlay `DeathRebirthOverlay` when `isDead` |

---

## Task 1: Add persisted death fields to AppSettings

**Files:**
- Modify: `Sources/Clawdagotchi/AppSettings.swift`

- [ ] **Step 1: Add the two new stored properties**

In `AppSettings.swift`, add these two properties after `var birthDate`:

```swift
var lastClaudeActivityTimestamp: Double {
    didSet { UserDefaults.standard.set(lastClaudeActivityTimestamp, forKey: "lastClaudeActivityTimestamp") }
}
var deathThreshold: Double {
    didSet { UserDefaults.standard.set(deathThreshold, forKey: "deathThreshold") }
}
```

- [ ] **Step 2: Register defaults**

In `private init()`, inside the `defaults.register(defaults: [...])` call, add:

```swift
"lastClaudeActivityTimestamp": Double(0),
"deathThreshold": Double(0),
```

- [ ] **Step 3: Load in init**

After the existing `self.birthDate = ...` line, add:

```swift
self.lastClaudeActivityTimestamp = defaults.double(forKey: "lastClaudeActivityTimestamp")
self.deathThreshold = defaults.double(forKey: "deathThreshold")
```

- [ ] **Step 4: Build**

```bash
cd /Users/chrispennington/Developer/personal/clawdagotchi && swift build 2>&1 | tail -5
```

Expected: `Build complete!`

- [ ] **Step 5: Commit**

```bash
git add Sources/Clawdagotchi/AppSettings.swift
git commit -m "feat: add lastClaudeActivityTimestamp and deathThreshold to AppSettings"
```

---

## Task 2: Add death logic to TamagotchiViewModel

**Files:**
- Modify: `Sources/Clawdagotchi/TamagotchiViewModel.swift`

- [ ] **Step 1: Add `DeathStats` struct and new properties**

After the `enum FunReaction` block (around line 66), add:

```swift
struct DeathStats: Sendable {
    let name: String
    let days: Int
    let level: Int
    let xp: Int
}
```

After `private(set) var justLeveledUp: Bool = false` (around line 44), add:

```swift
private(set) var isDead: Bool = false
private(set) var deathStats: DeathStats? = nil
```

- [ ] **Step 2: Add `checkForDeath()` method**

Add this new method in the `// MARK: - Mood system` section (before `previewMood`):

```swift
// MARK: - Death

private func checkForDeath() {
    let settings = AppSettings.shared
    let lastActivity = settings.lastClaudeActivityTimestamp
    guard lastActivity > 0 else { return }
    let elapsed = Date().timeIntervalSince1970 - lastActivity
    if elapsed > settings.deathThreshold {
        isDead = true
        deathStats = DeathStats(
            name: settings.botName,
            days: settings.ageInDays,
            level: settings.level,
            xp: settings.xp
        )
    }
}
```

- [ ] **Step 3: Call `checkForDeath()` from `start()`**

In `func start()`, add this line immediately after `checkDailyLogin()`:

```swift
checkForDeath()
```

- [ ] **Step 4: Record activity and roll threshold in `handleEvent()`**

In `handleEvent(_:)`, immediately after `lastInteractionTime = now` (around line 524), add:

```swift
let settings = AppSettings.shared
settings.lastClaudeActivityTimestamp = now.timeIntervalSince1970
if settings.deathThreshold == 0 {
    settings.deathThreshold = Double.random(in: 43200...86400)
}
```

- [ ] **Step 5: Add `rebirth(newName:)` method**

Add this method next to `resetProgress()` (around line 487):

```swift
func rebirth(newName: String) {
    let settings = AppSettings.shared
    settings.xp = 0
    settings.level = 1
    settings.birthDate = Self.todayString()
    settings.streak = 0
    settings.lastLoginDate = Self.todayString()
    settings.botName = newName.isEmpty ? "Clawd" : newName
    settings.lastClaudeActivityTimestamp = 0
    settings.deathThreshold = 0
    isDead = false
    deathStats = nil
}
```

- [ ] **Step 6: Build**

```bash
cd /Users/chrispennington/Developer/personal/clawdagotchi && swift build 2>&1 | tail -5
```

Expected: `Build complete!`

- [ ] **Step 7: Commit**

```bash
git add Sources/Clawdagotchi/TamagotchiViewModel.swift
git commit -m "feat: add death detection and rebirth logic to TamagotchiViewModel"
```

---

## Task 3: Create DeathRebirthOverlay view

**Files:**
- Create: `Sources/Clawdagotchi/DeathRebirthOverlay.swift`

- [ ] **Step 1: Create the file**

Create `Sources/Clawdagotchi/DeathRebirthOverlay.swift` with this content:

```swift
import SwiftUI

struct DeathRebirthOverlay: View {
    let stats: TamagotchiViewModel.DeathStats
    let onRebirth: (String) -> Void

    @State private var stage: Int = 1
    @State private var newName: String = ""
    @State private var showStats: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.92)

            if stage == 1 {
                gameOverView
                    .transition(.opacity)
            } else {
                newCrabView
                    .transition(.opacity)
            }
        }
        .onAppear {
            newName = stats.name
            withAnimation(.easeIn(duration: 0.6).delay(0.4)) {
                showStats = true
            }
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 12) {
            Text("GAME OVER")
                .font(.system(.title2, design: .monospaced, weight: .bold))
                .foregroundStyle(.red)
                .tracking(4)

            Rectangle()
                .fill(Color(white: 0.2))
                .frame(width: 100, height: 1)

            if showStats {
                Text(stats.name.uppercased())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(white: 0.4))
                    .transition(.opacity.combined(with: .move(edge: .top)))

                HStack(spacing: 24) {
                    statTile(value: "\(stats.days)", label: "DAYS")
                    statTile(value: "\(stats.level)", label: "LEVEL")
                    statTile(value: "\(stats.xp)", label: "XP")
                }
                .transition(.opacity)

                Rectangle()
                    .fill(Color(white: 0.1))
                    .frame(width: 100, height: 1)
                    .transition(.opacity)

                Text("gone quiet... forgotten")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color(white: 0.2))
                    .transition(.opacity)
            }

            Spacer().frame(height: 16)

            Text("tap to continue")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color(white: 0.25))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(white: 0.15), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.4)) {
                stage = 2
            }
        }
    }

    private var newCrabView: some View {
        VStack(spacing: 10) {
            Text("🥚")
                .font(.system(size: 48))

            Text("A NEW CRAB AWAITS")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color(red: 0.48, green: 0.44, blue: 1.0))
                .tracking(2)

            Text("name your new companion")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color(white: 0.35))

            TextField("", text: $newName)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color(white: 0.7))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(white: 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color(red: 0.23, green: 0.23, blue: 0.42), lineWidth: 1)
                )
                .frame(width: 140)

            Button {
                onRebirth(newName.isEmpty ? "Clawd" : newName)
            } label: {
                Text("HATCH")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(white: 0.75))
                    .tracking(1)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.16, green: 0.1, blue: 0.42))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(red: 0.35, green: 0.29, blue: 0.67), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Text("lifetime stats preserved")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color(white: 0.2))
                .padding(.top, 8)
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .monospaced))
                .foregroundStyle(Color(white: 0.55))
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color(white: 0.27))
                .tracking(1)
        }
    }
}
```

- [ ] **Step 2: Build**

```bash
cd /Users/chrispennington/Developer/personal/clawdagotchi && swift build 2>&1 | tail -5
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/Clawdagotchi/DeathRebirthOverlay.swift
git commit -m "feat: add DeathRebirthOverlay two-stage death/rebirth UI"
```

---

## Task 4: Wire overlay into ContentView

**Files:**
- Modify: `Sources/Clawdagotchi/ContentView.swift`

- [ ] **Step 1: Wrap body in ZStack and add overlay**

Replace the entire `var body: some View` in `ContentView.swift` with:

```swift
var body: some View {
    ZStack {
        TamagotchiView(
            state: viewModel.displayState,
            sessionCount: viewModel.activeSessionCount,
            pendingPermission: viewModel.pendingPermission,
            pendingPermissionCount: viewModel.pendingPermissionCount,
            hunger: viewModel.hunger,
            happiness: viewModel.happiness,
            moodState: viewModel.moodState,
            poopCount: viewModel.poopCount,
            greetingMessage: viewModel.greetingMessage,
            funReaction: viewModel.funReaction,
            level: viewModel.currentLevel,
            xpProgress: viewModel.xpProgress,
            justLeveledUp: viewModel.justLeveledUp,
            simonSaysActive: viewModel.simonSaysActive,
            simonPromptActive: viewModel.simonPromptActive,
            simonShowingPattern: viewModel.simonShowingPattern,
            simonHighlight: viewModel.simonHighlight,
            onApprove: { viewModel.approvePermission() },
            onDeny: { viewModel.denyPermission() },
            onPoke: { viewModel.pokeCrab() },
            onFeed: { viewModel.feedCrab() },
            onPet: { viewModel.petCrab() },
            onSimonInput: { viewModel.simonInput($0) },
            onSimonPromptAccept: { viewModel.acceptSimonPrompt() },
            onSimonPromptDecline: { viewModel.declineSimonPrompt() }
        )
        .scaleEffect(widgetScale)

        if viewModel.isDead, let stats = viewModel.deathStats {
            DeathRebirthOverlay(stats: stats) { newName in
                viewModel.rebirth(newName: newName)
            }
        }
    }
    .frame(width: baseWidth * widgetScale, height: baseHeight * widgetScale)
}
```

- [ ] **Step 2: Build**

```bash
cd /Users/chrispennington/Developer/personal/clawdagotchi && swift build 2>&1 | tail -5
```

Expected: `Build complete!`

- [ ] **Step 3: Smoke test — trigger death manually**

To verify the full flow works, temporarily force `isDead = true` in `checkForDeath()` by replacing the method body with:

```swift
private func checkForDeath() {
    isDead = true
    deathStats = DeathStats(
        name: AppSettings.shared.botName,
        days: AppSettings.shared.ageInDays,
        level: AppSettings.shared.level,
        xp: AppSettings.shared.xp
    )
}
```

Then build and run:

```bash
swift build && bash build_app.sh && open Clawdagotchi.app
```

Verify:
- GAME OVER screen appears immediately on launch
- Stats show correct name, days, level, XP
- Tapping advances to egg/naming stage
- Entering a name and pressing HATCH dismisses the overlay
- The crab's name updates in the settings/greeting

- [ ] **Step 4: Restore real `checkForDeath()` logic**

Replace the temporary body with the real implementation:

```swift
private func checkForDeath() {
    let settings = AppSettings.shared
    let lastActivity = settings.lastClaudeActivityTimestamp
    guard lastActivity > 0 else { return }
    let elapsed = Date().timeIntervalSince1970 - lastActivity
    if elapsed > settings.deathThreshold {
        isDead = true
        deathStats = DeathStats(
            name: settings.botName,
            days: settings.ageInDays,
            level: settings.level,
            xp: settings.xp
        )
    }
}
```

- [ ] **Step 5: Final build**

```bash
cd /Users/chrispennington/Developer/personal/clawdagotchi && swift build 2>&1 | tail -5
```

Expected: `Build complete!`

- [ ] **Step 6: Commit**

```bash
git add Sources/Clawdagotchi/ContentView.swift Sources/Clawdagotchi/TamagotchiViewModel.swift
git commit -m "feat: wire DeathRebirthOverlay into ContentView"
```
