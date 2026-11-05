## Why
The built-in layouts cover fixed grids. Power users want zones of any size and position bound to their own shortcuts, saved window arrangements they can recall, and a way to send a window to another Space.

## What Changes
- Custom zones: user-defined rectangles (fractions of the usable screen area) with optional global shortcuts, menu entries and URL access
- Saved layouts: capture the arrangement of open windows and re-apply it later (matched by app bundle id and title)
- Runtime actions: a small `RuntimeAction` mechanism (custom zone, saved layout, Space move) next to the closed `SnapAction` enum, with shortcut bindings, menu entries and `snapr://execute-action?name=` support
- Config import/export carries custom zones and saved layouts, tolerant of unknown keys, shortcuts validated with `isValidGlobalShortcut`
- Move window to next / previous / numbered Space: experimental, default OFF, behind a protocol, no-op when unavailable

## Impact
- Affected specs: custom-zones, saved-layouts, runtime-actions, spaces (all new)
- Affected code: new `SnaprCore` files (`CustomLayouts`, `RuntimeAction`, `Arrangements`, `Spaces`); `ConfigDocument` (additive fields), `AutomationRouter`/`AutomationHost` (runtime names), `HotkeyManager`, `AppModel`, `SnaprApp` menu, `SettingsView`, `AXWindowProvider` (element accessor)
- No new `SnapAction` cases and no `SnapController` edits (custom frames go through the existing `snap(_:toFrame:screen:)`)
- Depends on: add-layout-engine
