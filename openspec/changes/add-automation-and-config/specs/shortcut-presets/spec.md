## ADDED Requirements
### Requirement: Spectacle Preset
The system SHALL offer a preset applying Spectacle's default shortcuts to the matching actions.

#### Scenario: Apply preset
- **WHEN** the user applies the Spectacle preset
- **THEN** Spectacle bindings (for example Opt+Cmd+Left for left half) replace all current bindings

### Requirement: Restore Defaults
The system SHALL restore Snapr's default shortcuts on request.

#### Scenario: Restore
- **WHEN** the user restores defaults
- **THEN** all shortcut customizations are removed
