## ADDED Requirements
### Requirement: Ignored Apps
The system SHALL let users mark applications, by bundle identifier, as ignored, and SHALL NOT trigger snap shortcuts while an ignored application is frontmost.

#### Scenario: Shortcut in ignored app
- **WHEN** an ignored app is frontmost and the user presses a Snapr shortcut
- **THEN** the key press reaches the app and no window is moved

#### Scenario: Ignore frontmost app from the menu
- **WHEN** the user chooses "Ignore <app>" in the menu bar menu
- **THEN** the app's bundle identifier is added to the ignored list and shortcuts are suspended while it is frontmost
