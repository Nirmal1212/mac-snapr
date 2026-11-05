import CoreGraphics
import Foundation

/// Width order a repeated left/right half action cycles through.
public enum HalfCycleOrder: String, Codable, CaseIterable, Equatable {
    /// Rectangle: 1/2 → 2/3 → 1/3 (default).
    case rectangle
    /// Original core spec: 1/2 → 1/3 → 2/3.
    case spec

    public var widths: [CGFloat] {
        switch self {
        case .rectangle: return [1.0 / 2, 2.0 / 3, 1.0 / 3]
        case .spec: return [1.0 / 2, 1.0 / 3, 2.0 / 3]
        }
    }

    public var title: String {
        switch self {
        case .rectangle: return "1/2 → 2/3 → 1/3 (Rectangle)"
        case .spec: return "1/2 → 1/3 → 2/3"
        }
    }
}

/// What repeating a left/right half action does.
public enum RepeatBehavior: String, Codable, CaseIterable, Equatable {
    case cycleSizes
    case moveToAdjacentDisplay

    public var title: String {
        switch self {
        case .cycleSizes: return "Cycle sizes"
        case .moveToAdjacentDisplay: return "Move to adjacent display"
        }
    }
}

/// Per-edge screen gap.
public struct EdgeGaps: Codable, Equatable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    public var isZero: Bool { top == 0 && left == 0 && bottom == 0 && right == 0 }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        top = try c.decodeIfPresent(CGFloat.self, forKey: .top) ?? 0
        left = try c.decodeIfPresent(CGFloat.self, forKey: .left) ?? 0
        bottom = try c.decodeIfPresent(CGFloat.self, forKey: .bottom) ?? 0
        right = try c.decodeIfPresent(CGFloat.self, forKey: .right) ?? 0
    }
}

public struct GapOptions: Codable, Equatable {
    /// Distance between neighbouring snapped windows.
    public var windowGap: CGFloat = 0
    /// Distance between windows and the usable-area edges.
    public var screenGaps = EdgeGaps()
    /// Apply gaps only on the primary screen.
    public var mainScreenOnly = false
    /// Keep the top of the usable area below the camera housing on notched screens.
    public var notchAwareTopGap = true
    /// Ignore the top screen gap when the menu bar is hidden (non-notched screens).
    public var fullHeightWhenMenuBarHidden = false
    /// Action names exempt from gaps.
    public var exemptActions: Set<String> = []

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case windowGap, screenGaps, mainScreenOnly, notchAwareTopGap, fullHeightWhenMenuBarHidden, exemptActions
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        windowGap = try c.decodeIfPresent(CGFloat.self, forKey: .windowGap) ?? 0
        screenGaps = try c.decodeIfPresent(EdgeGaps.self, forKey: .screenGaps) ?? EdgeGaps()
        mainScreenOnly = try c.decodeIfPresent(Bool.self, forKey: .mainScreenOnly) ?? false
        notchAwareTopGap = try c.decodeIfPresent(Bool.self, forKey: .notchAwareTopGap) ?? true
        fullHeightWhenMenuBarHidden = try c.decodeIfPresent(Bool.self, forKey: .fullHeightWhenMenuBarHidden) ?? false
        exemptActions = try c.decodeIfPresent(Set<String>.self, forKey: .exemptActions) ?? []
    }

    public func isExempt(_ action: SnapAction) -> Bool { exemptActions.contains(action.name) }
}

/// All settings of the layout engine, stored under one key. Decoding tolerates missing fields.
public struct LayoutOptions: Codable, Equatable {
    public var halfCycleOrder: HalfCycleOrder = .rectangle
    public var repeatBehavior: RepeatBehavior = .cycleSizes
    public var quadrantCycling = false
    public var oppositeSideSwitch = false
    public var repeatedMaximizeRestores = false
    public var halvesKeepOtherAxis = false
    public var unsnapRestoresSize = true
    public var portraitAwareThirds = true
    /// Fraction of the usable area used by Almost Maximize.
    public var almostMaximizeFraction: CGFloat = 0.9
    /// Points added/removed per axis by Larger / Smaller.
    public var resizeStep: CGFloat = 30
    public var minimumWindowSize = CGSize(width: 200, height: 120)
    /// Size used by the Specified Size action.
    public var specifiedSize = CGSize(width: 1024, height: 640)
    public var gaps = GapOptions()

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case halfCycleOrder, repeatBehavior, quadrantCycling, oppositeSideSwitch, repeatedMaximizeRestores
        case halvesKeepOtherAxis, unsnapRestoresSize, portraitAwareThirds, almostMaximizeFraction
        case resizeStep, minimumWindowSize, specifiedSize, gaps
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = LayoutOptions.defaults
        halfCycleOrder = (try? c.decodeIfPresent(HalfCycleOrder.self, forKey: .halfCycleOrder)) ?? d.halfCycleOrder
        repeatBehavior = (try? c.decodeIfPresent(RepeatBehavior.self, forKey: .repeatBehavior)) ?? d.repeatBehavior
        quadrantCycling = try c.decodeIfPresent(Bool.self, forKey: .quadrantCycling) ?? d.quadrantCycling
        oppositeSideSwitch = try c.decodeIfPresent(Bool.self, forKey: .oppositeSideSwitch) ?? d.oppositeSideSwitch
        repeatedMaximizeRestores =
            try c.decodeIfPresent(Bool.self, forKey: .repeatedMaximizeRestores) ?? d.repeatedMaximizeRestores
        halvesKeepOtherAxis = try c.decodeIfPresent(Bool.self, forKey: .halvesKeepOtherAxis) ?? d.halvesKeepOtherAxis
        unsnapRestoresSize = try c.decodeIfPresent(Bool.self, forKey: .unsnapRestoresSize) ?? d.unsnapRestoresSize
        portraitAwareThirds = try c.decodeIfPresent(Bool.self, forKey: .portraitAwareThirds) ?? d.portraitAwareThirds
        almostMaximizeFraction =
            try c.decodeIfPresent(CGFloat.self, forKey: .almostMaximizeFraction) ?? d.almostMaximizeFraction
        resizeStep = try c.decodeIfPresent(CGFloat.self, forKey: .resizeStep) ?? d.resizeStep
        minimumWindowSize = try c.decodeIfPresent(CGSize.self, forKey: .minimumWindowSize) ?? d.minimumWindowSize
        specifiedSize = try c.decodeIfPresent(CGSize.self, forKey: .specifiedSize) ?? d.specifiedSize
        gaps = try c.decodeIfPresent(GapOptions.self, forKey: .gaps) ?? d.gaps
    }

    private static let defaults = LayoutOptions()
}

public extension SettingKey {
    /// Layout engine options (cycle order, repeat behavior, sizing, gaps).
    static var layoutOptions: SettingKey<LayoutOptions> { .init("layoutOptions", default: LayoutOptions()) }
}
