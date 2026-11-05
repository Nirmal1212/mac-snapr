# window-compatibility Specification

## Purpose
Handle apps that need special treatment when resized, such as Enhanced User Interface and native-resize apps.

## Requirements

### Requirement: Enhanced UI Handling
The system SHALL temporarily disable an app's Accessibility Enhanced User Interface while resizing its window and restore it afterwards, unless disabled by preference.

#### Scenario: Enhanced UI app
- **WHEN** a window of an app with Enhanced UI enabled is snapped
- **THEN** the frame is applied without animation interference and the app's setting is restored

### Requirement: Native Resize Apps
The system SHALL let users list apps whose windows are resized with a single size-then-position pass.

#### Scenario: Listed app
- **WHEN** a window of a listed app is snapped
- **THEN** the size and position are each set once
