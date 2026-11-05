## 1. Signing and notarization
- [ ] 1.1 Choose the real bundle identifier and replace `com.you.snapr` (package.sh default, docs, config paths)
- [ ] 1.2 Developer ID signing in `scripts/package.sh` with hardened runtime; verify Sparkle components share the Team ID
- [ ] 1.3 Notarize with `notarytool` and staple the DMG; credentials via keychain profile or CI secrets only
- [ ] 1.4 Release workflow: notarized DMG attached to the GitHub Release on `v*` tags
- [ ] 1.5 Update README, `site/` and `docs/releasing.md` install steps (Gatekeeper workaround no longer needed)

## 2. Screenshots and appearance
- [ ] 2.1 Capture screenshots: menu popover (intro and actions), Settings with search, drag-to-snap preview
- [ ] 2.2 Add them to README and the landing page (and an `og:image`)
- [ ] 2.3 Check Settings window and popover in light and dark appearance
