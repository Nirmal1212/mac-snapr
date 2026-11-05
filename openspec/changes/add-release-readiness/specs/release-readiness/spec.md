## ADDED Requirements
### Requirement: Notarized Release
Release builds SHALL be signed with a Developer ID, notarized by Apple and stapled, so that Gatekeeper opens them without a warning.

#### Scenario: Fresh install
- **WHEN** a user downloads the release DMG and opens Snapr.app
- **THEN** macOS opens it without an unidentified-developer warning

#### Scenario: Stable permission grant
- **WHEN** the user updates to a new release signed with the same Developer ID
- **THEN** the existing Accessibility permission still applies

### Requirement: Documented Appearance
The README and website SHALL show screenshots of the menu popover, the settings window and the drag-to-snap preview, and the UI SHALL be checked in light and dark appearance.

#### Scenario: Screenshots present
- **WHEN** a visitor opens the README
- **THEN** it shows the current popover, settings window and snap preview
