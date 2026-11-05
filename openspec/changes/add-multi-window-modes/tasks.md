## 1. Models and Settings
- [ ] 1.1 `MultiWindowOptions` (tolerant decoding), setting key, config import/export field
- [ ] 1.2 `SnapAction` cases, titles, category, `isMultiWindow`

## 2. Pure Planning
- [ ] 2.1 Grid/rows/columns (max per row/column, balanced) with unit tests
- [ ] 2.2 Cascade, stack, reverse planners with unit tests
- [ ] 2.3 Reserved areas (Stage Manager strip, Todo sidebar) and `ReservedScreenProvider` with unit tests
- [ ] 2.4 Combined-display distribution with unit tests

## 3. Execution
- [ ] 3.1 `WindowListProvider` protocol and mock
- [ ] 3.2 `MultiWindowController` (tile, cascade, stack cycling, reverse, Todo toggle/reflow) with tests
- [ ] 3.3 `NewWindowMonitor` with tests

## 4. App Integration
- [ ] 4.1 AX `WindowListProvider`, routing in `AppModel`, reserved-area screen decorator
- [ ] 4.2 Stack badge and new-window timer
- [ ] 4.3 Settings section

## 5. Verification
- [ ] 5.1 `openspec validate --all --strict`, `swift build`, `swift test`
