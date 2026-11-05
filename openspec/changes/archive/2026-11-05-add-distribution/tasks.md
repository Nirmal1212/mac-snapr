## 1. Sparkle Integration
- [x] 1.1 Add Sparkle SwiftPM dependency to the `Snapr` target
- [x] 1.2 `UpdateChecking` protocol, `UpdaterConfig` and `automaticUpdateChecks` setting in SnaprCore with unit tests
- [x] 1.3 `SparkleUpdater` adapter (disabled when bundle lacks feed URL/public key)
- [x] 1.4 "Check for Updates…" menu item and automatic-check toggle in Settings

## 2. Packaging
- [x] 2.1 `package.sh`: embed `Sparkle.framework`, add rpath, sign inside-out, write Sparkle Info.plist keys from env
- [x] 2.2 `make-appcast.sh` wrapper for `generate_appcast`
- [x] 2.3 CI release step passes env/secrets (no keys committed)
- [x] 2.4 Verify packaged app launches with embedded framework and passes `codesign --verify --strict`

## 3. Homebrew
- [x] 3.1 Cask template and `render-cask.sh`
- [x] 3.2 Validate rendered cask syntax (`ruby -c`)

## 4. Docs
- [x] 4.1 `docs/releasing.md` (key generation, signing, notarization hook, appcast, cask)
- [x] 4.2 README: updates, Homebrew install, privacy wording
