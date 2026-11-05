## Why
The Settings window is now one long scrolling form with a dozen sections, which is hard to scan and hard to search. The menu bar menu jumps straight into a long list of actions, so a new user gets no explanation of what Snapr is or how to use it.

## What Changes
- Settings window becomes a two-pane layout like macOS System Settings: a sidebar listing the sections (with icons) and a detail pane for the selected section.
- A search field in the sidebar finds individual settings across all sections; choosing a result opens its section and highlights the setting.
- Clicking the menu bar icon first shows a short introduction to Snapr (what it does, three quick tips, permission status) before the list of actions, on every click, with a setting to turn it off.

## Impact
- Affected specs: settings-window (new), menu-bar-app (added requirements)
- Affected code: `SettingsView` and the per-section views (`InputSettingsSections`, `MultiWindowSettingsSections`, `CustomLayoutSections`), a new settings search index in `SnaprCore`, `SnaprApp` menu bar scene, new intro view
- No change to window-management behavior, shortcuts, URL scheme or stored settings format (one new boolean setting, `showIntroOnOpen`)

## Out of Scope
- Reorganizing which options exist or renaming them
- Localization
- Onboarding for Accessibility permission (already covered by add-window-management)
