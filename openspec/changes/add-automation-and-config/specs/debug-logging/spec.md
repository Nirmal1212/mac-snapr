## ADDED Requirements
### Requirement: Debug Log Viewer
The system SHALL keep a bounded in-memory log of action events when debug logging is enabled and show it in a viewer window.

#### Scenario: Viewing
- **WHEN** debug logging is on and actions run
- **THEN** the viewer lists timestamped entries, newest last, and can clear them

#### Scenario: Disabled
- **WHEN** debug logging is off
- **THEN** nothing is recorded
