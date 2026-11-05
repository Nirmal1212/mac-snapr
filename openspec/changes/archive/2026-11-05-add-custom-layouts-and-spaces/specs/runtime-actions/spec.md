## ADDED Requirements
### Requirement: Runtime Actions
The system SHALL support actions defined at run time (custom zones, saved layouts, Space moves) with names `custom:<id>`, `layout:<id>` and `space:<next|previous|n>`, available as shortcuts, menu entries and URL actions.

#### Scenario: Run by URL
- **WHEN** `snapr://execute-action?name=custom:<id>` is opened and the zone exists
- **THEN** the zone is applied to the focused window

#### Scenario: Invalid or unknown id
- **WHEN** the id is malformed (not 1 to 64 characters of lowercase letters, digits or hyphen) or does not exist
- **THEN** nothing is performed

### Requirement: Config Round Trip
The system SHALL export and import custom zones and saved layouts, ignoring unknown keys and invalid elements, and validating shortcuts.

#### Scenario: Round trip
- **WHEN** the configuration is exported and imported on a clean profile
- **THEN** the zones and layouts and their valid shortcuts are restored

#### Scenario: Invalid shortcut
- **WHEN** an imported item has a combo that is not a valid global shortcut
- **THEN** the item is imported without the shortcut and the problem is reported
