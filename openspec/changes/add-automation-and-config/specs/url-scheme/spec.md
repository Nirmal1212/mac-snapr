## ADDED Requirements
### Requirement: URL Scheme
The system SHALL handle `snapr://` URLs to execute actions and manage ignored apps.

#### Scenario: Execute action
- **WHEN** `snapr://execute-action?name=left-half` is opened
- **THEN** the focused window snaps to the left half

#### Scenario: Registry-driven names
- **WHEN** the `name` is any action registered in `ActionRegistry`
- **THEN** it is executed without further changes to the URL handler

#### Scenario: Unknown action
- **WHEN** the `name` is not a registered action
- **THEN** nothing is executed and the failure is logged

#### Scenario: Ignore and unignore
- **WHEN** `snapr://ignore-app?bundle-id=com.example.App` or `snapr://unignore-app?bundle-id=com.example.App` is opened
- **THEN** that bundle identifier is added to or removed from the ignored list

#### Scenario: Bundle id required and validated
- **WHEN** `ignore-app` or `unignore-app` has no `bundle-id`, or it is longer than 255 characters or contains characters outside `[A-Za-z0-9.-]`
- **THEN** the URL is rejected and the ignored list is unchanged (URLs never default to the frontmost app)

#### Scenario: Bounded list
- **WHEN** the ignored list already holds 500 apps
- **THEN** further ignore requests are rejected
