## Why
Snapr is distributed as a notarized DMG, but users have no way to learn about new versions and installing requires a manual download. Sparkle auto-update and a Homebrew cask close that gap with minimal code.

## What Changes
- Sparkle 2 auto-update: "Check for Updates…" menu item, automatic-check setting, EdDSA-signed appcast
- `scripts/package.sh` embeds `Sparkle.framework`, fixes the rpath and signs inside-out
- Appcast generation script and release documentation (keys are never committed)
- Homebrew cask template and a script that renders it for a release
- Update checks are the only network access; they can be turned off

## Impact
- Affected specs: updates, distribution (new). Relaxes the "no network" Privacy requirement from `add-window-management` (menu-bar-app) to "no network except update checks"
- Affected code: `Package.swift` (Sparkle dependency, approved), `Sources/Snapr` (updater wrapper, menu item, settings toggle), `Sources/SnaprCore/Settings.swift` (new key), `scripts/`, `packaging/`, `docs/releasing.md`, CI release step
- Shared-file edits: `SettingKey` extension, `MenuContent` in SnaprApp.swift, `SettingsView` General section
