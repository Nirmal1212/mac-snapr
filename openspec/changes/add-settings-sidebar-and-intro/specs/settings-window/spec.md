## ADDED Requirements
### Requirement: Sidebar Navigation
The settings window SHALL present a sidebar listing every settings section with an icon and title, and a detail pane showing the selected section.

#### Scenario: Open settings
- **WHEN** the user opens Settings for the first time
- **THEN** the sidebar lists all sections and the General section is shown

#### Scenario: Select a section
- **WHEN** the user selects "Shortcuts" in the sidebar
- **THEN** the detail pane shows only the Shortcuts section

#### Scenario: Remember selection
- **WHEN** the user closes and reopens Settings
- **THEN** the previously selected section is shown

### Requirement: Settings Search
The settings window SHALL provide a search field that finds individual settings across all sections.

#### Scenario: Find a setting
- **WHEN** the user types "gap" in the search field
- **THEN** results list the settings whose title or keywords match, each with its section name

#### Scenario: Open a result
- **WHEN** the user selects a result
- **THEN** the window shows that setting's section, scrolls to the setting and highlights it briefly

#### Scenario: Multiple words
- **WHEN** the user types "launch login"
- **THEN** only settings matching both words are listed

#### Scenario: No match
- **WHEN** no setting matches the query
- **THEN** the sidebar shows a "No results" message

#### Scenario: Clear search
- **WHEN** the user clears the search field or presses Escape
- **THEN** the sidebar shows the section list again with the selection preserved

#### Scenario: Keyboard
- **WHEN** the user presses Cmd+F in the settings window
- **THEN** the search field receives focus

### Requirement: Search Index Coverage
Every settings section SHALL be registered in one section list that drives both the sidebar and the search index, and each section SHALL contribute at least one searchable entry.

#### Scenario: New section
- **WHEN** a section is added to the section list without search entries
- **THEN** the unit tests fail
