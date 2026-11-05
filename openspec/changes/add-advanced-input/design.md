## Context
Builds on the listen-only drag monitor and `SnapController` from `add-window-management`.

## Decisions
- **No new `SnapAction` cases.** Drag zones resolve to a frame (`DragZone.frame(in:)`) placed through `SnapController.snap(_:toFrame:)`; sixths and bottom thirds are not keyboard actions here (the layout-engine change owns those actions).
- **Options as Codable structs** (`DragSnapOptions`, `DisplayRules`, `[MouseShortcut]`) with tolerant decoding, stored under typed `SettingKey`s declared in `InputSettings.swift`.
- **Pure zone logic.** `DragZones.zone(at:in:options:)` is unit tested; the monitor only gathers events.
- **Two-thirds:** the bottom edge splits into thirds; a strip around each third boundary yields left/right two-thirds.
- **Half zones:** top-edge strips beside the corners snap to the top half (the center stays maximize); bottom-edge strips beside corners snap to the bottom half when bottom thirds are off.
- **Sixths (opt-in):** corner zones snap to sixths (one third wide, half high) instead of quarters.
- **Lazy AX hit-testing.** The drag monitor no longer hit-tests on every mouse-down. It records the down point and resolves the window once per gesture, when the cursor first moves past a small slop (the start frame is reconstructed by subtracting the cursor delta). `AXUIElementSetMessagingTimeout` (0.25 s) bounds AX calls so an unresponsive app cannot stall the main run loop.
- **Tap isolation.** The drag monitor and title-bar monitor stay `listenOnly`. Consuming features get their own tap: `MouseButtonMonitor` (active, only created when at least one mouse shortcut exists, consumes only matched buttons and their release) and `DragEdgeGuard` (active, only created when the Mission Control guard is on, clamps drag y one point below the top edge). Tap callbacks do no AX work; actions run asynchronously on the main queue.
- **Title-bar double-click** decides maximize vs. restore from the frame at mouse-down, then applies it after the system zoom, so the two cannot undo each other.
- **Display rules** live in `SnapController.displayRules`; cursor warping goes through a `CursorProvider` protocol (mocked in tests).
- **Animation** is a bounded (<= 120 ms), eased step loop in the AX provider; off by default.

## Risks / Trade-offs
- Active taps add per-event latency and need Accessibility; both are optional and created lazily.
- Window under the pointer for mouse shortcuts needs an AX hit-test on the press; it runs off the tap callback and is time-limited.
- The system may disable a tap on timeout; handlers re-enable it.

## Open Questions
- None.
