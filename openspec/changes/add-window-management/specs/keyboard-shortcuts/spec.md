## ADDED Requirements
### Requirement: Global Shortcuts
The system SHALL register global keyboard shortcuts for every snap action, active in any application.

#### Scenario: Default arrow bindings
- **WHEN** the user presses Ctrl+Opt+Left
- **THEN** the focused window snaps to the left half

### Requirement: Customizable Bindings
The system SHALL let users record, change, and clear shortcuts, persisting them across launches.

#### Scenario: Rebind
- **WHEN** the user records a new shortcut for "Maximize"
- **THEN** the new shortcut works immediately and the old one is released

### Requirement: Conflict Detection
The system SHALL warn when a shortcut is already assigned to another action.

#### Scenario: Duplicate
- **WHEN** the user assigns an in-use shortcut
- **THEN** the system shows a warning and does not apply it until confirmed
