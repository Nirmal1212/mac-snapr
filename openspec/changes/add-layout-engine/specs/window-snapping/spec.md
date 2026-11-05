## MODIFIED Requirements
### Requirement: Cycle Sizes
The system SHALL cycle a repeated half action through 1/2, 2/3 and 1/3 widths by default, in an order the user can change.

#### Scenario: Repeat left half
- **WHEN** "Left Half" is triggered twice consecutively on the same window with default settings
- **THEN** the window width changes to 2/3, then 1/3 on the next trigger
