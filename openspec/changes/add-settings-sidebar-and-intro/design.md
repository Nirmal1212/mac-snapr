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
- **Intro page**: app icon, one-sentence description, three tips (keyboard shortcut example from the user's current bindings, drag to an edge, open Settings), the Accessibility status line with a Grant button when needed, and a "Get started" button that moves to Actions and records `introDismissed = true`.
- **When the intro shows**: on every open until dismissed with "Get started"; afterwards the popover opens on Actions, which has an "Intro" button in its header to return to the intro. Settings > General has "Show intro when opening the menu" to bring the intro back permanently.
- **Actions page** keeps today's content (categorized actions, ignore app, custom zones and layouts, Spaces if enabled, Settings, Check for Updates, Quit) in a scrolling list with category disclosure groups, since `.window` style does not give native submenus. Shortcut labels stay right-aligned. Keyboard: arrow navigation, Return to run, Escape closes the popover.

## Risks / Trade-offs
- `.window` style loses native menu behavior (type-to-select, automatic submenu hover). Mitigated with a filter field on the Actions page if the list proves unwieldy; not required in this change.
- The popover steals focus from the frontmost window, so actions must target the previously focused window. Existing behavior already tracks the last non-Snapr frontmost app; reuse it and add a test with the mock provider.
- Search index can drift from the real controls (see above).

## Open Questions
- Should the intro show every time the icon is clicked, or only until dismissed? This design assumes until dismissed, with a setting to keep it on.
