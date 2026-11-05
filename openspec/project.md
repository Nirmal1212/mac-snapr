# Project Context

## Purpose
Snapr: a small, fast, native macOS menu bar app giving Windows-style window management: snap to halves/quarters/thirds, maximize, restore, move between displays, via keyboard shortcuts and drag-to-edge.

## Tech Stack
- Swift 5.9+, macOS 13+ (Ventura)
- SwiftUI (settings, menu bar via `MenuBarExtra`), AppKit where needed
- Accessibility API (`AXUIElement`) for window control
- Carbon `RegisterEventHotKey` / `CGEventTap` for global hotkeys and drag detection
- Swift Package Manager + Xcode project; XCTest

## Conventions
- Pure geometry logic lives in `WindowGeometry` (no AppKit side effects) and is unit tested.
- OS access hidden behind protocols (`WindowProvider`, `ScreenProvider`) for mocking.
- SwiftLint + swift-format; small files; no third-party deps unless justified.
- Conventional Commits.

## Domain Notes
- Requires Accessibility permission; app must degrade gracefully without it.
- Use `NSScreen.visibleFrame` (excludes menu bar/Dock); convert between Cocoa (bottom-left) and AX (top-left) coordinates.
- No telemetry. Network access only for optional, user-disableable update checks (Sparkle); otherwise fully local.

## Constraints
- Idle CPU < 1%, memory < 50 MB.
- Sandbox off (Accessibility API); distribute notarized outside App Store.

## Out of Scope
- Windows/Linux support
- Behavior beyond Rectangle (including Rectangle Pro) feature parity; see `docs/rectangle-feature-map.md` for the planned changes
