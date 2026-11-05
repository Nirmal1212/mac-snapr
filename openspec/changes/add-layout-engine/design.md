## Context
Builds on `add-window-management`: closed `SnapAction` enum + `ActionRegistry`, pure `WindowGeometry`, typed `SettingsStore`, `ShortcutMap` (overrides only), `SnapController` with `WindowProvider`/`ScreenProvider` mocks.

## Decisions
- **Layouts are a catalog, not code per case.** `LayoutCatalog` (own file) maps each new `SnapAction` to a grid cell (`cols`, `rows`, `col`, `row`, spans), title, category and optional default shortcut. `SnapAction.title/category`, `DefaultShortcuts.combo` and `WindowGeometry.frame` each get one grouped block (marked `add-layout-engine`) that delegates to the catalog, so parallel changes add their own cases without touching mine.
- **Closed enum stays.** Each layout is its own `SnapAction` case (CaseIterable, string raw value) so menu, shortcuts and settings pick them up with no per-action UI.
- **One options value.** `LayoutOptions` (Codable, tolerant decoding with per-field defaults) is stored under a single `SettingKey` (`layoutOptions`); `SnapController` reads it through a closure so changes apply immediately. `ShortcutMap` format is untouched; new actions are unbound or take defaults, and old data decodes unchanged.
- **Pipeline.** `LayoutEngine.target` = usable area (visible frame, then notch and screen gaps) → `WindowGeometry.frame` → window gap. `SnapController` adds repeat state, fit handling and restore.
- **Concrete shapes.**
  - Sixths 3x2, vertical sixths 2x3, eighths 4x2, vertical eighths 2x4, ninths 3x3.
  - Corner two-thirds = 2/3 width x 2/3 height anchored in a corner.
  - Center half = 1/2 width, full height. Center prominently = 70% x 85%. Almost maximize = configurable fraction, default 90%, centered.
  - Portrait-aware thirds (default on): on a screen taller than wide, left/center/right thirds and two-thirds become top/middle/bottom.
  - Larger/smaller grow or shrink about the window center by `resizeStep` (30 pt) per axis, clamped to the usable area and a minimum window size. Move left/right/up/down slides the window to that edge of the usable area without resizing. Double/halve keep the window's left/top and clamp into the usable area.
- **Repeat cycle order is a setting** (`HalfCycleOrder`: `.rectangle` 1/2 → 2/3 → 1/3 default, `.spec` 1/2 → 1/3 → 2/3). Rectangle's order is the default because users migrating expect it; this supersedes the core spec scenario.
- **Repeat behaviors** (in `SnapController`, keyed on "window still where we left it"): repeated left/right half either cycles sizes or moves to the adjacent display (`RepeatBehavior`, not wrapping; falls back to cycling at the last display); quadrant cycling rotates a repeated quarter clockwise TL → TR → BR → BL; opposite-side switch keeps the current width when left/right half is followed by the other side; repeated maximize restores; "halves keep other axis" makes left/right half retain the window's y/height and top/bottom keep x/width.
- **Fit handling.** `LayoutEngine.fit` anchors a window larger than the target to the edge or corner the target touches, then clamps into the usable area. The controller raises `onMinimumSizeReached(target, actual)`; the app shows a brief HUD.
- **Gaps.** Screen gaps inset the usable area per edge. Window gap shrinks each snapped frame by half the gap on sides that do not touch the usable-area edge, so neighbours end up exactly one gap apart. Options: main screen only (the screen whose frame origin is (0,0)), per-action exemptions (stored by action name), notch-aware top gap (top of usable area is at least the screen's safe-area inset), and "full height when menu bar hidden" (no top screen gap when the menu bar is hidden on a non-notched screen). Only region layouts (halves, quarters, thirds, grid layouts) get the window gap; sizing/moving and center actions get screen gaps only.
- **Unsnap restore.** The drag monitor, on the first move of a window the controller considers snapped, calls `SnapController.unsnap` to restore the pre-snap size, keeping the cursor at the same relative position. Pure math in `LayoutEngine.unsnapped`.
- **Screen notch data.** `ScreenInfo.safeAreaTop` (default 0) is filled from `NSScreen.safeAreaInsets.top`.

## Risks / Trade-offs
- ~60 new enum cases make the menu and shortcut list long; the menu groups categories into submenus.
- Changing the default cycle order alters existing behavior; mitigated by the setting.
- Quadrant cycling and adjacent-display repeat are off by default to avoid surprising current users.
- Unsnap hooks into the drag monitor, which `add-advanced-input` also edits; the hook is a few lines in `drag(_:at:)`.

## Open Questions
- Rectangle's exact "center prominently" proportions and move-to-edge vs. step semantics are approximated; adjust from user feedback.
