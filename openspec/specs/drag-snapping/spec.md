# drag-snapping Specification

## Purpose
Snap a window by dragging it to a screen edge or corner, with a preview of the target area.

## Requirements

### Requirement: Edge Drag Snap
The system SHALL snap a window when it is dragged and released at a screen edge or corner: left/right edge → half, top edge → maximize, corners → quarters.

#### Scenario: Drag to left edge
- **WHEN** the user drags a window so the cursor is at the left edge and releases
- **THEN** the window snaps to the left half

### Requirement: Preview Overlay
The system SHALL show a translucent preview of the target frame while the cursor is in a snap zone.

#### Scenario: Entering zone
- **WHEN** the cursor enters a snap zone during a drag
- **THEN** the overlay displays the target frame and disappears on release or exit

### Requirement: Toggle
The system SHALL allow drag snapping to be disabled in settings.

#### Scenario: Disabled
- **WHEN** drag snapping is off
- **THEN** no overlay appears and windows are not snapped on release
