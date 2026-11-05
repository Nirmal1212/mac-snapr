import Foundation

/// Search entries per section. Every control in the settings views needs an entry here whose id matches the
/// view's `.settingTarget("<id>")` (see CONTRIBUTING.md). Titles mostly mirror the visible labels (without live values); keywords add synonyms.
extension SettingsSection {
    public var searchEntries: [SettingsEntry] {
        switch self {
        case .general: return Self.generalEntries
        case .shortcuts: return Self.shortcutEntries
        case .layout: return Self.layoutEntries
        case .gaps: return Self.gapEntries
        case .dragAndSnap: return Self.dragEntries
        case .multipleWindows: return Self.multiWindowEntries
        case .customLayouts: return Self.customEntries
        case .ignoredApps: return Self.ignoredEntries
        case .compatibility: return Self.compatibilityEntries
        case .configuration: return Self.configurationEntries
        case .about: return Self.aboutEntries
        }
    }

    private static let generalEntries: [SettingsEntry] = [
        .init("general.drag-snap", .general, "Snap windows by dragging to screen edges",
            ["drag", "edge", "mouse", "enable", "disable", "toggle"]),
        .init("general.launch-at-login", .general, "Launch at login",
            ["startup", "start", "boot", "login item", "open automatically"]),
        .init("general.auto-updates", .general, "Automatically check for updates",
            ["upgrade", "sparkle", "version", "daily"]),
        .init("general.accessibility", .general, "Accessibility access",
            ["permission", "grant", "privacy", "security", "trusted", "event tap"]),
        // Added for task 3 (menu intro); the matching Button carries .settingTarget("general.show-intro").
        .init("general.show-intro", .general, "Show welcome intro again",
            ["welcome", "popover", "menu bar", "tips", "introduction", "onboarding", "intro", "reset", "tutorial"])
    ]

    private static let shortcutEntries: [SettingsEntry] =
        [
            SettingsEntry("shortcuts.restore-defaults", .shortcuts, "Restore Default Shortcuts",
                ["reset", "keyboard", "hotkey"]),
            SettingsEntry("shortcuts.spectacle", .shortcuts, "Use Spectacle Shortcuts",
                ["preset", "keyboard", "hotkey", "migrate"])
        ]
        + ActionRegistry.all.map { action in
            SettingsEntry(
                "shortcuts.action.\(action.rawValue)", .shortcuts, action.title,
                ["shortcut", "keyboard", "hotkey", "key", action.category.rawValue])
        }

    private static let layoutEntries: [SettingsEntry] = [
        .init("layout.half-cycle-order", .layout, "Repeat half cycle order", ["halves", "left", "right", "repeat", "cycle"]),
        .init("layout.repeat-behavior", .layout, "Repeating left/right half", ["halves", "repeat", "thirds", "cycle"]),
        .init("layout.quadrant-cycling", .layout, "Repeating a quarter cycles through quadrants",
            ["corner", "quarters", "repeat"]),
        .init("layout.opposite-side", .layout, "Opposite half keeps the current width", ["switch", "halves", "resize"]),
        .init("layout.repeat-maximize", .layout, "Repeating Maximize restores the window", ["fullscreen", "toggle", "undo"]),
        .init("layout.halves-other-axis", .layout, "Halves keep the window's other axis", ["height", "width", "position"]),
        .init("layout.unsnap-size", .layout, "Dragging a snapped window restores its size", ["unsnap", "original", "undo"]),
        .init("layout.portrait-thirds", .layout, "Thirds stack vertically on portrait displays",
            ["vertical", "rotated", "monitor", "screen"]),
        .init("layout.almost-maximize", .layout, "Almost Maximize", ["percent", "fraction", "size", "fullscreen"]),
        .init("layout.resize-step", .layout, "Larger / Smaller step", ["grow", "shrink", "increment", "points", "size"]),
        .init("layout.specified-width", .layout, "Specified size width", ["fixed", "custom", "points", "size"]),
        .init("layout.specified-height", .layout, "Specified size height", ["fixed", "custom", "points", "size"])
    ]

    private static let gapEntries: [SettingsEntry] = [
        .init("gaps.window-gap", .gaps, "Between windows", ["gap", "spacing", "padding", "margin", "points"]),
        .init("gaps.screen-top", .gaps, "Screen top", ["gap", "margin", "padding", "edge", "points"]),
        .init("gaps.screen-left", .gaps, "Screen left", ["gap", "margin", "padding", "edge", "points"]),
        .init("gaps.screen-bottom", .gaps, "Screen bottom", ["gap", "margin", "padding", "edge", "points"]),
        .init("gaps.screen-right", .gaps, "Screen right", ["gap", "margin", "padding", "edge", "points"]),
        .init("gaps.main-screen-only", .gaps, "Only on the main screen", ["gap", "display", "monitor", "primary"]),
        .init("gaps.notch", .gaps, "Keep windows below the notch", ["gap", "macbook", "camera", "top"]),
        .init("gaps.full-height-menu-bar", .gaps, "Use full height when the menu bar is hidden",
            ["gap", "auto-hide", "autohide", "fullscreen"]),
        .init("gaps.exempt-actions", .gaps, "Actions exempt from gaps", ["gap", "exclude", "ignore", "exception", "disable"])
    ]

    private static let dragEntries: [SettingsEntry] = [
        .init("drag.zones", .dragAndSnap, "Zones",
            ["drag", "snapping", "edges", "corners", "left", "right", "top", "bottom", "third", "maximize"]),
        .init("drag.modifier", .dragAndSnap, "Require modifier",
            ["drag", "control", "option", "shift", "command", "key", "hold"]),
        .init("drag.edge-margin", .dragAndSnap, "Edge margin", ["drag", "sensitivity", "distance", "slider"]),
        .init("drag.corner-size", .dragAndSnap, "Corner size", ["drag", "sensitivity", "distance", "slider"]),
        .init("drag.animate", .dragAndSnap, "Animate windows", ["animation", "motion", "drag", "smooth"]),
        .init("drag.mission-control", .dragAndSnap, "Keep dragging above the menu bar from opening Mission Control",
            ["drag", "top", "spaces", "prevent"]),
        .init("drag.preview-opacity", .dragAndSnap, "Drag preview opacity", ["footprint", "transparency", "alpha", "slider"]),
        .init("drag.preview-border", .dragAndSnap, "Drag preview border width", ["footprint", "outline", "slider"]),
        .init("drag.preview-blur", .dragAndSnap, "Drag preview blur", ["footprint", "vibrancy", "frosted"]),
        .init("drag.preview-color", .dragAndSnap, "Drag preview color", ["footprint", "accent", "tint", "colour"]),
        .init("drag.displays-order", .dragAndSnap, "Order displays by x coordinate",
            ["displays", "monitors", "screens", "arrangement", "left to right"]),
        .init("drag.displays-keep-size", .dragAndSnap, "Keep size when moving a maximized window",
            ["displays", "monitors", "screens", "next display"]),
        .init("drag.displays-repeat", .dragAndSnap, "Repeat last action on the other display",
            ["displays", "monitors", "screens", "next display"]),
        .init("drag.displays-cursor", .dragAndSnap, "Move cursor with window",
            ["displays", "monitors", "screens", "mouse", "pointer"]),
        .init("drag.title-bar", .dragAndSnap, "Double-click title bar to maximize / restore",
            ["titlebar", "header", "mouse", "fullscreen"]),
        .init("drag.mouse-shortcuts", .dragAndSnap, "Mouse button shortcuts",
            ["middle", "button", "click", "pointer", "modifier", "under pointer", "add mouse"])
    ]

    private static let multiWindowEntries: [SettingsEntry] = [
        .init("multi.max-per-row", .multipleWindows, "Max windows per row", ["tile", "grid", "columns", "limit"]),
        .init("multi.max-per-column", .multipleWindows, "Max windows per column", ["tile", "grid", "rows", "limit"]),
        .init("multi.balanced-grid", .multipleWindows, "Balanced grids", ["tile", "last row", "fill", "even"]),
        .init("multi.combined-displays", .multipleWindows, "Combined displays",
            ["tile", "all displays", "monitors", "screens"]),
        .init("multi.cascade-offset", .multipleWindows, "Cascade offset", ["staircase", "points", "spacing"]),
        .init("multi.stack-offset", .multipleWindows, "Stack overlap offset", ["overlap", "points", "spacing", "pile"]),
        .init("multi.stack-same-size", .multipleWindows, "Stacked windows share one size", ["overlap", "pile", "equal"]),
        .init("multi.stack-badge", .multipleWindows, "Show stack badge when cycling", ["overlap", "indicator", "hud", "pile"]),
        .init("multi.todo", .multipleWindows, "Todo mode", ["sidebar", "pin", "enable", "app"]),
        .init("multi.todo-app", .multipleWindows, "Todo app", ["bundle identifier", "sidebar", "frontmost"]),
        .init("multi.todo-width", .multipleWindows, "Todo sidebar width", ["points", "size"]),
        .init("multi.todo-side", .multipleWindows, "Todo sidebar side", ["left", "right", "position"]),
        .init("multi.stage-manager", .multipleWindows, "Keep layouts clear of the Stage Manager strip",
            ["stage manager", "avoid", "gap"]),
        .init("multi.stage-width", .multipleWindows, "Stage Manager strip width", ["points", "size"]),
        .init("multi.stage-side", .multipleWindows, "Stage Manager strip side", ["left", "right", "position"]),
        .init("multi.new-window-action", .multipleWindows, "Apply to every new window",
            ["automatic", "auto", "snap", "new windows", "default position"])
    ]

    private static let customEntries: [SettingsEntry] = [
        .init("custom.zones", .customLayouts, "Custom Zones", ["rectangle", "region", "percent", "area", "add zone", "remove"]),
        .init("custom.saved-layouts", .customLayouts, "Saved Layouts",
            ["workspace", "arrangement", "save current windows", "apply", "restore"]),
        .init("custom.spaces", .customLayouts, "Enable moving windows to other Spaces",
            ["spaces", "desktops", "experimental", "mission control", "virtual desktops"])
    ]

    private static let ignoredEntries: [SettingsEntry] = [
        .init("ignored.apps", .ignoredApps, "Ignored apps",
            ["exclude", "disable", "blocklist", "blacklist", "bundle identifier", "shortcuts off", "add app"])
    ]

    private static let compatibilityEntries: [SettingsEntry] = [
        .init("compat.native-resize", .compatibility, "Apps resized with a single size-then-position pass",
            ["native", "resize", "terminal", "workaround", "problem", "bundle identifier", "add app"])
    ]

    private static let configurationEntries: [SettingsEntry] = [
        .init("config.import", .configuration, "Import Config", ["load", "restore", "json", "file", "backup"]),
        .init("config.export", .configuration, "Export Config", ["save", "backup", "json", "file"]),
        .init("config.debug-log", .configuration, "Debug Log", ["diagnostics", "troubleshoot", "logs", "support"])
    ]

    private static let aboutEntries: [SettingsEntry] = [
        .init("about.version", .about, "Version", ["build", "release", "snapr"]),
        .init("about.check-updates", .about, "Check for Updates", ["upgrade", "sparkle", "new version", "download"]),
        .init("about.github", .about, "Snapr on GitHub", ["source", "code", "website", "link", "repository", "homepage", "issues"])
    ]
}
