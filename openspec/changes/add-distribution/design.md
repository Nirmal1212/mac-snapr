## Context
Swift 5.9 SwiftPM menu bar app, built into a bundle by `scripts/package.sh` (no Xcode project), sandbox off, distributed outside the App Store. Core is merged.

## Decisions
- **Sparkle 2.x via SwiftPM** (approved third-party dependency), used only from the `Snapr` target. `SnaprCore` stays dependency-free.
- **Testable seam:** `UpdateChecking` protocol and `UpdaterConfig` (pure: is the bundle configured) live in `SnaprCore` with unit tests. `SparkleUpdater` in `Snapr` adapts `SPUStandardUpdaterController`.
- **Disabled when unconfigured:** `swift run` and dev builds have no `SUFeedURL`/`SUPublicEDKey`; the updater is not started and the menu item is disabled. Values are injected by `package.sh` from `SU_FEED_URL` and `SU_PUBLIC_ED_KEY`; if unset, the keys are omitted.
- **Consent:** `SUEnableAutomaticChecks` is not written to Info.plist, so Sparkle shows its own permission prompt before the first automatic check. Writing `automaticallyChecksForUpdates = true` in code would skip that prompt, so at startup the app only pushes the setting to Sparkle when it is off; a `true` is pushed only when the user flips the toggle.
- **Settings:** `automaticUpdateChecks` (Bool, default true) mirrors the Settings toggle.
- **Privacy:** update checks are the single, user-disableable network use. No system profiling, no telemetry. The `menu-bar-app` spec delta MODIFIES the existing "Privacy" requirement from `add-window-management`. It applies only once `add-window-management` is archived (its specs are not yet in `openspec/specs`), so archive that change first. Onboarding text and `openspec/project.md` are reworded to match.
- **Packaging:** SwiftPM links `Sparkle.framework` with an `@loader_path` rpath only, so `package.sh` adds `@executable_path/../Frameworks` via `install_name_tool`, copies the framework from the build artifacts (`ditto`, preserving symlinks), and signs inside-out: XPC services, `Autoupdate` and `Updater.app` inside the framework, then the framework, then the app. `--deep` is not used. The app is signed last with hardened runtime and no sandbox entitlements. The Info.plist is written before signing.
- **Universal build:** the Sparkle xcframework macOS slice is already universal.
- **Signing keys:** never generated or stored in the repo. The EdDSA private key lives in the maintainer's keychain (`generate_keys`) or a CI secret; only the public key goes into the build.
- **Appcast:** `scripts/make-appcast.sh` runs Sparkle's `generate_appcast` over a releases directory and writes `appcast.xml`; hosting URL is a placeholder.
- **Homebrew cask:** `packaging/homebrew/snapr.rb.template` with version, sha256 and URL placeholders, `auto_updates true`, `depends_on macos: ">= :ventura"`, `zap` paths. `scripts/render-cask.sh` fills it from a DMG. Publishing to a tap is manual.

## Risks / Trade-offs
- Notarization stays in change 0; Sparkle works best with a notarized Developer ID build. Ad-hoc builds are for testing only.
- Sparkle adds ~3 MB and XPC helpers; idle CPU/memory budget is unaffected (scheduled daily checks).

## Open Questions
- Final bundle id, appcast host and tap name (placeholders for now).
