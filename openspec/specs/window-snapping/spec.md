# window-snapping Specification

## Purpose
Snap the focused window to halves, quarters, thirds, maximize, center and restore its previous frame.

## Requirements

### Requirement: Snap to Screen Regions
The system SHALL resize and position the focused window to a chosen region of the current display's visible frame: left/right/top/bottom half, four quarters, left/center/right third, two-thirds, maximize, and center.

#### Scenario: Snap left half
- **WHEN** the user triggers "Left Half" with a focused window
- **THEN** the window frame equals the left 50% of the screen's visible frame

#### Scenario: Snap to quarter
- **WHEN** the user triggers "Top Right Quarter"
- **THEN** the window occupies the top-right 25% of the visible frame

### Requirement: Cycle Sizes
The system SHALL cycle a repeated half action through 1/2, 2/3 and 1/3 widths by default, in an order the user can change.

#### Scenario: Repeat left half
- **WHEN** "Left Half" is triggered twice consecutively on the same window with default settings
- **THEN** the window width changes to 2/3, then 1/3 on the next trigger

### Requirement: Restore Previous Size
The system SHALL restore a window's pre-snap frame on request.

#### Scenario: Restore
- **WHEN** a snapped window receives "Restore"
- **THEN** it returns to its frame before the first snap

### Requirement: Unsupported Windows
The system SHALL ignore actions on windows that cannot be resized and SHALL NOT crash.

#### Scenario: Fixed-size window
- **WHEN** an action targets a non-resizable window
- **THEN** the system moves it if possible and otherwise does nothing
