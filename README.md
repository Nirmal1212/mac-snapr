# Snapr

Lightweight macOS menu bar utility for window management (snap, resize, move across displays), similar to Windows Snap / PowerToys FancyZones.

Spec-driven with [OpenSpec](https://github.com/Fission-AI/OpenSpec).

```bash
npm install -g @fission-ai/openspec
openspec init        # select your AI tool
openspec list        # active changes
openspec validate add-window-management --strict
```

Workflow: proposal in `openspec/changes/` → implement via `tasks.md` → `openspec archive add-window-management --yes`.

## Try it (testers)
1. Download `Snapr-<version>.dmg` from the Releases page and drag Snapr to Applications.
2. The build is ad-hoc signed (not notarized): right-click Snapr.app → Open the first time (or run `xattr -dr com.apple.quarantine /Applications/Snapr.app`).
3. Grant Accessibility access when prompted (System Settings → Privacy & Security → Accessibility).

## Install with Homebrew
Once a tap is published (see `docs/releasing.md`): `brew install --cask snapr`. The cask template is `packaging/homebrew/snapr.rb.template`.

## Updates
Releases built with a feed URL and Sparkle public key check for updates about daily and offer a "Check for Updates…" menu item; turn automatic checks off in Settings. Dev builds (`swift run`) have updates disabled. Maintainer steps (keys, signing, appcast, cask): `docs/releasing.md`.

## Build
```bash
swift run                 # run from source
scripts/package.sh        # produces dist/Snapr.app (with Sparkle embedded) and dist/Snapr-<version>.dmg
```
Release: push a tag like `v0.1.0`; CI builds the DMG and attaches it to a GitHub Release.

## Usage
Snapr lives in the menu bar (no Dock icon). Pick any action from the menu, use a shortcut, or drag a window to a screen edge.

| Action | Default shortcut |
|--------|------------------|
| Left / Right / Top / Bottom half | Ctrl+Opt+Arrow |
| Top-left / top-right / bottom-left / bottom-right quarter | Ctrl+Opt+U / I / J / K |
| Left / center / right third | Ctrl+Opt+D / F / G |
| Left / right two thirds | Ctrl+Opt+E / T |
| Maximize / Center / Restore | Ctrl+Opt+Return / C / Delete |
| Next / previous display | Ctrl+Opt+Cmd+Right / Left |

- Pressing Left/Right Half repeatedly cycles 1/2, 1/3, 2/3 width.
- Drag a window to the left/right edge for a half, the top edge to maximize, or a corner for a quarter; a preview shows the target.
- Rebind or clear shortcuts in Settings (conflicts are flagged), toggle drag snapping, and enable launch at login.
- Fully local: the only network use is the optional update check; no telemetry.

Screenshots: not yet captured (needs a signed-in desktop session).

## Layout
- `Sources/SnaprCore`: pure, unit-tested logic (`WindowGeometry`, `SnapAction` registry, settings store, shortcut map, drag zones, `SnapController`) and the `WindowProvider`/`ScreenProvider` protocols with mocks.
- `Sources/Snapr`: macOS app (AX and NSScreen providers, Carbon hotkeys, event-tap drag monitor, SwiftUI menu/settings).
