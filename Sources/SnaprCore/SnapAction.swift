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

    // MARK: add-layout-engine
    // Fourths
    case firstFourth = "first-fourth"
    case secondFourth = "second-fourth"
    case thirdFourth = "third-fourth"
    case lastFourth = "last-fourth"
    case leftThreeFourths = "left-three-fourths"
    case rightThreeFourths = "right-three-fourths"
    // Sixths
    case topLeftSixth = "top-left-sixth"
    case topCenterSixth = "top-center-sixth"
    case topRightSixth = "top-right-sixth"
    case bottomLeftSixth = "bottom-left-sixth"
    case bottomCenterSixth = "bottom-center-sixth"
    case bottomRightSixth = "bottom-right-sixth"
    // Vertical sixths
    case verticalSixthLeftTop = "vertical-sixth-left-top"
    case verticalSixthLeftMiddle = "vertical-sixth-left-middle"
    case verticalSixthLeftBottom = "vertical-sixth-left-bottom"
    case verticalSixthRightTop = "vertical-sixth-right-top"
    case verticalSixthRightMiddle = "vertical-sixth-right-middle"
    case verticalSixthRightBottom = "vertical-sixth-right-bottom"
    // Eighths
    case topFirstEighth = "top-first-eighth"
    case topSecondEighth = "top-second-eighth"
    case topThirdEighth = "top-third-eighth"
    case topFourthEighth = "top-fourth-eighth"
    case bottomFirstEighth = "bottom-first-eighth"
    case bottomSecondEighth = "bottom-second-eighth"
    case bottomThirdEighth = "bottom-third-eighth"
    case bottomFourthEighth = "bottom-fourth-eighth"
    // Vertical eighths
    case verticalEighthLeft1 = "vertical-eighth-left-1"
    case verticalEighthLeft2 = "vertical-eighth-left-2"
    case verticalEighthLeft3 = "vertical-eighth-left-3"
    case verticalEighthLeft4 = "vertical-eighth-left-4"
    case verticalEighthRight1 = "vertical-eighth-right-1"
    case verticalEighthRight2 = "vertical-eighth-right-2"
    case verticalEighthRight3 = "vertical-eighth-right-3"
    case verticalEighthRight4 = "vertical-eighth-right-4"
    // Ninths
    case ninthTopLeft = "ninth-top-left"
    case ninthTopCenter = "ninth-top-center"
    case ninthTopRight = "ninth-top-right"
    case ninthMiddleLeft = "ninth-middle-left"
    case ninthMiddleCenter = "ninth-middle-center"
    case ninthMiddleRight = "ninth-middle-right"
    case ninthBottomLeft = "ninth-bottom-left"
    case ninthBottomCenter = "ninth-bottom-center"
    case ninthBottomRight = "ninth-bottom-right"
    // Corner two-thirds
    case topLeftTwoThirds = "top-left-two-thirds"
    case topRightTwoThirds = "top-right-two-thirds"
    case bottomLeftTwoThirds = "bottom-left-two-thirds"
    case bottomRightTwoThirds = "bottom-right-two-thirds"
    // Centered and large
    case centerHalf = "center-half"
    case centerProminently = "center-prominently"
    case almostMaximize = "almost-maximize"
    case maximizeHeight = "maximize-height"
    // Sizing and moving
    case larger = "larger"
    case smaller = "smaller"
    case moveLeft = "move-left"
    case moveRight = "move-right"
    case moveUp = "move-up"
    case moveDown = "move-down"
    case doubleWidth = "double-width"
    case halveWidth = "halve-width"
    case doubleHeight = "double-height"
    case halveHeight = "halve-height"
    case specifiedSize = "specified-size"

    // MARK: add-multi-window-modes
    case tileAll = "tile-all"
    case tileActiveApp = "tile-active-app"
    case tileRows = "tile-rows"
    case tileColumns = "tile-columns"
    case cascadeAll = "cascade-all"
    case cascadeActiveApp = "cascade-active-app"
    case stackNext = "stack-next"
    case stackPrevious = "stack-previous"
    case reverseAll = "reverse-all"
    case toggleTodo = "toggle-todo"
    case reflowTodo = "reflow-todo"

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
        // MARK: add-layout-engine
        case .firstFourth, .secondFourth, .thirdFourth, .lastFourth, .leftThreeFourths, .rightThreeFourths:
            return LayoutCatalog.title(for: self)
        case .topLeftSixth, .topCenterSixth, .topRightSixth, .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth:
            return LayoutCatalog.title(for: self)
        case .verticalSixthLeftTop, .verticalSixthLeftMiddle, .verticalSixthLeftBottom,
            .verticalSixthRightTop, .verticalSixthRightMiddle, .verticalSixthRightBottom:
            return LayoutCatalog.title(for: self)
        case .topFirstEighth, .topSecondEighth, .topThirdEighth, .topFourthEighth, .bottomFirstEighth,
            .bottomSecondEighth, .bottomThirdEighth, .bottomFourthEighth:
            return LayoutCatalog.title(for: self)
        case .verticalEighthLeft1, .verticalEighthLeft2, .verticalEighthLeft3, .verticalEighthLeft4,
            .verticalEighthRight1, .verticalEighthRight2, .verticalEighthRight3, .verticalEighthRight4:
            return LayoutCatalog.title(for: self)
        case .ninthTopLeft, .ninthTopCenter, .ninthTopRight, .ninthMiddleLeft, .ninthMiddleCenter,
            .ninthMiddleRight, .ninthBottomLeft, .ninthBottomCenter, .ninthBottomRight:
            return LayoutCatalog.title(for: self)
        case .topLeftTwoThirds, .topRightTwoThirds, .bottomLeftTwoThirds, .bottomRightTwoThirds:
            return LayoutCatalog.title(for: self)
        case .centerHalf, .centerProminently, .almostMaximize, .maximizeHeight:
            return LayoutCatalog.title(for: self)
        case .larger, .smaller, .moveLeft, .moveRight, .moveUp, .moveDown, .doubleWidth, .halveWidth,
            .doubleHeight, .halveHeight, .specifiedSize:
            return LayoutCatalog.title(for: self)
        // MARK: add-multi-window-modes
        case .tileAll, .tileActiveApp, .tileRows, .tileColumns, .cascadeAll, .cascadeActiveApp, .stackNext,
            .stackPrevious, .reverseAll, .toggleTodo, .reflowTodo:
            return MultiWindowCatalog.title(for: self)
        }
    }

    public var category: ActionCategory {
        switch self {
        case .leftHalf, .rightHalf, .topHalf, .bottomHalf: return .halves
        case .topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter: return .quarters
        case .leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds: return .thirds
        case .maximize, .center, .restore: return .size
        case .nextDisplay, .previousDisplay: return .displays
        // MARK: add-layout-engine
        case .firstFourth, .secondFourth, .thirdFourth, .lastFourth, .leftThreeFourths, .rightThreeFourths:
            return LayoutCatalog.category(for: self)
        case .topLeftSixth, .topCenterSixth, .topRightSixth, .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth:
            return LayoutCatalog.category(for: self)
        case .verticalSixthLeftTop, .verticalSixthLeftMiddle, .verticalSixthLeftBottom,
            .verticalSixthRightTop, .verticalSixthRightMiddle, .verticalSixthRightBottom:
            return LayoutCatalog.category(for: self)
        case .topFirstEighth, .topSecondEighth, .topThirdEighth, .topFourthEighth, .bottomFirstEighth,
            .bottomSecondEighth, .bottomThirdEighth, .bottomFourthEighth:
            return LayoutCatalog.category(for: self)
        case .verticalEighthLeft1, .verticalEighthLeft2, .verticalEighthLeft3, .verticalEighthLeft4,
            .verticalEighthRight1, .verticalEighthRight2, .verticalEighthRight3, .verticalEighthRight4:
            return LayoutCatalog.category(for: self)
        case .ninthTopLeft, .ninthTopCenter, .ninthTopRight, .ninthMiddleLeft, .ninthMiddleCenter,
            .ninthMiddleRight, .ninthBottomLeft, .ninthBottomCenter, .ninthBottomRight:
            return LayoutCatalog.category(for: self)
        case .topLeftTwoThirds, .topRightTwoThirds, .bottomLeftTwoThirds, .bottomRightTwoThirds:
            return LayoutCatalog.category(for: self)
        case .centerHalf, .centerProminently, .almostMaximize, .maximizeHeight:
            return LayoutCatalog.category(for: self)
        case .larger, .smaller, .moveLeft, .moveRight, .moveUp, .moveDown, .doubleWidth, .halveWidth,
            .doubleHeight, .halveHeight, .specifiedSize:
            return LayoutCatalog.category(for: self)
        // MARK: add-multi-window-modes
        case .tileAll, .tileActiveApp, .tileRows, .tileColumns, .cascadeAll, .cascadeActiveApp, .stackNext,
            .stackPrevious, .reverseAll, .toggleTodo, .reflowTodo:
            return MultiWindowCatalog.category(for: self)
        }
    }
}

public enum ActionCategory: String, CaseIterable {
    case halves = "Halves"
    case quarters = "Quarters"
    case thirds = "Thirds"
    case fourths = "Fourths"
    case sixths = "Sixths"
    case eighths = "Eighths"
    case ninths = "Ninths"
    case size = "Size"
    case sizing = "Sizing & Moving"
    case displays = "Displays"
    // MARK: add-multi-window-modes
    case multiWindow = "Multiple Windows"
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
