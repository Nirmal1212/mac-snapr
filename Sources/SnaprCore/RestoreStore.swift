import CoreGraphics

/// In-memory store of each window's pre-snap frame.
public final class RestoreStore {
    private var frames: [WindowID: CGRect] = [:]

    public init() {}

    public func frame(for id: WindowID) -> CGRect? { frames[id] }

    /// Records `frame` unless one is already stored (or `overwrite` is set).
    public func record(_ frame: CGRect, for id: WindowID, overwrite: Bool = false) {
        if overwrite || frames[id] == nil { frames[id] = frame }
    }

    /// Returns and removes the stored frame.
    public func take(_ id: WindowID) -> CGRect? { frames.removeValue(forKey: id) }

    public func clear(_ id: WindowID) { frames[id] = nil }
}
