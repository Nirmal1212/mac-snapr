## Context
Builds on the `SnapAction` enum / `ActionRegistry`, typed `SettingKey` / `SettingsStore` and `ShortcutMap` from add-window-management.

## Decisions
- **URL actions via the registry**: the handler calls `ActionRegistry.action(named:)` only; it never switches over `SnapAction`, so actions added by other changes work automatically. Same for config shortcut names and the Spectacle preset (unknown names are skipped).
- **Pure parsing in Core**: `AutomationURL.parse(_:)` and `ConfigDocument` are pure and unit tested; AppKit glue (Apple Event URL handler, NSWorkspace observer) stays in the app target.
- **Ignore apps by bundle id**, stored in `SettingKey.ignoredApps`. While the frontmost app is ignored, global hotkeys are unregistered so the key press reaches that app. Drag snapping is unaffected.
- **Config JSON**: `{version, dragSnapEnabled, ignoredApps, nativeResizeApps, shortcuts: {action: {keyCode, modifiers} | null}}`. Decoding is field by field with `decodeIfPresent`; unknown keys are ignored, missing keys leave the current value untouched. Shortcut entries for unknown actions are dropped; `null` clears a shortcut. Auto-loaded from `~/Library/Application Support/Snapr/config.json` on launch if present.
- **Hidden prefs** are read natively from `UserDefaults` (`defaults write com.you.snapr <key> -bool|-array ...`) by `HiddenPreferences`, separate from the JSON-encoded `SettingsStore` values so `defaults write` works with plain types. Keys: `debugLogging` (bool), `enhancedUIHandling` (bool, default true), `nativeResizeApps` (array of bundle ids).
- **Spectacle preset** is a function producing a `ShortcutMap`: clears everything, then assigns Spectacle combos for actions that exist in the registry.
- **Debug log**: bounded in-memory ring buffer (`DebugLog`), no disk or network; records only when `debugLogging` is on.
- **Enhanced UI**: `AXWindowProvider.setFrame` temporarily clears `AXEnhancedUserInterface` on the owning app and restores it afterwards. **Native resize apps** skip the size-position-size sequence and set size then position once.

## Security
- `execute-action` is intentionally unauthenticated: any local process or web page can open a `snapr://` URL. It is acceptable because actions only move or resize the focused window and `restore` undoes them; nothing is destructive.
- URL-driven `ignore-app` / `unignore-app` require an explicit, validated `bundle-id` (`[A-Za-z0-9.-]`, at most 255 characters) and never default to the frontmost app, so a web page cannot silently disable Snapr for the browser. The menu item may still target the frontmost app. The ignored list is capped at 500 entries and logged URLs are truncated to 200 characters.
- Config import rejects key combos failing `KeyCombo.isValidGlobalShortcut` (same rule as the recorder).

## Risks / Trade-offs
- A URL scheme needs the packaged app (`Info.plist`); `swift run` cannot receive URLs.
- Unregistering hotkeys on app switch is slightly racy with very fast switching; acceptable.
- Shared-file edits are additive: no new `SnapAction` cases.

## Open Questions
- None.
