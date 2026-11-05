## ADDED Requirements
### Requirement: Config Export
The system SHALL export the user's configuration as a JSON file.

#### Scenario: Export
- **WHEN** the user chooses Export Config
- **THEN** a JSON file with settings, ignored apps and shortcut customizations is written

### Requirement: Tolerant Config Import
The system SHALL import JSON configuration, ignoring unknown keys and leaving settings absent from the file unchanged.

#### Scenario: Unknown and missing keys
- **WHEN** a config contains unknown keys and omits some known keys
- **THEN** the import succeeds, known keys are applied and omitted settings keep their current values

#### Scenario: Unknown action
- **WHEN** a config binds a shortcut to an action name that is not registered
- **THEN** that entry is skipped and the rest is applied

#### Scenario: Invalid shortcut
- **WHEN** a config binds a combo that is not a valid global shortcut (for example no modifiers on a non-function key)
- **THEN** that entry is skipped and reported, including when loaded at launch

### Requirement: Load On Launch
The system SHALL apply `~/Library/Application Support/Snapr/config.json` at launch when it exists.

#### Scenario: Config present at launch
- **WHEN** Snapr starts and the file exists and is valid
- **THEN** its settings are applied before shortcuts are registered
