import Foundation

/// The settings sections in sidebar order. This is the single source for the sidebar and the search index:
/// `searchEntries` switches exhaustively over the cases, so a new section cannot be added without entries.
public enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general
    case shortcuts
    case layout
    case gaps
    case dragAndSnap = "drag-and-snap"
    case multipleWindows = "multiple-windows"
    case customLayouts = "custom-layouts"
    case ignoredApps = "ignored-apps"
    case compatibility
    case configuration
    case about

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .general: return "General"
        case .shortcuts: return "Shortcuts"
        case .layout: return "Layout"
        case .gaps: return "Gaps"
        case .dragAndSnap: return "Drag and Snap"
        case .multipleWindows: return "Multiple Windows"
        case .customLayouts: return "Custom Layouts"
        case .ignoredApps: return "Ignored Apps"
        case .compatibility: return "Compatibility"
        case .configuration: return "Configuration"
        case .about: return "About"
        }
    }

    /// SF Symbol name for the sidebar row.
    public var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .shortcuts: return "keyboard"
        case .layout: return "rectangle.split.2x2"
        case .gaps: return "square.dashed"
        case .dragAndSnap: return "cursorarrow.motionlines"
        case .multipleWindows: return "square.on.square"
        case .customLayouts: return "rectangle.3.group"
        case .ignoredApps: return "nosign"
        case .compatibility: return "wrench.and.screwdriver"
        case .configuration: return "slider.horizontal.3"
        case .about: return "info.circle"
        }
    }

    /// Prefix of every search entry id in this section (`"<idPrefix>.<name>"`).
    public var idPrefix: String {
        switch self {
        case .general: return "general"
        case .shortcuts: return "shortcuts"
        case .layout: return "layout"
        case .gaps: return "gaps"
        case .dragAndSnap: return "drag"
        case .multipleWindows: return "multi"
        case .customLayouts: return "custom"
        case .ignoredApps: return "ignored"
        case .compatibility: return "compat"
        case .configuration: return "config"
        case .about: return "about"
        }
    }

    /// Position in the sidebar, used as a ranking tiebreaker.
    public var order: Int { Self.allCases.firstIndex(of: self) ?? Self.allCases.count }
}
