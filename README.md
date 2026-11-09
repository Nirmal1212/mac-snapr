# Snapr

Free, native macOS menu bar app for Windows-style window snapping: snap windows to halves, quarters, thirds and more with keyboard shortcuts or by dragging to a screen edge. Fully local, no telemetry.

> Status: public beta (`0.1.0-beta.2`). Download the DMG from the [Releases page](https://github.com/Nirmal1212/mac-snapr/releases), or build from source (see [Build](#build)). Website: https://nirmal1212.github.io/mac-snapr/

Requirements: macOS 13 (Ventura) or later, and Accessibility permission (macOS only lets an app move other apps' windows through the Accessibility API).

## Features
- **Layouts:** halves, quarters, thirds and two-thirds, fourths, sixths, eighths, ninths, corner two-thirds, center and almost-maximize, maximize, restore; larger/smaller, move without resizing, double/halve.
- **Shortcuts:** global shortcuts with conflict detection and a recorder, a Spectacle-compatible preset, restore defaults.
- **Drag to snap:** drag to an edge or corner with a preview; tune zones, modifier key, margins and footprint.
- **Displays:** next/previous display, keep size, repeat on the other display.
- **Gaps:** gaps between windows and around screen edges, notch-aware.
- **Multiple windows:** tile (all, rows, columns, active app), cascade, stack cycling, Todo sidebar, Stage Manager awareness, an action for every new window.
- **Custom layouts:** your own zones with shortcuts, saved window arrangements, and an experimental, off-by-default move between Spaces (private APIs).
- **Automation:** `snapr://` URLs, JSON config import/export, ignored apps, hidden preferences.
- **Settings:** a sidebar with search, and a short intro in the menu bar popover on first launch.

## Usage
Snapr lives in the menu bar (no Dock icon). Open the menu for every action, use a shortcut, or drag a window to a screen edge.

| Action | Default shortcut |
|--------|------------------|
| Left / Right / Top / Bottom half | Ctrl+Opt+Arrow |
| Top-left / top-right / bottom-left / bottom-right quarter | Ctrl+Opt+U / I / J / K |
| Left / center / right third | Ctrl+Opt+D / F / G |
| Left / right two thirds | Ctrl+Opt+E / T |
| Maximize / Center / Restore | Ctrl+Opt+Return / C / Delete |
| Maximize height | Ctrl+Opt+Shift+Up |
| Larger / Smaller | Ctrl+Opt+= / - |
| Next / previous display | Ctrl+Opt+Cmd+Right / Left |

Most other actions ship unbound; assign them in Settings > Shortcuts.

- Pressing Left/Right Half repeatedly cycles 1/2, 2/3, 1/3 width (Rectangle order; switch to 1/2, 1/3, 2/3 in Settings > Layout).
- Drag a window to the left/right edge for a half, the top edge to maximize, or a corner for a quarter; a preview shows the target.
- Rebind or clear shortcuts in Settings, toggle drag snapping, and enable launch at login. Use the search field in Settings to find any option.

### Automation
```bash
open "snapr://execute-action?name=left-half"                  # run any action by name
open "snapr://ignore-app?bundle-id=com.apple.Safari"          # ignore / unignore need an explicit bundle id
```
Action names match the registry (kebab-case, e.g. `left-half`, `tile-all`). Settings can be exported and imported as JSON in Settings > Configuration; `~/Library/Application Support/Snapr/config.json` is loaded at launch if present. Advanced options are available with `defaults write` (see `openspec/specs/hidden-preferences/spec.md`).

Screenshots: not yet captured; see the website for illustrations of the layouts.

## Install
1. Download `Snapr-<version>.dmg` from the Releases page and drag Snapr to Applications.
2. Releases are not yet notarized, so macOS blocks the first launch. On macOS 13/14 right-click Snapr.app and choose Open. On macOS 15 Sequoia and later, try opening it, then use System Settings > Privacy & Security > "Open Anyway". Or run `xattr -dr com.apple.quarantine /Applications/Snapr.app`.
3. Grant Accessibility access when prompted (System Settings > Privacy & Security > Accessibility). Beta builds are ad-hoc signed, so after each update remove Snapr from that list and add it again.

Homebrew (`brew install --cask snapr`) is planned once a tap is published; the cask template is `packaging/homebrew/snapr.rb.template`.

## Updates
Releases built with a feed URL and Sparkle public key can check for updates and offer "Check for Updates…"; Sparkle asks permission before checking automatically, and automatic checks can be turned off in Settings. Dev builds (`swift run`) have updates disabled. Maintainer steps (keys, signing, appcast, cask): [docs/releasing.md](docs/releasing.md).

## Build
Requirements: Xcode 15+ or Swift 5.9+ toolchain on macOS 13+.
```bash
swift run                 # run from source (Accessibility is granted to your terminal)
scripts/package.sh        # builds dist/Snapr.app (Sparkle embedded) and dist/Snapr-<version>.dmg
```
`scripts/package.sh` signs ad-hoc unless `SIGN_IDENTITY` is set. Ad-hoc signatures change on every build, so macOS drops the Accessibility grant after each rebuild: reset it with `tccutil reset Accessibility <bundle id>` and grant it again.

## Project layout
- `Sources/SnaprCore`: pure, unit-tested logic (geometry and layouts, the `SnapAction` registry, settings and search index, shortcuts, drag zones, `SnapController`, multi-window planning, custom layouts, automation) and the `WindowProvider`/`ScreenProvider` protocols with mocks.
- `Sources/Snapr`: the macOS app (Accessibility and NSScreen providers, Carbon hotkeys, event taps, SwiftUI popover and settings, Sparkle).
- `Tests/SnaprCoreTests`: unit tests.
- `openspec/`: specifications (`specs/`) and in-flight changes (`changes/`), managed with [OpenSpec](https://github.com/Fission-AI/OpenSpec).
- `site/`: the single-page website. `assets/branding/`: logo and icon sources. `docs/`: release guide and agent notes.

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for the Git Flow branching model, the OpenSpec workflow, and the checks CI runs.

## License
[MIT](LICENSE)
