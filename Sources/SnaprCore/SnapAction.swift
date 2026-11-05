import Foundation

/// Every window action Snapr can perform.
///
/// Menu, shortcuts and the (future) URL scheme all iterate `SnapAction.allCases` /
/// `ActionRegistry`, so adding a case here exposes it everywhere automatically.
public enum SnapAction: String, CaseIterable, Codable, Hashable {
    case leftHalf = "left-half"
    case rightHalf = "right-half"
    case topHalf = "top-half"
    case bottomHalf = "bottom-half"
    case topLeftQuarter = "top-left-quarter"
    case topRightQuarter = "top-right-quarter"
    case bottomLeftQuarter = "bottom-left-quarter"
    case bottomRightQuarter = "bottom-right-quarter"
    case leftThird = "left-third"
    case centerThird = "center-third"
    case rightThird = "right-third"
    case leftTwoThirds = "left-two-thirds"
    case rightTwoThirds = "right-two-thirds"
    case maximize
    case center
    case restore
    case nextDisplay = "next-display"
    case previousDisplay = "previous-display"

    /// Stable machine name (used for persistence and URL schemes).
    public var name: String { rawValue }

    public var title: String {
        switch self {
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        case .topHalf: return "Top Half"
        case .bottomHalf: return "Bottom Half"
        case .topLeftQuarter: return "Top Left Quarter"
        case .topRightQuarter: return "Top Right Quarter"
        case .bottomLeftQuarter: return "Bottom Left Quarter"
        case .bottomRightQuarter: return "Bottom Right Quarter"
        case .leftThird: return "Left Third"
        case .centerThird: return "Center Third"
        case .rightThird: return "Right Third"
        case .leftTwoThirds: return "Left Two Thirds"
        case .rightTwoThirds: return "Right Two Thirds"
        case .maximize: return "Maximize"
        case .center: return "Center"
        case .restore: return "Restore"
        case .nextDisplay: return "Next Display"
        case .previousDisplay: return "Previous Display"
        }
    }

    public var category: ActionCategory {
        switch self {
        case .leftHalf, .rightHalf, .topHalf, .bottomHalf: return .halves
        case .topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter: return .quarters
        case .leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds: return .thirds
        case .maximize, .center, .restore: return .size
        case .nextDisplay, .previousDisplay: return .displays
        }
    }
}

public enum ActionCategory: String, CaseIterable {
    case halves = "Halves"
    case quarters = "Quarters"
    case thirds = "Thirds"
    case size = "Size"
    case displays = "Displays"
}

/// Lookup over all registered actions.
public enum ActionRegistry {
    public static var all: [SnapAction] { SnapAction.allCases }

    public static func action(named name: String) -> SnapAction? {
        SnapAction(rawValue: name)
    }

    public static func grouped() -> [(category: ActionCategory, actions: [SnapAction])] {
        ActionCategory.allCases.compactMap { category in
            let actions = all.filter { $0.category == category }
            return actions.isEmpty ? nil : (category, actions)
        }
    }
}
