# Rectangle feature map → OpenSpec changes

Source: rectangleapp.com, the Rectangle GitHub README and TerminalCommands.md. Default shortcuts and the full Settings UI were not on those pages, so they are not listed. Rectangle Pro-style features are included in scope.

## Changes (6, in suggested order)

| # | Change ID | Theme |
|---|-----------|-------|
| 0 | `add-window-management` (existing) | v1 core |
| 1 | `add-layout-engine` | Every layout, sizing, repeat-cycling, gaps |
| 2 | `add-advanced-input` | Drag-snap tuning, display rules, mouse and title-bar triggers |
| 3 | `add-multi-window-modes` | Tiling, cascade, stacking, Todo, Stage Manager |
| 4 | `add-automation-and-config` | Ignore apps, URL scheme, config import/export, hidden prefs |
| 5 | `add-custom-layouts-and-spaces` | Pro-style: custom zones and moving between Spaces |
| 6 | `add-distribution` | Updates and Homebrew (notarization stays in 0) |

## Coverage

### 0. `add-window-management` (existing)
- Halves, quarters, basic thirds, maximize, center, restore
- Configurable global shortcuts, conflict detection, recorder
- Next / previous display
- Drag-to-edge snap with preview: top = maximize, sides = halves, corners = quarters, master toggle
- Menu bar app, settings window, launch at login, Accessibility onboarding
- DMG and notarization

### 1. `add-layout-engine`
Pure geometry plus the rules that modify it; fits the `WindowGeometry` unit-test convention.
- **Layouts:** fourths and three-fourths; sixths; eighths; ninths; corner two-thirds; vertical eighths and sixths; center half; center prominently; almost maximize (default 90%); maximize height; portrait-aware thirds
- **Sizing and moving:** larger / smaller (30 pt step, min-size limit); move left/right/up/down without resizing; double or halve width/height; specified centered size
- **Fit handling:** windows that can't reach the target align to edge or corner; "minimum size reached" HUD
- **Repeat behavior:** repeated halves/quarters cycle 1/2 → 2/3 → 1/3; repeated side action goes to adjacent display; quadrant-position cycling; opposite-side switch; repeated maximize restores; halves keep other-axis size (Windows/KDE style)
- **Gaps:** gap between windows; per-edge screen gaps; notch-aware top gap; main-screen-only; per-action gap exemption; full height when menu bar is hidden
- **Restore:** unsnap restores the previous size

### 2. `add-advanced-input`
- **Drag-snap zones:** bottom-third zones; drag between zones for two-thirds; half zones beside corners; opt-in sixths; enable/disable each zone; modifier key required to snap
- **Drag-snap look and feel:** margins; snap before reaching edge; footprint blur, alpha, border, color; animate windows; no Mission Control trigger when dragging above the menu bar
- **Display rules:** order displays by x coordinate; keep size when moving a maximized window; repeat last action on the other display; move cursor with window
- **Other triggers:** middle/extra mouse-button shortcuts (with modifiers, optionally acting on the window under the pointer); double-click title bar to maximize/restore

### 3. `add-multi-window-modes`
- Tile all, tile active app, tile in rows / columns (max per row/column, balanced grids)
- Cascade all, cascade active app
- Cycle stacked windows forward/back, same-size option, overlap offset, stack badge
- Reverse all
- Combined-display mode
- Todo mode (reserved sidebar, others tile beside it)
- Stage Manager strip awareness
- Apply an action to every new window

### 4. `add-automation-and-config`
- Ignore app (shortcuts off while it is frontmost)
- URL scheme `snapr://execute-action?name=…` plus ignore/unignore tasks
- JSON config import/export, loaded on launch
- Hidden preferences via `defaults write`
- Spectacle-compatible shortcut preset and restore defaults
- Debug logging viewer
- Enhanced-UI handling and a native-resize app list

### 5. `add-custom-layouts-and-spaces`
- Custom zones: shortcuts for any size and position
- Layout persistence: save and recall window arrangements
- Move a window to another Space (next / previous / numbered)

### 6. `add-distribution`
- Sparkle auto-update
- Homebrew cask

## Decisions needed before accepting
- **Spaces (change 5):** macOS has no public API for moving windows between Spaces. It needs private APIs or synthesized input, which conflicts with the design decision "Accessibility API over private APIs" and may break between macOS releases. Put this in its own design section, or split it out as a separate change if you want to ship the rest of change 5 without it.
- **Order:** change 1 is the best next step. Changes 2–4 are independent of each other once 1 lands. Change 5 should come last.
