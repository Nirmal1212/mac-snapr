## ADDED Requirements
### Requirement: Additional Drag Zones
The system SHALL support bottom-third zones, two-thirds zones between thirds, half zones beside corners, and opt-in sixths, and SHALL allow each zone to be enabled or disabled individually.

#### Scenario: Bottom third
- **WHEN** the cursor is at the bottom edge within the left third and bottom thirds are enabled
- **THEN** the target is the bottom-left third of the screen

#### Scenario: Two-thirds between zones
- **WHEN** the cursor is at the bottom edge near the boundary between the left and center thirds
- **THEN** the target is the left two-thirds

#### Scenario: Disabled zone
- **WHEN** a zone is disabled
- **THEN** the cursor there produces no target

### Requirement: Required Modifier
The system SHALL optionally require held modifier keys for a drag to snap.

#### Scenario: Modifier missing
- **WHEN** a modifier is required and not held during the drag
- **THEN** no overlay appears and the window is not snapped

### Requirement: Margins and Footprint
The system SHALL let the user set the edge margin and corner size and the footprint alpha, border width, color and blur.

#### Scenario: Larger margin
- **WHEN** the edge margin is increased
- **THEN** a cursor that far from the edge activates the zone

### Requirement: Animation and Mission Control Guard
The system SHALL optionally animate snapped windows and SHALL optionally prevent a drag above the menu bar from triggering Mission Control.

#### Scenario: Guard on
- **WHEN** the guard is on and a drag reaches the top edge
- **THEN** the pointer position is held one point below the edge
