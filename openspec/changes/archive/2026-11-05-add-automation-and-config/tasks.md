## 1. Core
- [x] 1.1 `AutomationURL` parser (execute-action, ignore-app, unignore-app) with tests
- [x] 1.2 `ignoredApps` setting and `HiddenPreferences` with tests
- [x] 1.3 `ConfigDocument` import/export, tolerant decoding, with tests
- [x] 1.4 Spectacle preset and restore defaults with tests
- [x] 1.5 `DebugLog` ring buffer with tests

## 2. App
- [x] 2.1 Ignore frontmost app: menu item, settings list, hotkey suspension while ignored
- [x] 2.2 URL handler (Apple Event) and Info.plist URL scheme in package script
- [x] 2.3 Config import/export UI and load on launch
- [x] 2.4 Settings: Spectacle preset button, restore defaults, debug log viewer
- [x] 2.5 Enhanced-UI handling and native-resize list in `AXWindowProvider`

## 3. Verify
- [x] 3.1 `openspec validate add-automation-and-config --strict`, `swift build`, `swift test`
