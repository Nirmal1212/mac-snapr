## Context
Greenfield menu bar app controlling other apps' windows via Accessibility API.

## Decisions
- **Accessibility API over private APIs**: stable, permission-gated, App-Store-independent.
- **Layout as enum + pure function**: `SnapAction` → `CGRect` given `visibleFrame`; trivially testable.
- **Hotkeys via Carbon**: no extra permission beyond Accessibility; low overhead.
- **Drag detection via CGEventTap (listen-only)**: avoids interfering with input.
- **Restore**: store original frame per window (`CGWindowID`) in memory only.

## Risks / Trade-offs
- Some apps enforce min/max sizes → clamp and accept result.
- Coordinate-system mismatch across displays → centralize conversion in one helper.
- Full-screen/Stage Manager windows → ignore unsupported windows.

## Open Questions
- Default shortcut modifier set (Ctrl+Opt vs Ctrl+Cmd) to avoid system conflicts.

## Resolved
- Default shortcut modifiers: Ctrl+Opt (Ctrl+Opt+Cmd for display moves). Users can rebind in Settings.
- Shared extension points: `SnapAction` enum + `ActionRegistry` (menu, shortcuts and settings iterate it), typed `SettingKey`/`SettingsStore`, `WindowProvider`/`ScreenProvider` protocols with mocks in `SnaprCore`.
- Limitation: actions are a closed `SnapAction` enum (compile-time). Runtime-defined actions (e.g. custom zones) will need the registry to move to a protocol-based model in a later change.
