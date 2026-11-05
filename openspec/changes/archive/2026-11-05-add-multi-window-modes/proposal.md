## Why
Single-window snapping cannot arrange a whole workspace. Users want one shortcut that tiles, cascades or stacks many windows, keeps a sidebar app (Todo) beside the rest, respects the Stage Manager strip, and applies a layout to every new window.

## What Changes
- Tile all windows, tile the active app's windows, tile in rows or in columns (max per row/column, balanced grids), optional combined-display mode
- Cascade all windows, cascade the active app's windows
- Cycle stacked windows forward/back (same-size option, overlap offset, stack badge)
- Reverse all window positions
- Todo mode: a reserved sidebar for one app; all layouts use the remaining area
- Stage Manager awareness: the strip area is excluded from every layout
- Apply a chosen action to every new window
- New `SnapAction` cases (reachable through shortcuts, the menu and `snapr://execute-action` via `ActionRegistry`), settings, config import/export, settings UI

## Impact
- Affected specs: window-tiling, cascade-and-stack, reserved-areas, new-window-action (all new)
- Affected code: new `MultiWindow*.swift` files in `SnaprCore`; `SnapAction` (one `// MARK: add-multi-window-modes` block per switch), `ConfigDocument` (one new optional field), `AppModel` (routing, providers, new-window timer), AX provider (window listing), settings view
- Shared-file edits: `SnapAction`, `ConfigDocument`, `AppModel`, `SettingsView`, `SystemProviders`
