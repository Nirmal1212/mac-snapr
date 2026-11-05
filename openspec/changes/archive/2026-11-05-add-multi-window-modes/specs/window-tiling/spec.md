## ADDED Requirements
### Requirement: Tile Windows
The system SHALL provide actions to tile all windows, tile the active app's windows, tile in rows and tile in columns, filling the usable area of the screen with no overlap and the configured window gap between tiles.

#### Scenario: Tile all
- **WHEN** four windows are on a screen and Tile All runs
- **THEN** they form a 2 by 2 grid covering the usable area

#### Scenario: Tile active app
- **WHEN** Tile Active App runs
- **THEN** only the frontmost app's windows are tiled and other windows are untouched

### Requirement: Row and Column Limits
The system SHALL support a maximum windows per row and per column, and a balanced mode in which the last row or column stretches to fill the area.

#### Scenario: Max per row
- **WHEN** five windows are tiled in rows with a maximum of 3 per row
- **THEN** the first row holds three windows and the second two, and the second row's windows are wider when balanced is on

### Requirement: Combined Display Mode
The system SHALL optionally lay windows out across all displays together, distributing them in proportion to each display's usable area.

#### Scenario: Two equal displays
- **WHEN** combined mode is on and four windows span two equal displays
- **THEN** each display receives two windows

### Requirement: Reverse All
The system SHALL provide an action that reverses the positions of all windows on the screen.

#### Scenario: Two windows
- **WHEN** a window on the left and one on the right exist and Reverse All runs
- **THEN** they swap frames
