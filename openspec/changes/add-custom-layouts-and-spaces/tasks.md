## 1. Core: models and runtime actions
- [ ] 1.1 `CustomZone`, `SavedLayout` models with validation, tolerant decoding, settings keys, `CustomLayoutStore`, with tests
- [ ] 1.2 `RuntimeAction` names, parsing and id validation with tests
- [ ] 1.3 `RuntimeActionRunner` (zones, layouts) and `ArrangementPlanner`/capture with tests

## 2. Config and automation
- [ ] 2.1 `ConfigDocument` custom zones and saved layouts (round trip, tolerant, shortcut validation) with tests
- [ ] 2.2 `AutomationRouter` runtime names via `AutomationHost` with tests

## 3. Spaces
- [ ] 3.1 `SpaceMoving` protocol, `SpaceActionController`, `spacesEnabled` flag (default off) with tests
- [ ] 3.2 `PrivateSpaceMover` (dlsym, no SIP changes, verified, no-op when unavailable)

## 4. App
- [ ] 4.1 `HotkeyManager` runtime bindings, `AppModel` wiring, `AXWindowLister`
- [ ] 4.2 Menu entries and Settings section (zones editor, saved layouts, experimental Spaces toggle)

## 5. Verify
- [ ] 5.1 `openspec validate add-custom-layouts-and-spaces --strict`, `swift build`, `swift test`
