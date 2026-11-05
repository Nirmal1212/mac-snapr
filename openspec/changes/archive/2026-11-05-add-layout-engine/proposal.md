## Why
The v1 core covers halves, quarters and basic thirds. Rectangle users expect many more layouts, keyboard resizing/moving, smarter repeated shortcuts, and gaps between windows. This change adds them as pure geometry plus a small set of settings.

## What Changes
- Layouts: fourths and three-fourths, sixths (landscape and vertical), eighths (landscape and vertical), ninths, corner two-thirds, center half, center prominently, almost maximize, maximize height; portrait-aware thirds
- Sizing and moving: larger/smaller (30 pt step, minimum size), move without resizing, double/halve width and height, specified centered size
- Fit handling: windows that cannot reach the target align to the target's edge or corner; "Minimum size reached" HUD
- Repeat behavior: configurable half cycle order (default Rectangle's 1/2 → 2/3 → 1/3; the core spec's 1/2 → 1/3 → 2/3 stays available), side action to adjacent display, quadrant cycling, opposite-side switch, repeated maximize restores, halves keeping the other axis
- Gaps: window gap, per-edge screen gaps, notch-aware top gap, main-screen-only, per-action exemption, full height when the menu bar is hidden
- Unsnap restores the previous size when a snapped window is dragged away

## Impact
- Affected specs: window-layouts, window-sizing, repeat-behavior, window-gaps (new); window-snapping (modified: Cycle Sizes)
- Affected code: `SnapAction` (new cases), `WindowGeometry`, `SnapController`, `Settings`, `Shortcuts` defaults, `ScreenInfo` (notch inset), `DragZones` (gap-aware preview), settings and menu UI, drag monitor (unsnap)
- Behavior change: default repeat cycle order for halves is now 1/2 → 2/3 → 1/3 (was 1/2 → 1/3 → 2/3); selectable in Settings
