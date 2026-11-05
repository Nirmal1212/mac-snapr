## Why
Tasks 7.1 (notarization) and 7.3 (screenshots) were left open when `add-window-management` was archived, because the dependent changes needed its specs applied first. They need an Apple Developer ID and a Mac with the UI, so they are tracked here instead of being lost.

## What Changes
- Notarized, stapled DMG releases signed with a Developer ID (stable signature, so Accessibility grants survive updates)
- Real bundle identifier replacing the `com.you.snapr` placeholder
- README and landing page screenshots of the menu popover, settings window and drag-to-snap preview
- Light and dark appearance check of the Settings window (carried over from `add-settings-sidebar-and-intro` task 2.4)

## Impact
- Affected specs: release-readiness (new)
- Affected code: `scripts/package.sh` (notarization step), `.github/workflows/ci.yml`, `docs/releasing.md`, README, `site/`
- Needs: Apple Developer ID certificate and notarization credentials (never committed), a Mac for screenshots
