# Death & Rebirth Design

**Goal:** Clawdagotchi can die if Claude goes quiet for too long, adding real stakes to the companion relationship. On next app open, the user sees a GAME OVER screen with survival stats, then a rebirth flow to name their new crab.

---

## Trigger

Death is checked once on app startup in `TamagotchiViewModel.start()`, after `checkDailyLogin()`.

**Condition:** `now - lastClaudeActivityTimestamp > deathThreshold`

- `lastClaudeActivityTimestamp` — Unix timestamp of the last received hook event (any of PreToolUse, PostToolUse, Stop, SubagentStop). Defaults to 0 (never had Claude activity → no death check runs).
- `deathThreshold` — a random value in `43200...86400` seconds (12–24h). Rolled once on the first Claude activity after a reset and persisted. This means the exact death window is unpredictable: the crab could go at 12h or survive until 24h.

If `lastClaudeActivityTimestamp == 0`, skip the death check entirely (fresh install or just-reborn crab).

---

## Data Model Changes (AppSettings)

Two new `UserDefaults`-backed fields:

| Field | Type | Default | Notes |
|---|---|---|---|
| `lastClaudeActivityTimestamp` | `Double` | `0` | Unix timestamp; 0 = never |
| `deathThreshold` | `Double` | `0` | Seconds; 0 = needs rolling |

Both are reset to `0` on rebirth, so a fresh threshold is rolled after the new crab's first Claude activity.

---

## Activity Recording (TamagotchiViewModel)

In `handleEvent()`, after updating `lastInteractionTime`, persist activity and roll threshold if needed:

```swift
let settings = AppSettings.shared
settings.lastClaudeActivityTimestamp = Date().timeIntervalSince1970
if settings.deathThreshold == 0 {
    settings.deathThreshold = Double.random(in: 43200...86400)
}
```

The threshold only rolls when it's 0 — it remains stable for the rest of that life.

---

## Death Detection (TamagotchiViewModel)

New `checkForDeath()` method called from `start()`:

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

New ViewModel properties:
- `private(set) var isDead: Bool = false`
- `private(set) var deathStats: DeathStats? = nil`

```swift
struct DeathStats {
    let name: String
    let days: Int
    let level: Int
    let xp: Int
}
```

---

## Rebirth (TamagotchiViewModel)

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

**Preserved on rebirth:** all lifetime stats (`totalSessions`, `totalToolUses`, `totalXPEarned`, `totalPokes`, `totalFeeds`, `totalPets`, `totalPoopsCleaned`, `totalPermissionsApproved`, `totalPermissionsDenied`, `unlockedAchievements`).

---

## UI: DeathRebirthOverlay

A new self-contained `DeathRebirthOverlay` view. No changes to `TamagotchiView`.

**Placement:** In `ContentView`, added as a `ZStack` layer (or `.overlay`) shown when `viewModel.isDead`.

### Stage 1 — GAME OVER

- Dark background, monospace font throughout
- `GAME OVER` in red, letter-spaced, fades in
- Crab name displayed
- Three stat tiles stagger in below: **DAYS · LEVEL · XP** (from `deathStats`)
- Subtext: "gone quiet... forgotten"
- "tap to continue" prompt at bottom
- Tapping anywhere advances to Stage 2

### Stage 2 — New Crab

- Egg emoji (🥚) centered
- `A NEW CRAB AWAITS` in purple/indigo monospace
- "name your new companion" label
- `TextField` pre-filled with current `botName`
- `HATCH` button — calls `viewModel.rebirth(newName: fieldValue)`
- Subtle "lifetime stats preserved" note at bottom

### Animation

- Stage 1 fades in on appear
- Stats stagger with small delays (0.1s each)
- Transition from Stage 1 → 2: crossfade or slide

---

## What Resets vs Persists

| Field | On Death |
|---|---|
| `xp` | Reset to 0 |
| `level` | Reset to 1 |
| `birthDate` | Reset to today |
| `streak` | Reset to 0 |
| `lastLoginDate` | Reset to today |
| `botName` | Updated to new name from prompt |
| `lastClaudeActivityTimestamp` | Reset to 0 |
| `deathThreshold` | Reset to 0 |
| All `total*` stats | **Preserved** |
| `unlockedAchievements` | **Preserved** |

---

## Edge Cases

- **First launch / never had Claude activity:** `lastClaudeActivityTimestamp == 0` → death check skipped. Crab is always alive on fresh install.
- **App never opened between activity and check:** The timestamp is recorded in-process, so as long as a hook fired in the previous session the timestamp is valid.
- **Name left blank:** Falls back to `"Clawd"`.
