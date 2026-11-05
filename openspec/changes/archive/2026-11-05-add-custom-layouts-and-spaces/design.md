## Context
`SnapAction` is a closed enum (see add-window-management): menu, shortcuts, config and URLs iterate `ActionRegistry`. Custom zones and saved layouts are defined at run time, so they cannot be enum cases.

## Decisions
- **Runtime actions beside the enum**: `RuntimeAction` is a small value type (`zone(id)`, `layout(id)`, `space(target)`) with a stable string name (`custom:<id>`, `layout:<id>`, `space:next|previous|<n>`). `RuntimeAction.parse(_:)` validates ids (`[a-z0-9-]`, 1...64 characters). `SnapAction` and `ActionRegistry` are untouched, which keeps this change independent of the parallel multi-window work.
- **Own bindings**: shortcuts for runtime actions live on the zone / layout itself (`KeyCombo?`) rather than in `ShortcutMap`, whose keys are `SnapAction` names. `CustomLayoutStore.bindings` lists them; `HotkeyManager.register(_:runtime:)` registers them with ids offset from the built-in ones. Conflicts with built-in shortcuts and between runtime items are rejected when assigning (`CustomLayoutStore.conflict`) and skipped when registering.
- **Storage**: `SettingKey.customZones` and `.savedLayouts` (JSON in `SettingsStore`, tolerant decoding, capped at 200 zones and 50 layouts). `CustomLayoutStore` is the only writer.
- **Geometry**: a zone is `x, y, width, height` as fractions (0...1, top-left origin) of the usable area (screen gaps and notch handling apply like built-in layouts). `CustomZone.frame(in:)` is pure; `RuntimeActionRunner` places it through `LayoutEngine.area` / `applyWindowGap` / `pixelAligned` and `SnapController.snap(_:toFrame:screen:)`, so Restore and minimum-size handling keep working.
- **Saved layouts**: `SavedLayout` holds entries `{bundleID, title?, screenIndex, rect}` with `rect` in fractions of that screen's visible frame. `ArrangementPlanner` (pure) matches current windows to entries by bundle id and exact title first, then by order within the app, and returns frames to apply. Windows are listed through the `WindowLister` protocol (Accessibility implementation in the app target). Unmatched entries are skipped; no apps are launched.
- **URL access**: `AutomationRouter` first tries `ActionRegistry.action(named:)`, then `RuntimeAction.parse`. The host (`AutomationHost.perform(_ action: RuntimeAction) -> Bool`, default `false`) reports whether the id exists; unknown or malformed ids yield `.unknownAction`. Ids are validated before they are looked up.
- **Config**: `ConfigDocument.customZones` and `.savedLayouts` decode element by element (a bad element is dropped, unknown keys ignored). Shortcuts on imported items must pass `isValidGlobalShortcut` or are removed (reported in the skipped list); shortcuts colliding with another binding are removed as well. Absent fields leave the current value untouched.

## Spaces (experimental, off by default)
macOS has no public API for moving another app's window to a Space. Options considered:
1. **Private CoreGraphics (CGS) calls** (`CGSCopyManagedDisplaySpaces`, `CGSMoveWindowsToManagedSpace`, `CGSCopySpacesForWindows`) resolved with `dlsym`. Works without disabling SIP on some macOS versions; macOS 14.5+ restricts moving windows owned by other processes, so the call can silently do nothing.
2. **Synthesized input** (drag the title bar and press Ctrl+Arrow / Ctrl+number). Fragile, visible, depends on the user's Mission Control shortcuts, and needs the window under the cursor.
3. Scripting addition (yabai): requires disabling SIP. Rejected.

Decision: option 1 only, isolated in `PrivateSpaceMover` (app target) behind the `SpaceMoving` protocol in Core. `SpaceActionController` (Core, tested with a mock) enforces the rules: the `spacesEnabled` setting (default false, never exported or imported by config so a file cannot switch on private API use) must be on, the mover must report `isAvailable`, and the result is verified by re-reading the window's Space; a failed or unverified move returns a failure result and changes nothing. Symbols that fail to resolve make the mover unavailable, so the rest of the app is unaffected. Space actions are not shown in the menu while the flag is off, and are refused when run from a URL or shortcut.

### Risks
- Private symbols can change or be restricted in any macOS release; behaviour is best effort and labelled experimental in Settings.
- Private API use is incompatible with App Store distribution (Snapr is distributed outside it, sandbox off).
- A window moved to another Space is not followed (the active Space does not change).

## Open Questions
- None.
