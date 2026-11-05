# cascade-and-stack Specification

## Purpose
Cascade windows from the top-left, and cycle through windows stacked at the same position.

## Requirements

### Requirement: Cascade
The system SHALL provide actions to cascade all windows or the active app's windows, offsetting each by a configurable step from the usable area's top-left and wrapping when the area is exhausted.

#### Scenario: Offset
- **WHEN** three windows are cascaded with an offset of 30
- **THEN** their origins differ by 30 points both horizontally and vertically

### Requirement: Stack Cycling
The system SHALL provide Stack Next and Stack Previous actions that rotate the order of the screen's stacked windows, place them with a configurable overlap offset (optionally one common size) and raise them so the new front window is on top.

#### Scenario: Next
- **WHEN** Stack Next runs on a stack A, B, C
- **THEN** the order becomes B, C, A and B is raised to the front

### Requirement: Stack Badge
The system SHALL optionally show the new front window's position in the stack (for example 2/3) after cycling.

#### Scenario: Badge shown
- **WHEN** the badge option is on and the stack is cycled
- **THEN** the stack-changed callback receives index 2 and count 3
