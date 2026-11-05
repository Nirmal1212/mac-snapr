## ADDED Requirements
### Requirement: Grid Layouts
The system SHALL provide actions that place the focused window in a cell of an even grid over the usable area: fourths and three-fourths (full height), sixths (3x2), vertical sixths (2x3), eighths (4x2), vertical eighths (2x4), ninths (3x3), and corner two-thirds (2/3 x 2/3 anchored in a corner).

#### Scenario: Second fourth
- **WHEN** the user triggers "Second Fourth"
- **THEN** the window occupies the second quarter-width column at full height

#### Scenario: Center ninth
- **WHEN** the user triggers "Ninth Middle Center"
- **THEN** the window occupies the middle cell of the 3x3 grid

#### Scenario: Corner two-thirds
- **WHEN** the user triggers "Top Left Two Thirds"
- **THEN** the window is 2/3 of the usable width and height, anchored top-left

### Requirement: Centered Layouts
The system SHALL provide Center Half (half width, full height), Center Prominently (70% x 85%), Almost Maximize (configurable fraction, default 90%) and Maximize Height (keeps x and width).

#### Scenario: Almost maximize
- **WHEN** the user triggers "Almost Maximize" with the default fraction
- **THEN** the window is centered at 90% of the usable width and height

#### Scenario: Maximize height
- **WHEN** the user triggers "Maximize Height"
- **THEN** the window keeps its x and width and spans the full usable height

### Requirement: Portrait-Aware Thirds
When enabled (default), the system SHALL lay thirds and two-thirds out vertically on screens taller than wide.

#### Scenario: Portrait display
- **WHEN** "Left Third" is triggered on a portrait screen
- **THEN** the window occupies the top third at full width

### Requirement: Fit Handling
The system SHALL align a window that cannot reach the target size to the edge or corner the target touches, and SHALL show a "Minimum size reached" HUD.

#### Scenario: App minimum size
- **WHEN** a window with a minimum width larger than the target is snapped to the right third
- **THEN** it is right-aligned to the screen edge and the HUD appears
