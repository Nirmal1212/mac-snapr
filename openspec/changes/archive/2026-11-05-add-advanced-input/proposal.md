## Why
Core drag snapping only offers edge/corner halves, quarters and maximize with fixed sensitivity. Power users need more zones, control over when and how snapping triggers, display-movement rules, and triggers beyond the keyboard.

## What Changes
- Drag-snap zones: bottom thirds, two-thirds between zones, half zones beside corners, opt-in sixths; per-zone enable; required modifier key
- Drag-snap look and feel: edge/corner margins, footprint alpha/border/color/blur, animated placement, optional guard against Mission Control when dragging above the menu bar
- Display rules: order displays by x coordinate, keep size when moving a maximized window, repeat last action on the other display, move cursor with window
- Other triggers: middle/extra mouse-button shortcuts (optionally on the window under the pointer), double-click title bar to maximize/restore
- Settings UI section for all of the above

## Impact
- Affected specs: drag-snap-tuning, display-rules, extra-triggers (all new)
- Affected code: `DragZones`, `DragSnapMonitor`, `PreviewOverlay`, `SnapController`, `ScreenGeometry`, settings keys (new `InputSettings.swift`), new monitors, settings view
- No new `SnapAction` cases
