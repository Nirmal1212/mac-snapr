## 1. Settings structure
- [x] 1.1 Add `SettingsSection` enum (id, title, symbol) and `SettingsIndex` with matching and ranking in `SnaprCore`, with unit tests
- [x] 1.2 Split `SettingsView` into per-section views; add About section (version, update check, links)
- [x] 1.3 Declare `searchEntries` for each section, including those from input, multi-window and custom-layout views
- [x] 1.4 Unit test: every section has entries, ids unique, sections exist

## 2. Settings UI
- [x] 2.1 `NavigationSplitView` with sidebar list, detail pane and remembered selection
- [x] 2.2 Sidebar search field, result list, no-results state, Escape and Cmd+F handling
- [x] 2.3 Scroll to and highlight the chosen setting; accessibility labels and focus
- [ ] 2.4 Window sizing and light/dark appearance check

## 3. Menu intro
- [x] 3.1 Add `showIntroOnOpen` settings key (default true, tolerant decoding)
- [x] 3.2 Switch `MenuBarExtra` to `.window` style; build Intro page and Actions page
- [x] 3.3 Actions page: grouped, scrolling list with shortcut labels; run on previously focused window
- [x] 3.4 "Show intro when opening the menu" toggle in Settings > General (default on)
- [x] 3.5 Tests for intro state transitions and target-window tracking with mock providers

## 4. Docs
- [ ] 4.1 README screenshots of new settings and intro (needs a Mac)
- [x] 4.2 CONTRIBUTING note: new controls must add a search entry
