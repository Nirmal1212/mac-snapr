## ADDED Requirements
### Requirement: Action For New Windows
The system SHALL optionally apply a chosen action to every new window, detected by comparing window sets between scans; windows present when the feature starts SHALL NOT be affected.

#### Scenario: New window snapped
- **WHEN** the option is Left Half and a new window appears
- **THEN** it is snapped to the left half

#### Scenario: Existing windows
- **WHEN** the option is first enabled with windows already open
- **THEN** those windows are left alone
