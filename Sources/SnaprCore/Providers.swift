import CoreGraphics

public struct WindowID: Hashable {
    public var rawValue: Int
    public init(_ rawValue: Int) { self.rawValue = rawValue }
}

public struct WindowInfo: Equatable {
    public var id: WindowID
    public var frame: CGRect
    public var canMove: Bool
    public var canResize: Bool

    public init(id: WindowID, frame: CGRect, canMove: Bool = true, canResize: Bool = true) {
        self.id = id
        self.frame = frame
        self.canMove = canMove
        self.canResize = canResize
    }
}

/// Access to other applications' windows. Frames use the top-left/y-down global space.
public protocol WindowProvider: AnyObject {
    /// The focused window of the frontmost app other than Snapr itself.
    func focusedWindow() -> WindowInfo?
    /// The window under a global point (used by drag snapping).
    func window(at point: CGPoint) -> WindowInfo?
    /// The current frame of a previously returned window (used to detect window drags).
    func currentFrame(of id: WindowID) -> CGRect?
    /// Applies a frame; returns the frame the window actually ended up with, or nil on failure.
    @discardableResult
    func setFrame(_ frame: CGRect, for id: WindowID) -> CGRect?
}

public protocol ScreenProvider: AnyObject {
    func screens() -> [ScreenInfo]
}

// MARK: - Mocks

public final class MockWindowProvider: WindowProvider {
    public var windows: [WindowID: WindowInfo]
    public var focusedID: WindowID?
    /// Minimum size a window enforces, mimicking apps with size limits.
    public var minimumSize: CGSize = .zero
    public private(set) var setFrameCalls: [(WindowID, CGRect)] = []

    public init(windows: [WindowInfo] = [], focused: WindowID? = nil) {
        self.windows = Dictionary(uniqueKeysWithValues: windows.map { ($0.id, $0) })
        self.focusedID = focused ?? windows.first?.id
    }

    public func focusedWindow() -> WindowInfo? { focusedID.flatMap { windows[$0] } }

    public func window(at point: CGPoint) -> WindowInfo? {
        windows.values.first { $0.frame.contains(point) }
    }

    public func currentFrame(of id: WindowID) -> CGRect? { windows[id]?.frame }

    @discardableResult
    public func setFrame(_ frame: CGRect, for id: WindowID) -> CGRect? {
        guard var window = windows[id], window.canMove else { return nil }
        setFrameCalls.append((id, frame))
        var result = frame
        if window.canResize {
            result.size = CGSize(
                width: max(frame.width, minimumSize.width), height: max(frame.height, minimumSize.height))
        } else {
            result.size = window.frame.size
        }
        window.frame = result
        windows[id] = window
        return result
    }
}

public final class MockScreenProvider: ScreenProvider {
    public var list: [ScreenInfo]
    public init(_ list: [ScreenInfo]) { self.list = list }
    public func screens() -> [ScreenInfo] { list }
}
