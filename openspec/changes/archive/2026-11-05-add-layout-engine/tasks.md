## 1. Shared Plumbing
- [x] 1.1 Add `SnapAction` cases in one grouped block and update the four exhaustive switches (`title`, `category`, `DefaultShortcuts.combo`, `WindowGeometry.frame`) with one grouped `add-layout-engine` block each, delegating to `LayoutCatalog`
- [x] 1.2 Add `ActionCategory` cases (fourths, sixths, eighths, ninths, sizing)
- [x] 1.3 `LayoutOptions` + `SettingKey.layoutOptions` with tolerant decoding (old/partial data keeps defaults)
- [x] 1.4 Test that `ShortcutMap` data saved before this change still decodes and keeps its bindings; new actions get defaults or stay unbound without default conflicts

## 2. Layouts
- [x] 2.1 `LayoutCatalog` grid cells: fourths and three-fourths, sixths, vertical sixths, eighths, vertical eighths, ninths, corner two-thirds
- [x] 2.2 Center half, center prominently, almost maximize (configurable fraction), maximize height
- [x] 2.3 Portrait-aware thirds and two-thirds
- [x] 2.4 Unit tests for every layout (tiling coverage, exact rects)

## 3. Sizing and Moving
- [x] 3.1 Larger / smaller with step (default 30 pt) and minimum window size
- [x] 3.2 Move left/right/up/down without resizing
- [x] 3.3 Double / halve width and height
- [x] 3.4 Specified centered size (setting)
- [x] 3.5 Unit tests

## 4. Fit Handling
- [x] 4.1 `LayoutEngine.fit`: align to the target's edge/corner when the window can't reach the target size
- [x] 4.2 `SnapController.onMinimumSizeReached` callback and app HUD
- [x] 4.3 Unit tests (min-size mock, corner anchoring)

## 5. Repeat Behavior
- [x] 5.1 Repeat-cycle order setting (`HalfCycleOrder`): default Rectangle's 1/2 → 2/3 → 1/3, alternate core-spec order 1/2 → 1/3 → 2/3; update existing core tests and the core cycle scenario
- [x] 5.2 Repeated side action moves to adjacent display (option)
- [x] 5.3 Quadrant-position cycling (option)
- [x] 5.4 Opposite-side switch keeps width (option)
- [x] 5.5 Repeated maximize restores (option)
- [x] 5.6 Halves keep the other axis (option)
- [x] 5.7 Unit tests for each

## 6. Gaps
- [x] 6.1 Window gap and per-edge screen gaps
- [x] 6.2 Notch-aware top gap (`ScreenInfo.safeAreaTop` from `NSScreen`)
- [x] 6.3 Main-screen-only, per-action exemption, full height when menu bar hidden
- [x] 6.4 Drag-snap preview uses the same gap-aware target
- [x] 6.5 Unit tests

## 7. Restore
- [x] 7.1 Unsnap restores the previous size (pure math + `SnapController.unsnap` + drag monitor hook, option)
- [x] 7.2 Unit tests

## 8. UI and Docs
- [x] 8.1 Menu: category submenus
- [x] 8.2 Settings: layout, repeat, sizing and gap options
- [x] 8.3 `swift build`, `swift test`, `openspec validate add-layout-engine --strict`
