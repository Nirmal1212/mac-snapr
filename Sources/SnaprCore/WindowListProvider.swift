import CoreGraphics

/// A window of any app, as listed for multi-window actions.
public struct ManagedWindow: Equatable {
    public var id: WindowID
    public var frame: CGRect
    public var bundleID: String?
    /// Belongs to the frontmost app (other than Snapr).
    public var isActiveApp: Bool
    public var canMove: Bool
    public var canResize: Bool

    public init(
        id: WindowID, frame: CGRect, bundleID: String? = nil, isActiveApp: Bool = false,
        canMove: Bool = true, canResize: Bool = true
    ) {
        self.id = id
        self.frame = frame
        self.bundleID = bundleID
        self.isActiveApp = isActiveApp
        self.canMove = canMove
        self.canResize = canResize
    }

    public var info: WindowInfo { WindowInfo(id: id, frame: frame, canMove: canMove, canResize: canResize) }
}

/// Lists the windows of all apps. Frames use the global top-left/y-down space. Implementations must
/// register the returned windows so `WindowProvider.setFrame(_:for:)` can address them.
public protocol WindowListProvider: AnyObject {
    /// Visible, standard, non-minimized windows, the frontmost app first and front to back within an app.
    func allWindows() -> [ManagedWindow]
    /// Brings a window to the front (and activates its app).
    func raise(_ id: WindowID)
}

/// Test double; `windows` is the front-to-back list and `raise` moves a window to the front.
public final class MockWindowListProvider: WindowListProvider {
    public var windows: [ManagedWindow]
    public private(set) var raised: [WindowID] = []
    /// Reflects frames set through a `MockWindowProvider` in later listings.
    public weak var frameSource: MockWindowProvider?

    public init(_ windows: [ManagedWindow] = []) { self.windows = windows }

    public func allWindows() -> [ManagedWindow] {
        windows.map { window in
            var copy = window
            if let frame = frameSource?.windows[window.id]?.frame { copy.frame = frame }
            return copy
        }
    }

    public func raise(_ id: WindowID) {
        raised.append(id)
        if let index = windows.firstIndex(where: { $0.id == id }) {
            windows.insert(windows.remove(at: index), at: 0)
        }
    }
}
