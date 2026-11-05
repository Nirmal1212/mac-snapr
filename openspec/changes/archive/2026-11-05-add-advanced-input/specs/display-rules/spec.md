## ADDED Requirements
### Requirement: Display Ordering
The system SHALL order displays by x coordinate for next/previous display, or by system order when that rule is off.

#### Scenario: By x
- **WHEN** ordering is by x and the system lists the right display first
- **THEN** Next Display from the left display moves to the display on the right

### Requirement: Keep Size When Maximized
The system SHALL optionally keep a maximized window's size, clamped and centered, when moving it to another display.

#### Scenario: Option on
- **WHEN** a maximized window is moved to a larger display
- **THEN** it keeps its size instead of filling the new display

### Requirement: Repeat Last Action
The system SHALL optionally apply the window's last snap action on the destination display after a display move.

#### Scenario: Left half follows
- **WHEN** a window snapped to Left Half is moved to another display
- **THEN** it becomes Left Half on that display

### Requirement: Cursor Follows Window
The system SHALL optionally move the cursor to the window center after a display move.

#### Scenario: Cursor moved
- **WHEN** the option is on and a window moves displays
- **THEN** the cursor is warped to the window center
