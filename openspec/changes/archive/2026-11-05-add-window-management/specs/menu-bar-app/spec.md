## ADDED Requirements
### Requirement: Menu Bar Presence
The system SHALL run as a menu bar app with no Dock icon, exposing all actions in its menu.

#### Scenario: Menu action
- **WHEN** the user selects "Right Half" from the menu
- **THEN** the previously focused window snaps to the right half

### Requirement: Accessibility Onboarding
The system SHALL detect missing Accessibility permission and guide the user to grant it.

#### Scenario: First launch
- **WHEN** permission is not granted
- **THEN** the app shows an explanation and opens System Settings → Privacy & Security → Accessibility

### Requirement: Launch at Login
The system SHALL offer an option to launch at login.

#### Scenario: Enable
- **WHEN** the user enables "Launch at Login"
- **THEN** the app registers via `SMAppService` and starts on next login

### Requirement: Privacy
The system SHALL NOT make network requests or collect telemetry.

#### Scenario: Offline
- **WHEN** the app runs with no network
- **THEN** all features work
