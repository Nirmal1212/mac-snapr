## ADDED Requirements
### Requirement: Manual Update Check
The system SHALL provide a "Check for Updates…" menu item that checks the appcast and offers a signed update.

#### Scenario: Update available
- **WHEN** the user selects "Check for Updates…" and a newer signed version exists in the appcast
- **THEN** the system shows the update prompt with release notes

#### Scenario: Up to date
- **WHEN** the user selects "Check for Updates…" and no newer version exists
- **THEN** the system reports that Snapr is up to date

### Requirement: Automatic Checks
The system SHALL check for updates automatically at most once per day while running, and SHALL let the user disable automatic checks in settings.

#### Scenario: Disabled
- **WHEN** automatic update checks are off
- **THEN** no network request is made unless the user triggers a manual check

### Requirement: Signed Updates Only
The system SHALL install only updates whose archive carries a valid EdDSA signature matching the public key embedded in the app.

#### Scenario: Bad signature
- **WHEN** an appcast item has a missing or invalid signature
- **THEN** the update is rejected and nothing is installed

### Requirement: Unconfigured Builds
The system SHALL disable updating when the app bundle has no feed URL or public key.

#### Scenario: Development build
- **WHEN** Snapr runs via `swift run` or without update keys in Info.plist
- **THEN** the update menu item is disabled and no update network request is made

### Requirement: Update Network Use Only
The system SHALL make network requests only to fetch the appcast and update archives, SHALL NOT send system profile data, and SHALL NOT collect telemetry. This refines the Privacy requirement of the menu-bar-app capability.

#### Scenario: Offline
- **WHEN** the app runs with no network
- **THEN** all window management features work and a failed update check is reported without side effects
