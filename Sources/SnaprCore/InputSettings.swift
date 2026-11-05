import CoreGraphics
import Foundation

/// Footprint (drag preview) appearance.
public struct FootprintStyle: Codable, Equatable {
    public var alpha: Double = 0.25
    public var borderWidth: Double = 2
    /// RGB color as 0...1 components; nil uses the system accent color.
    public var color: [Double]?
    public var blur = false

    public init() {}

    private enum CodingKeys: String, CodingKey { case alpha, borderWidth, color, blur }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        alpha = try c.decodeIfPresent(Double.self, forKey: .alpha) ?? alpha
        borderWidth = try c.decodeIfPresent(Double.self, forKey: .borderWidth) ?? borderWidth
        color = try c.decodeIfPresent([Double].self, forKey: .color)
        blur = try c.decodeIfPresent(Bool.self, forKey: .blur) ?? blur
    }
}

/// Tunable drag-to-edge snapping behavior.
public struct DragSnapOptions: Codable, Equatable {
    /// Zones that are active. Defaults to the core zones; thirds, halves and sixths are opt-in.
    public var enabledZones: Set<DragZone> = DragZone.defaultEnabled
    /// Modifiers that must all be held for a drag to snap (empty = always).
    public var requiredModifiers: KeyModifiers = []
    /// Distance from a screen edge at which a zone activates.
    public var edgeMargin: Double = Double(DragZones.edgeThreshold)
    /// Length along an edge, from a corner, that counts as the corner zone.
    public var cornerSize: Double = Double(DragZones.cornerSize)
    public var footprint = FootprintStyle()
    /// Animate window placement (short, bounded).
    public var animate = false
    /// Keep a drag above the menu bar from triggering Mission Control.
    public var preventMissionControl = false

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case enabledZones, requiredModifiers, edgeMargin, cornerSize, footprint, animate, preventMissionControl
    }

    /// Tolerant decoding so options added later never reset saved ones.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabledZones = try c.decodeIfPresent(Set<DragZone>.self, forKey: .enabledZones) ?? enabledZones
        requiredModifiers = try c.decodeIfPresent(KeyModifiers.self, forKey: .requiredModifiers) ?? requiredModifiers
        edgeMargin = try c.decodeIfPresent(Double.self, forKey: .edgeMargin) ?? edgeMargin
        cornerSize = try c.decodeIfPresent(Double.self, forKey: .cornerSize) ?? cornerSize
        footprint = try c.decodeIfPresent(FootprintStyle.self, forKey: .footprint) ?? footprint
        animate = try c.decodeIfPresent(Bool.self, forKey: .animate) ?? animate
        preventMissionControl = try c.decodeIfPresent(Bool.self, forKey: .preventMissionControl) ?? preventMissionControl
    }

    /// Whether the held modifiers satisfy the requirement.
    public func modifiersSatisfied(by held: KeyModifiers) -> Bool {
        held.isSuperset(of: requiredModifiers)
    }
}

/// Rules applied when a window moves to another display.
public struct DisplayRules: Codable, Equatable {
    /// Order displays left to right by x coordinate (otherwise the system's order).
    public var orderByX = true
    /// A maximized window keeps its size (clamped, centered) instead of refilling the destination.
    public var keepSizeWhenMaximized = false
    /// Re-apply the window's last snap action on the destination display.
    public var repeatLastAction = false
    /// Warp the cursor to the window center after the move.
    public var moveCursorWithWindow = false

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case orderByX, keepSizeWhenMaximized, repeatLastAction, moveCursorWithWindow
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        orderByX = try c.decodeIfPresent(Bool.self, forKey: .orderByX) ?? orderByX
        keepSizeWhenMaximized = try c.decodeIfPresent(Bool.self, forKey: .keepSizeWhenMaximized) ?? keepSizeWhenMaximized
        repeatLastAction = try c.decodeIfPresent(Bool.self, forKey: .repeatLastAction) ?? repeatLastAction
        moveCursorWithWindow = try c.decodeIfPresent(Bool.self, forKey: .moveCursorWithWindow) ?? moveCursorWithWindow
    }
}

/// A middle/extra mouse button bound to an action.
public struct MouseShortcut: Codable, Equatable, Identifiable {
    public var id = UUID()
    /// CGEvent button number: 2 = middle, 3 and up = extra buttons.
    public var button: Int
    public var modifiers: KeyModifiers
    public var action: SnapAction
    /// Act on the window under the pointer instead of the focused window.
    public var underPointer: Bool

    public init(button: Int = 2, modifiers: KeyModifiers = [], action: SnapAction, underPointer: Bool = false) {
        self.button = button
        self.modifiers = modifiers
        self.action = action
        self.underPointer = underPointer
    }
}

public enum MouseShortcuts {
    /// The shortcut for a pressed button with exactly these modifiers. Left/right buttons never match.
    public static func match(_ list: [MouseShortcut], button: Int, modifiers: KeyModifiers) -> MouseShortcut? {
        guard button >= 2 else { return nil }
        return list.first { $0.button == button && $0.modifiers == modifiers }
    }
}

/// Title-bar double-click helpers (pure).
public enum TitleBar {
    public static let height: CGFloat = 28

    /// Whether `point` lies in the title-bar strip at the top of `window`.
    public static func contains(_ point: CGPoint, in window: CGRect, height: CGFloat = TitleBar.height) -> Bool {
        window.contains(point) && point.y <= window.minY + height
    }

    /// Maximize, or restore when the window already fills `visible`.
    public static func toggleAction(windowFrame: CGRect, visible: CGRect) -> SnapAction {
        WindowGeometry.approximatelyEqual(windowFrame, visible, tolerance: 4) ? .restore : .maximize
    }
}

/// Eased interpolation between frames for animated placement.
public enum FrameAnimation {
    public static func frames(from start: CGRect, to end: CGRect, steps: Int) -> [CGRect] {
        guard steps > 1 else { return [end] }
        return (1...steps).map { index in
            let t = Double(index) / Double(steps)
            let eased = CGFloat(1 - pow(1 - t, 3))
            func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * eased }
            return CGRect(
                x: mix(start.minX, end.minX), y: mix(start.minY, end.minY),
                width: mix(start.width, end.width), height: mix(start.height, end.height))
        }
    }
}

/// Moves the mouse cursor (global top-left/y-down space).
public protocol CursorProvider: AnyObject {
    func move(to point: CGPoint)
}

public final class MockCursorProvider: CursorProvider {
    public private(set) var moves: [CGPoint] = []
    public init() {}
    public func move(to point: CGPoint) { moves.append(point) }
}

public extension SettingKey {
    static var dragSnapOptions: SettingKey<DragSnapOptions> { .init("dragSnapOptions", default: DragSnapOptions()) }
    static var displayRules: SettingKey<DisplayRules> { .init("displayRules", default: DisplayRules()) }
    static var mouseShortcuts: SettingKey<[MouseShortcut]> { .init("mouseShortcuts", default: []) }
    /// Double-click a title bar to maximize / restore.
    static var titleBarDoubleClick: SettingKey<Bool> { .init("titleBarDoubleClick", default: false) }
}
