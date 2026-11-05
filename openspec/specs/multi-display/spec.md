# multi-display Specification

## Purpose
Move windows between displays while preserving their relative layout.

## Requirements

### Requirement: Move Between Displays
The system SHALL move the focused window to the next or previous display, preserving its relative position and size.

#### Scenario: Next display
- **WHEN** the user triggers "Next Display" with two displays connected
- **THEN** the window appears on the other display at the same relative frame

### Requirement: Per-Display Snapping
The system SHALL compute snap regions from the visible frame of the display containing the window's center.

#### Scenario: Secondary display
- **WHEN** a window centered on display 2 is snapped right half
- **THEN** it fills the right half of display 2's visible frame

### Requirement: Display Changes
The system SHALL handle displays being connected or disconnected without errors.

#### Scenario: Single display
- **WHEN** only one display exists and "Next Display" is triggered
- **THEN** nothing happens
