## Context
Settings are a single SwiftUI `Form` made of `Section`s contributed by several changes. The menu bar uses `MenuBarExtra` in `.menu` style, which only supports plain menu items.

## Decisions
### Settings window
- **NavigationSplitView** with a `List(selection:)` sidebar (SF Symbol icon + title per section) and a detail pane showing one section's `Form` (`.formStyle(.grouped)`). Selection is stored in `@SceneStorage`/settings so the window reopens on the last section. Minimum window size about 760 x 520.
- **Sections** (sidebar order): General, Shortcuts, Layout, Gaps, Drag and Snap, Multiple Windows, Custom Layouts, Ignored Apps, Compatibility, Configuration, About. Each existing `Section` becomes a standalone section view; no option moves between sections except those listed under the new About section (version, update check, links).
- **Section registry**: a `SettingsSection` enum (id, title, symbol) in `SnaprCore` is the single source for the sidebar and the search index, so a new section cannot be added without appearing in both.
- **Search**: a `SettingsIndex` in `SnaprCore` (pure, unit tested) holds entries `(id, sectionID, title, keywords)`. Matching is case- and diacritic-insensitive, requires every query token to be a prefix of a word in the title or keywords, and ranks title matches above keyword matches, then by sidebar order. The search field uses `.searchable` in the sidebar and Cmd+F focuses it. While the query is non-empty the sidebar shows results (title plus section name) instead of sections; selecting one opens the section, scrolls to the setting with `ScrollViewReader` and flashes a highlight for about one second. Escape or clearing the field restores the section list.
- **Index completeness**: entries are declared next to the views in a `static let searchEntries` per section. A unit test asserts every section has at least one entry, ids are unique and every entry's section exists. It cannot prove each control is indexed, so reviewers check new controls add an entry (noted in CONTRIBUTING.md).
- **Accessibility**: sidebar rows and search results have labels, full keyboard navigation, and the highlight is not the only cue (the target control also receives accessibility focus).

### Menu intro
- **Switch to `MenuBarExtra` with `.window` style** so the content can be a SwiftUI view. The popover has two pages: **Intro** and **Actions**.
- **Intro page**: app icon, one-sentence description, three tips (keyboard shortcut example from the user's current bindings, drag to an edge, open Settings), the Accessibility status line with a Grant button when needed, and a "Show all options" button that moves to the Actions page.
- **When the intro shows**: on every open of the popover (every click on the icon), always starting on the Intro page. The Actions page has an "Intro" button in its header to go back. Settings > General has "Show intro when opening the menu" (default on); turning it off makes the popover open directly on Actions.
- **Actions page** keeps today's content (categorized actions, ignore app, custom zones and layouts, Spaces if enabled, Settings, Check for Updates, Quit) in a scrolling list with category disclosure groups, since `.window` style does not give native submenus. Shortcut labels stay right-aligned. Keyboard: arrow navigation, Return to run, Escape closes the popover.

## Risks / Trade-offs
- `.window` style loses native menu behavior (type-to-select, automatic submenu hover). Mitigated with a filter field on the Actions page if the list proves unwieldy; not required in this change.
- The popover steals focus from the frontmost window, so actions must target the previously focused window. Existing behavior already tracks the last non-Snapr frontmost app; reuse it and add a test with the mock provider.
- Search index can drift from the real controls (see above).

## Decisions Confirmed
- The intro shows on every click of the menu bar icon (confirmed by the product owner), with an opt-out setting.

## Manual Test Matrix (menu popover)
The `.window` popover cannot be exercised by unit tests. Before release, on macOS 13 and on macOS 14 or later, repeat each of these 5 times in a row and confirm the popover reopens on the Intro page (or Actions when the intro is off), the menu bar icon highlight is not stuck, and the next icon click opens it again on the first click:
- Open, then press Escape.
- Open, then run an action (the previously focused window moves; the popover closes).
- Open, then click outside the popover.
- Open, press Return on the Intro page ("Show all options"), then reopen: no row is pre-focused and Return does nothing.
- Cmd+, and Cmd+Q on both the Intro and Actions pages.
The dismiss mechanism is the single `dismissPopover()` helper in `MenuPopoverView.swift` (`orderOut`; swap for `close()` if the status item state goes out of sync). Also check Activity Monitor: idle CPU with the popover closed and open stays near 0%.
