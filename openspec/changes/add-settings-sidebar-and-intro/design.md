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
- **When the intro shows**: the first time the popover opens for a user (`introSeen` is false). `introSeen` is recorded when the popover hides after the intro was displayed, and afterwards every open starts on the Actions page. The Actions page has an "Intro" button in its header to view the intro again, and Settings > General has "Show welcome intro again", which clears `introSeen`. `introSeen` is per-user UI state and is not exported in config JSON (an old `showIntroOnOpen` key in a config file is ignored).
- **Popover geometry and dismissal**: the panel is placed under the status item when shown and keeps its bottom-left origin if its content size changes, so a page with a different height would detach the panel from the menu bar. Both pages therefore have the identical fixed size (340 x 480, intro content top-aligned, actions list filling the rest), and the page reset never changes the size. `dismissPopover()` clicks the status item button (`NSStatusBarButton.performClick`), the same action the user takes, so `MenuBarExtra` keeps its presented state and icon highlight consistent; `orderOut`/`close()` hide the panel behind its back, and `close()` is only the fallback. Opening Settings does not change the activation policy (it stays `.accessory`; the Settings window is a plain `NSWindow` activated with `NSApp.activate`).
- **Action order in the popover**: `PopoverActionLayout` presents Maximize, Center, Restore and Maximize Height as one group "Maximize & Center" directly after Quarters; `ActionCategory` (Settings, URLs, search) is unchanged.
- **Actions page** keeps today's content (categorized actions, ignore app, custom zones and layouts, Spaces if enabled, Settings, Check for Updates, Quit) in a scrolling list with category disclosure groups, since `.window` style does not give native submenus. Shortcut labels stay right-aligned. Keyboard: arrow navigation, Return to run, Escape closes the popover.

## Risks / Trade-offs
- `.window` style loses native menu behavior (type-to-select, automatic submenu hover). Mitigated with a filter field on the Actions page if the list proves unwieldy; not required in this change.
- The popover steals focus from the frontmost window, so actions must target the previously focused window. Existing behavior already tracks the last non-Snapr frontmost app; reuse it and add a test with the mock provider.
- Search index can drift from the real controls (see above).

## Decisions Confirmed
- The intro shows only the first time the popover opens for a user (revised from "every click" after trying the packaged app), with "Show welcome intro again" in Settings.

## Manual Test Matrix (menu popover)
The `.window` popover cannot be exercised by unit tests. Before release, on macOS 13 and on macOS 14 or later, repeat each of these 5 times in a row and confirm the popover opens on the Intro page only the first time and on the Actions page afterwards, the menu bar icon highlight is not stuck, and the next icon click opens it again on the first click:
- Open, then press Escape.
- Open, then run an action (the previously focused window moves; the popover closes).
- Open, then click outside the popover.
- Open, press Return on the Intro page ("Show all options"), then reopen: no row is pre-focused and Return does nothing.
- Open, go to Actions, open Settings, close Settings, reopen the popover: the panel stays attached to the icon (5 times).
- Cmd+, and Cmd+Q on both the Intro and Actions pages.
The dismiss mechanism is the single `dismissPopover()` helper in `MenuPopoverView.swift` (status item click; `close()` fallback). Also check Activity Monitor: idle CPU with the popover closed and open stays near 0%.
