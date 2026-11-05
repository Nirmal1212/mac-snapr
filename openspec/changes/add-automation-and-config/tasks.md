## 1. Core
- [ ] 1.1 `AutomationURL` parser (execute-action, ignore-app, unignore-app) with tests
- [ ] 1.2 `ignoredApps` setting and `HiddenPreferences` with tests
- [ ] 1.3 `ConfigDocument` import/export, tolerant decoding, with tests
- [ ] 1.4 Spectacle preset and restore defaults with tests
- [ ] 1.5 `DebugLog` ring buffer with tests

## 2. App
- [ ] 2.1 Ignore frontmost app: menu item, settings list, hotkey suspension while ignored
- [ ] 2.2 URL handler (Apple Event) and Info.plist URL scheme in package script
- [ ] 2.3 Config import/export UI and load on launch
- [ ] 2.4 Settings: Spectacle preset button, restore defaults, debug log viewer
- [ ] 2.5 Enhanced-UI handling and native-resize list in `AXWindowProvider`

## 3. Verify
- [ ] 3.1 `openspec validate add-automation-and-config --strict`, `swift build`, `swift test`
