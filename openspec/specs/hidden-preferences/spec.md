# hidden-preferences Specification

## Purpose
Expose advanced options through `defaults write` keys that are not shown in the Settings window.

## Requirements

### Requirement: Hidden Preferences
The system SHALL read advanced options from user defaults so they can be set with `defaults write com.you.snapr <key> ...`.

#### Scenario: Enable debug logging
- **WHEN** `defaults write com.you.snapr debugLogging -bool true` is run
- **THEN** debug events are recorded

#### Scenario: Absent or malformed value
- **WHEN** a key is absent or has the wrong type
- **THEN** its documented default is used
