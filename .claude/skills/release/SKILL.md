---
name: release
description: >
  Cut a new release of Clawdagotchi. Use when the user asks to release, ship,
  cut a release, create a new version, bump the version, or push an update.
  Handles the full release pipeline: version bump in Info.plist, DMG build,
  notarization, stapling, GitHub release creation, and Homebrew cask update.
---

# Clawdagotchi Release Process

**Project constants:**
- Repo: `cpenned/clawdagotchi`
- Signing team: `5FS8D53Q69`
- Notarization keychain profile: `notary`
- Homebrew tap: `cpenned/homebrew-tap`, cask file: `Casks/clawdagotchi.rb`
- Working directory: repo root

## Steps

### 1. Determine new version

Read current version from `Info.plist` (`CFBundleShortVersionString`). Ask the user what the new version should be if not specified. Convention: patch for fixes, minor for features.

### 2. Update Info.plist

Bump both fields:
- `CFBundleShortVersionString` → new version (e.g. `1.5.0`)
- `CFBundleVersion` → increment integer by 1

### 3. Commit and push

```bash
git add Info.plist
git commit -m "chore: bump to vX.Y.Z"
git push
```

### 4. Build DMG

```bash
bash scripts/create-dmg.sh
```

Produces `releases/Clawdagotchi-X.Y.Z.dmg` and `releases/Clawdagotchi.dmg`.

Verify the output includes `Included hook_relay.py`. If it says `WARNING: hook_relay.py not found`, stop and investigate before continuing.

### 5. Notarize

```bash
xcrun notarytool submit releases/Clawdagotchi-X.Y.Z.dmg --keychain-profile "notary" --wait
```

Must end with `status: Accepted`. If rejected, check the log: `xcrun notarytool log <submission-id> --keychain-profile "notary"`.

### 6. Staple and copy stable DMG

```bash
xcrun stapler staple releases/Clawdagotchi-X.Y.Z.dmg
cp releases/Clawdagotchi-X.Y.Z.dmg releases/Clawdagotchi.dmg
```

### 7. Create GitHub release

Generate release notes from git log since the previous tag, then:

```bash
gh release create vX.Y.Z releases/Clawdagotchi-X.Y.Z.dmg releases/Clawdagotchi.dmg \
  --title "Clawdagotchi vX.Y.Z" \
  --notes "..."
```

### 8. Update Homebrew cask

```bash
SHA=$(shasum -a 256 releases/Clawdagotchi-X.Y.Z.dmg | awk '{print $1}')
CURRENT_SHA=$(gh api repos/cpenned/homebrew-tap/contents/Casks/clawdagotchi.rb --jq '.sha')
```

Update `version` and `sha256` in the cask content, then PUT it:

```bash
gh api repos/cpenned/homebrew-tap/contents/Casks/clawdagotchi.rb \
  --method PUT \
  --field message="chore: bump clawdagotchi to vX.Y.Z" \
  --field content="$(echo "$CONTENT" | base64)" \
  --field sha="$CURRENT_SHA"
```

## Notes

- `releases/` is gitignored — DMGs are never committed to git
- `Clawdagotchi.dmg` (no version) is the stable copy used by direct download links
- All download CTAs point to `https://github.com/cpenned/clawdagotchi/releases/latest`
- The app checks for updates on launch via the GitHub releases API
