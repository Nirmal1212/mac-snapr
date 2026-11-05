## ADDED Requirements
### Requirement: Mouse Button Shortcuts
The system SHALL run a configured action when a middle or extra mouse button is pressed with the configured modifiers, on the focused window or optionally the window under the pointer, and SHALL consume only matched button events.

#### Scenario: Matched press
- **WHEN** button 3 is pressed with Option and a binding exists
- **THEN** the action runs and the click is not delivered to the app

#### Scenario: Unmatched press
- **WHEN** a button without a binding is pressed
- **THEN** the event passes through unchanged

### Requirement: Title Bar Double-Click
The system SHALL optionally maximize a window on title-bar double-click, and restore it when it is already maximized.

#### Scenario: Maximize
- **WHEN** the user double-clicks the title bar of a non-maximized window
- **THEN** the window is maximized

#### Scenario: Restore
- **WHEN** the user double-clicks the title bar of a maximized window
- **THEN** the window returns to its previous frame
