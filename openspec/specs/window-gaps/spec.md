# window-gaps Specification

## Purpose
Add gaps between windows and around screen edges, including notch-aware and per-action exemptions.

## Requirements

### Requirement: Window and Screen Gaps
The system SHALL support a gap between snapped windows and per-edge gaps between windows and the screen edges.

#### Scenario: Window gap
- **WHEN** a 10 pt window gap is set and Left Half and Right Half are applied
- **THEN** the two windows are exactly 10 pt apart and touch the screen edges

#### Scenario: Screen gap
- **WHEN** a 20 pt left screen gap is set and Left Half is applied
- **THEN** the window starts 20 pt from the left edge of the usable area

### Requirement: Gap Scope
The system SHALL allow gaps to apply on the main screen only and SHALL allow individual actions to be exempt from gaps.

#### Scenario: Exempt action
- **WHEN** Maximize is exempt and gaps are set
- **THEN** Maximize fills the visible frame exactly

### Requirement: Notch and Menu Bar
The system SHALL keep windows below the camera housing on notched displays (notch-aware top gap) and SHALL use the full height when the menu bar is hidden on non-notched displays.

#### Scenario: Notched display
- **WHEN** a snap targets a screen with a 32 pt safe-area inset and a hidden menu bar
- **THEN** the window's top edge is at least 32 pt below the screen's top
