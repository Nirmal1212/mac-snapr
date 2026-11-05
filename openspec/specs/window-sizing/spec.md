# window-sizing Specification

## Purpose
Resize and move windows without snapping: larger, smaller, move to edge, double and halve.

## Requirements

### Requirement: Larger and Smaller
The system SHALL grow or shrink the focused window about its center by a configurable step (default 30 pt) per axis, staying inside the usable area and above a minimum window size.

#### Scenario: Larger
- **WHEN** the user triggers "Larger" on a 400x300 window with default settings
- **THEN** the window is 430x330 with the same center, shifted inward if it would leave the usable area

#### Scenario: Minimum size
- **WHEN** "Smaller" is triggered on a window already at the minimum size
- **THEN** the size does not shrink further and the HUD appears

### Requirement: Move Without Resizing
The system SHALL move the window to the left, right, top or bottom edge of the usable area without changing its size.

#### Scenario: Move left
- **WHEN** the user triggers "Move Left"
- **THEN** the window's left edge meets the usable area's left edge and its size is unchanged

### Requirement: Double and Halve
The system SHALL double or halve the window's width or height, clamped to the usable area.

#### Scenario: Double width
- **WHEN** the user triggers "Double Width" on a window that would then exceed the right edge
- **THEN** the window is doubled and shifted left to fit

### Requirement: Specified Size
The system SHALL center the window at a user-configured size (clamped to the usable area).

#### Scenario: Specified size
- **WHEN** the user triggers "Specified Size" with 1024x640 configured
- **THEN** the window is 1024x640 and centered
