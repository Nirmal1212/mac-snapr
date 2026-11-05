# custom-zones Specification

## Purpose
Let users define their own screen zones, each with an optional shortcut, and snap windows to them.

## Requirements

### Requirement: Custom Zones
The system SHALL let the user define zones as rectangles relative to the usable screen area and place the focused window in a zone.

#### Scenario: Place in zone
- **WHEN** the user runs a custom zone
- **THEN** the focused window is moved and resized to the zone's rectangle within the usable area, honoring screen and window gaps, and Restore can undo it

#### Scenario: Invalid zone
- **WHEN** a zone has non-finite values, a non-positive size or a rectangle outside the screen
- **THEN** it is rejected when created and dropped when imported

### Requirement: Zone Shortcuts
The system SHALL allow an optional global shortcut per custom zone.

#### Scenario: Conflict
- **WHEN** the chosen combo is already used by a built-in action or another custom item, or is not a valid global shortcut
- **THEN** the assignment is rejected
