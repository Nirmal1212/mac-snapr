## Context
Builds on `LayoutEngine` (usable area, gaps, pixel alignment) and `SnapController`. Multi-window actions operate on a list of windows rather than the focused one.

## Decisions
- **New logic in new files.** Pure planning lives in `MultiWindowPlanner` (grid, cascade, stack, reverse; unit tested). `MultiWindowController` executes plans through protocols. `SnapController` is not modified.
- **Routing.** `SnapAction.isMultiWindow` marks the new actions. `AppModel.perform` sends them to `MultiWindowController`; everything else goes to `SnapController`. The URL scheme needs no change because `AutomationRouter` resolves names through `ActionRegistry`.
- **Window listing** is a separate `WindowListProvider` protocol (`allWindows()` front-to-back, `raise(_:)`), so `WindowProvider` and its mocks stay unchanged. Frames are applied through the existing `WindowProvider.setFrame`.
- **Usable area** per screen is `LayoutEngine.area` (screen gaps, notch) minus reserved areas (`ReservedAreas`): the Stage Manager strip and the Todo sidebar. The window gap is applied between tiles and pixel alignment uses `LayoutEngine.pixelAligned`, so neighbouring tiles share exact edges.
- **Reserved areas for every action.** `ReservedScreenProvider` decorates `ScreenProvider` and shrinks `visibleFrame`, so ordinary snap actions also avoid the Stage Manager strip and the Todo sidebar with no change to `SnapController`.
- **Stage Manager strip width** has no public API. The width is a setting (default 190 pt, left side); the strip only applies while Stage Manager is enabled (`com.apple.WindowManager` `GloballyEnabled`, read by the app).
- **Todo mode:** the Todo app is a bundle id (set from the frontmost window when toggled on and none is configured). The sidebar (width, left/right) is reserved on one screen (the screen chosen when enabling, else the primary). Todo-app windows are placed in the sidebar by tile/cascade/stack/reflow; other windows use the remaining area.
- **Combined-display mode:** windows are distributed over all screens proportionally to usable area (screens ordered by x, windows by position) and each screen is laid out on its own; off means only the active window's screen.
- **Grid:** balanced means the last row/column stretches to fill; `maxPerRow`/`maxPerColumn` 0 means unlimited. Tile all uses the column count whose cells are closest to the screen aspect ratio.
- **Stack:** the active screen's windows are placed with `stackOffset` steps (optionally one common size); Stack Next/Previous rotate the order, re-place the windows and raise them back to front. A stack badge (index/count) is reported through a callback and shown as a HUD.
- **Reverse:** windows are ordered by position (reading order); window i receives the frame of window n-1-i.
- **New-window action:** `NewWindowMonitor` diffs window ids between scans; the first scan only records a baseline. The app scans on a 1 s timer that runs only while the option is set.
- **Window order:** `allWindows()` lists the frontmost app first. Tiling sorts by position so repeated runs are stable.

## Security
- `snapr://` URLs can be opened by any web page. `toggle-todo` and `reflow-todo` persist state (Todo mode on, Todo app = frontmost app) and are therefore refused by `AutomationRouter` (`.refused`, via `SnapAction.isURLRestricted`); the menu and hotkeys still run them. The other multi-window actions only move windows and stay reachable.
- The new-window action may not be a multi-window action. Config import sanitizes `newWindowAction` (must exist in `ActionRegistry`, not multi-window) and `todo.bundleID` (valid bundle id) before storing.
- `NewWindowMonitor` keeps seen window ids (bounded to 2000, least recently seen evicted), so unminimized, unhidden or Space-switched windows are not mistaken for new ones.
- `ReservedScreenProvider` caches the decoded options (invalidated on settings change) and the Stage Manager preference (2 s), since it runs on every drag event. The AX element cache is pruned past 500 entries.

## Risks / Trade-offs
- AX window listing across apps is slower than the focused-window path; only user-triggered actions and the opt-in new-window timer use it.
- Stage Manager strip width is user-configured, not detected.
- Minimized, full-screen and non-standard windows are skipped.

## Open Questions
- None.
