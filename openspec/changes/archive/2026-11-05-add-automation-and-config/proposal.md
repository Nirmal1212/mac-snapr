## Why
Power users need to automate Snapr and tailor it without the UI: disable shortcuts in some apps, drive actions from scripts, share configuration, and work around misbehaving apps.

## What Changes
- Ignore apps: shortcuts are off while an ignored app is frontmost
- `snapr://` URL scheme: `execute-action`, `ignore-app`, `unignore-app`; actions resolved through `ActionRegistry`
- JSON config import/export (tolerant of unknown and missing keys), auto-loaded on launch
- Hidden preferences settable with `defaults write`
- Spectacle-compatible shortcut preset and restore defaults
- In-memory debug log with a viewer window
- Enhanced-UI handling and a native-resize app list

## Impact
- Affected specs: ignored-apps, url-scheme, config-import-export, hidden-preferences, shortcut-presets, debug-logging, window-compatibility (all new)
- Affected code: new `SnaprCore` files (automation, config, presets, log); `AppModel`, `SnaprApp`, `SettingsView`, `AXWindowProvider`, `scripts/package.sh` (URL scheme registration)
- Depends on: add-window-management
