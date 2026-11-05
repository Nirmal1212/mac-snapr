## ADDED Requirements
### Requirement: Menu Intro
The system SHALL show a short introduction to Snapr when the user clicks the menu bar icon, before the list of actions, until the user dismisses it.

#### Scenario: First click
- **WHEN** the user clicks the menu bar icon for the first time
- **THEN** the popover shows the intro page with a description, three quick tips and the Accessibility status

#### Scenario: Dismiss
- **WHEN** the user clicks "Get started" on the intro page
- **THEN** the popover shows the actions page and later opens directly on the actions page

#### Scenario: Reopen intro
- **WHEN** the user clicks "Intro" in the actions page header
- **THEN** the intro page is shown again

#### Scenario: Keep intro on
- **WHEN** the user enables "Show intro when opening the menu" in Settings
- **THEN** every open of the popover starts on the intro page

#### Scenario: Missing permission
- **WHEN** Accessibility access has not been granted
- **THEN** the intro page shows that status with a button that opens the permission guidance

### Requirement: Actions Page
The system SHALL list all enabled actions grouped by category in the menu bar popover, with each action's shortcut shown, and run the action on the window that was focused before the popover opened.

#### Scenario: Run an action
- **WHEN** the user selects "Left Half" in the popover
- **THEN** the popover closes and the previously focused window snaps to the left half

#### Scenario: Keyboard use
- **WHEN** the popover is open and the user presses Escape
- **THEN** the popover closes without running an action
