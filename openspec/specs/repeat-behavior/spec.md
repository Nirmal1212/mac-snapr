# repeat-behavior Specification

## Purpose
Define what happens when the same snap action is repeated: cycling sizes, adjacent display and restore.

## Requirements

### Requirement: Configurable Half Cycle Order
The system SHALL let the user choose the width order a repeated left/right half action cycles through: Rectangle order 1/2 → 2/3 → 1/3 (default) or 1/2 → 1/3 → 2/3.

#### Scenario: Default order
- **WHEN** "Left Half" is triggered three times in a row with default settings
- **THEN** the widths are 1/2, then 2/3, then 1/3, then back to 1/2

#### Scenario: Alternate order
- **WHEN** the order is set to 1/2 → 1/3 → 2/3 and "Left Half" is triggered twice
- **THEN** the second width is 1/3

### Requirement: Adjacent Display on Repeat
When enabled, the system SHALL move a window that is already snapped by a left or right half action to the adjacent display in that direction (applying the same action), instead of cycling sizes.

#### Scenario: Repeat right half
- **WHEN** "Right Half" is triggered on a window already at the right half and a display exists to the right
- **THEN** the window is snapped to the right half of that display

### Requirement: Quadrant Cycling
When enabled, the system SHALL move a repeated quarter action to the next quadrant clockwise.

#### Scenario: Repeat top-left quarter
- **WHEN** "Top Left Quarter" is triggered twice in a row
- **THEN** the second trigger places the window in the top-right quadrant

### Requirement: Opposite-Side Switch
When enabled, triggering the opposite half action on a window snapped by a left/right half SHALL keep the current width.

#### Scenario: Switch side
- **WHEN** a window is at the left third (via cycling) and "Right Half" is triggered
- **THEN** it takes the right third

### Requirement: Repeated Maximize Restores
When enabled, triggering Maximize on a window the system just maximized SHALL restore its previous frame.

#### Scenario: Double maximize
- **WHEN** "Maximize" is triggered twice in a row
- **THEN** the window returns to its pre-maximize frame

### Requirement: Halves Keep Other Axis
When enabled, left/right half SHALL keep the window's vertical position and height, and top/bottom half SHALL keep its horizontal position and width.

#### Scenario: Left half
- **WHEN** "Left Half" is triggered on a window of height 300 at y=100
- **THEN** the window is at the left half with y=100 and height 300

### Requirement: Unsnap Restores Size
When enabled (default), dragging a window away from a position the system snapped it to SHALL restore its pre-snap size, keeping the cursor at the same relative position.

#### Scenario: Drag out of snap
- **WHEN** a snapped window is dragged
- **THEN** it returns to its pre-snap size under the cursor
