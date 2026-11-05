## ADDED Requirements
### Requirement: Move Window To Space
The system SHALL provide an experimental, default-off feature to move the focused window to the next, previous or numbered Space using private APIs that do not require disabling SIP.

#### Scenario: Disabled
- **WHEN** the feature flag is off
- **THEN** Space actions do nothing and are not offered in the menu

#### Scenario: Unavailable or failed
- **WHEN** the private symbols are missing, or the window's Space does not change
- **THEN** the action reports failure, changes nothing else and the rest of Snapr keeps working

#### Scenario: Not configurable by file
- **WHEN** a config file is imported
- **THEN** it cannot change the feature flag
