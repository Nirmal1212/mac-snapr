## 1. Sparkle Integration
- [ ] 1.1 Add Sparkle SwiftPM dependency to the `Snapr` target
- [ ] 1.2 `UpdateChecking` protocol, `UpdaterConfig` and `automaticUpdateChecks` setting in SnaprCore with unit tests
- [ ] 1.3 `SparkleUpdater` adapter (disabled when bundle lacks feed URL/public key)
- [ ] 1.4 "Check for Updates…" menu item and automatic-check toggle in Settings

## 2. Packaging
- [ ] 2.1 `package.sh`: embed `Sparkle.framework`, add rpath, sign inside-out, write Sparkle Info.plist keys from env
- [ ] 2.2 `make-appcast.sh` wrapper for `generate_appcast`
- [ ] 2.3 CI release step passes env/secrets (no keys committed)
- [ ] 2.4 Verify packaged app launches with embedded framework and passes `codesign --verify --strict`

## 3. Homebrew
- [ ] 3.1 Cask template and `render-cask.sh`
- [ ] 3.2 Validate rendered cask syntax (`ruby -c`)

## 4. Docs
- [ ] 4.1 `docs/releasing.md` (key generation, signing, notarization hook, appcast, cask)
- [ ] 4.2 README: updates, Homebrew install, privacy wording
