## ADDED Requirements
### Requirement: Menu Intro
The system SHALL show a short introduction to Snapr the first time the menu bar popover opens for a user, before the list of actions, and open on the list of actions afterwards.

#### Scenario: First open
- **WHEN** the user opens the menu bar popover for the first time
- **THEN** the popover shows the intro page with a description, three quick tips and the Accessibility status

#### Scenario: Later opens
- **WHEN** the intro has been displayed before and the user clicks the menu bar icon
- **THEN** the popover opens directly on the actions page

#### Scenario: Continue to actions
- **WHEN** the user clicks "Show all options" on the intro page
- **THEN** the popover shows the actions page

#### Scenario: Reopen intro
- **WHEN** the user clicks "Intro" in the actions page header
- **THEN** the intro page is shown again

#### Scenario: Show intro again
- **WHEN** the user clicks "Show welcome intro again" in Settings > General
- **THEN** the next time the popover opens it shows the intro page

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
