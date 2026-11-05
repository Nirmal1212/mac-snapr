## ADDED Requirements
### Requirement: Todo Mode
The system SHALL provide a Todo mode that reserves a sidebar (configurable width and side) on one screen for the configured Todo app, with all other windows laid out in the remaining area.

#### Scenario: Tile beside the sidebar
- **WHEN** Todo mode is on and Tile All runs
- **THEN** the Todo app's window fills the sidebar and the other windows tile in the rest of the screen

#### Scenario: Toggle
- **WHEN** Toggle Todo runs with no Todo app configured
- **THEN** the frontmost window's app becomes the Todo app and Todo mode turns on

### Requirement: Stage Manager Awareness
The system SHALL exclude the Stage Manager strip (configurable width and side) from the usable area of every layout action while Stage Manager is active.

#### Scenario: Left strip
- **WHEN** Stage Manager is active with a 190 pt left strip and Left Half runs
- **THEN** the window fills the left half of the area right of the strip
