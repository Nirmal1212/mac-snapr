## ADDED Requirements
### Requirement: Save And Recall Layouts
The system SHALL capture the arrangement of open windows as a named layout and re-apply it on demand.

#### Scenario: Recall
- **WHEN** the user applies a saved layout
- **THEN** each open window matching an entry (same app and title, else same app by order) is moved to the stored position relative to its screen

#### Scenario: Missing windows
- **WHEN** an entry has no matching open window
- **THEN** it is skipped and no application is launched
