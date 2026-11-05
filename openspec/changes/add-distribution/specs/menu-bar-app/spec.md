## MODIFIED Requirements
### Requirement: Privacy
The system SHALL NOT make network requests or collect telemetry, except that it MAY fetch the Sparkle appcast and update archives for update checks. Update checks SHALL be user-disableable, SHALL NOT send system profile data, and no other network access or telemetry is permitted.

#### Scenario: Offline
- **WHEN** the app runs with no network
- **THEN** all features work

#### Scenario: Updates disabled
- **WHEN** automatic update checks are off and the user has not chosen "Check for Updates…"
- **THEN** the app makes no network requests
