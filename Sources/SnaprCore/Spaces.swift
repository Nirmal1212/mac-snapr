import Foundation

public extension SettingKey {
    /// Experimental: moving windows between Spaces relies on private APIs. Default OFF and deliberately
    /// excluded from config import/export so a file can never switch it on.
    static var spacesEnabled: SettingKey<Bool> { .init("spacesEnabled", default: false) }
}

/// Moves windows between Spaces. The only implementation that touches private APIs lives in the app
/// target (`PrivateSpaceMover`); everything here is plain Swift and testable with a mock.
public protocol SpaceMoving: AnyObject {
    /// False when the required system functionality could not be found on this macOS version.
    var isAvailable: Bool { get }
    /// Number of Spaces on the display currently holding `window`.
    func spaceCount(of window: WindowID) -> Int?
    /// One-based index of the Space holding `window` on its display.
    func spaceIndex(of window: WindowID) -> Int?
    /// Asks the system to move the window; the result is not trusted (see `SpaceActionController`).
    func move(_ window: WindowID, toSpaceIndex index: Int) -> Bool
}

public enum SpaceMoveResult: Equatable {
    case moved(toIndex: Int)
    case disabled
    case unavailable
    case noWindow
    /// Target does not exist (for example "next" on the last Space) or is where the window already is.
    case noChange
    /// The system call failed or the window's Space did not change.
    case failed
}

/// Applies the safety rules for Space moves: feature flag, availability and verification.
public final class SpaceActionController {
    private let settings: SettingsStore
    private let windows: WindowProvider
    private let mover: SpaceMoving?
    private let log: DebugLog?

    public init(settings: SettingsStore, windows: WindowProvider, mover: SpaceMoving?, log: DebugLog? = nil) {
        self.settings = settings
        self.windows = windows
        self.mover = mover
        self.log = log
    }

    /// Whether Space actions are currently usable (flag on and mover present and available).
    public var isActive: Bool { settings.get(.spacesEnabled) && (mover?.isAvailable ?? false) }

    @discardableResult
    public func perform(_ target: SpaceTarget) -> SpaceMoveResult {
        let result = run(target)
        log?.log("space \(target) -> \(result)")
        return result
    }

    private func run(_ target: SpaceTarget) -> SpaceMoveResult {
        guard settings.get(.spacesEnabled) else { return .disabled }
        guard let mover, mover.isAvailable else { return .unavailable }
        guard let window = windows.focusedWindow() else { return .noWindow }
        guard let current = mover.spaceIndex(of: window.id), let count = mover.spaceCount(of: window.id), count > 0
        else { return .failed }
        let destination: Int
        switch target {
        case .next: destination = current + 1
        case .previous: destination = current - 1
        case .index(let n): destination = n
        }
        guard (1...count).contains(destination), destination != current else { return .noChange }
        guard mover.move(window.id, toSpaceIndex: destination) else { return .failed }
        // The call may succeed without effect (restricted on newer macOS); only report what is verified.
        return mover.spaceIndex(of: window.id) == destination ? .moved(toIndex: destination) : .failed
    }
}

/// Test double for `SpaceMoving`.
public final class MockSpaceMover: SpaceMoving {
    public var isAvailable = true
    public var count = 4
    public var indices: [WindowID: Int] = [:]
    /// When false, `move` reports success but leaves the window where it is.
    public var movesWindows = true
    public private(set) var moveCalls: [(WindowID, Int)] = []

    public init() {}

    public func spaceCount(of window: WindowID) -> Int? { indices[window] == nil ? nil : count }
    public func spaceIndex(of window: WindowID) -> Int? { indices[window] }

    public func move(_ window: WindowID, toSpaceIndex index: Int) -> Bool {
        moveCalls.append((window, index))
        if movesWindows { indices[window] = index }
        return true
    }
}
