import CoreGraphics
import Foundation

/// Side of the screen used by a reserved area (Todo sidebar, Stage Manager strip).
public enum ScreenSide: String, Codable, CaseIterable, Equatable {
    case left, right

    public var title: String { self == .left ? "Left" : "Right" }
}

/// Todo mode: a reserved sidebar for one app, other windows use the remaining area.
public struct TodoOptions: Codable, Equatable {
    public var enabled = false
    /// Bundle identifier of the Todo app.
    public var bundleID: String?
    public var sidebarWidth: CGFloat = 400
    public var side: ScreenSide = .right
    /// Screen holding the sidebar; nil means the primary screen.
    public var screenID: Int?

    public init() {}

    private enum CodingKeys: String, CodingKey { case enabled, bundleID, sidebarWidth, side, screenID }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = (try? c.decodeIfPresent(Bool.self, forKey: .enabled)) ?? false
        bundleID = (try? c.decodeIfPresent(String.self, forKey: .bundleID)) ?? nil
        sidebarWidth = (try? c.decodeIfPresent(CGFloat.self, forKey: .sidebarWidth)) ?? 400
        side = (try? c.decodeIfPresent(ScreenSide.self, forKey: .side)) ?? .right
        screenID = (try? c.decodeIfPresent(Int.self, forKey: .screenID)) ?? nil
    }
}

/// Stage Manager awareness: the strip area is excluded from layouts while Stage Manager is active.
public struct StageManagerOptions: Codable, Equatable {
    public var enabled = true
    public var stripWidth: CGFloat = 190
    public var side: ScreenSide = .left

    public init() {}

    private enum CodingKeys: String, CodingKey { case enabled, stripWidth, side }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = (try? c.decodeIfPresent(Bool.self, forKey: .enabled)) ?? true
        stripWidth = (try? c.decodeIfPresent(CGFloat.self, forKey: .stripWidth)) ?? 190
        side = (try? c.decodeIfPresent(ScreenSide.self, forKey: .side)) ?? .left
    }
}

/// All settings of the multi-window modes, stored under one key. Decoding tolerates missing or bad fields.
public struct MultiWindowOptions: Codable, Equatable {
    /// Maximum windows per row for row/grid tiling; 0 = unlimited.
    public var maxPerRow = 0
    /// Maximum windows per column for column tiling; 0 = unlimited.
    public var maxPerColumn = 0
    /// The last row/column stretches to fill the area.
    public var balancedGrid = true
    /// Lay windows out across all displays together instead of the active display only.
    public var combinedDisplays = false
    /// Step between cascaded windows.
    public var cascadeOffset: CGFloat = 30
    /// Step between stacked windows.
    public var stackOffset: CGFloat = 24
    /// Give all stacked windows one common size.
    public var stackSameSize = true
    public var showStackBadge = true
    /// Name of the action applied to every new window; nil = off.
    public var newWindowAction: String?
    public var todo = TodoOptions()
    public var stageManager = StageManagerOptions()

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case maxPerRow, maxPerColumn, balancedGrid, combinedDisplays, cascadeOffset, stackOffset
        case stackSameSize, showStackBadge, newWindowAction, todo, stageManager
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func value<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            ((try? c.decodeIfPresent(T.self, forKey: key)) ?? nil) ?? fallback
        }
        maxPerRow = max(0, value(.maxPerRow, 0))
        maxPerColumn = max(0, value(.maxPerColumn, 0))
        balancedGrid = value(.balancedGrid, true)
        combinedDisplays = value(.combinedDisplays, false)
        cascadeOffset = max(1, value(.cascadeOffset, 30))
        stackOffset = max(1, value(.stackOffset, 24))
        stackSameSize = value(.stackSameSize, true)
        showStackBadge = value(.showStackBadge, true)
        newWindowAction = (try? c.decodeIfPresent(String.self, forKey: .newWindowAction)) ?? nil
        todo = value(.todo, TodoOptions())
        stageManager = value(.stageManager, StageManagerOptions())
    }
}

public extension SettingKey {
    /// Multi-window modes (tiling, cascade, stack, Todo, Stage Manager, new-window action).
    static var multiWindowOptions: SettingKey<MultiWindowOptions> {
        .init("multiWindowOptions", default: MultiWindowOptions())
    }
}
