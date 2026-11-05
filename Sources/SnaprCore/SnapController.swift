import CoreGraphics

/// Orchestrates actions against the focused window using injected providers.
public final class SnapController {
    private struct LastSnap {
        var action: SnapAction
        var step: Int
        var frame: CGRect
    }

    private let windows: WindowProvider
    private let screens: ScreenProvider
    public let restoreStore: RestoreStore
    private var lastSnap: [WindowID: LastSnap] = [:]
    /// Rules for moving windows between displays.
    public var displayRules = DisplayRules()
    /// Moves the cursor when `displayRules.moveCursorWithWindow` is on.
    public var cursor: CursorProvider?

    public init(windows: WindowProvider, screens: ScreenProvider, restoreStore: RestoreStore = RestoreStore()) {
        self.windows = windows
        self.screens = screens
        self.restoreStore = restoreStore
    }

    /// Performs `action` on the focused window. Returns true if a window was changed.
    @discardableResult
    public func perform(_ action: SnapAction) -> Bool {
        guard let window = windows.focusedWindow() else { return false }
        return perform(action, on: window)
    }

    /// Performs `action` on `window`.
    /// - Parameters:
    ///   - screen: screen to snap on; defaults to the screen containing the window's center.
    ///   - restoreFrame: frame to remember for Restore; defaults to the window's current frame.
    @discardableResult
    public func perform(
        _ action: SnapAction, on window: WindowInfo, screen: ScreenInfo? = nil, restoreFrame: CGRect? = nil
    ) -> Bool {
        guard window.canMove else { return false }
        let all = screens.screens()
        guard let current = screen ?? ScreenGeometry.screen(containing: window.frame, in: all) else { return false }

        switch action {
        case .restore:
            guard let frame = restoreStore.frame(for: window.id) else { return false }
            guard apply(frame, to: window, bounds: current.visibleFrame) != nil else { return false }
            restoreStore.clear(window.id)
            lastSnap[window.id] = nil
            return true

        case .nextDisplay, .previousDisplay:
            guard let destination = ScreenGeometry.neighbor(
                of: current, in: all, forward: action == .nextDisplay, byX: displayRules.orderByX)
            else { return false }
            return move(window, from: current, to: destination)

        default:
            let previous = lastSnap[window.id]
            let stillSnapped = previous.map { WindowGeometry.approximatelyEqual(window.frame, $0.frame) } ?? false
            var step = 0
            let cycleLength = WindowGeometry.cycleLength(for: action)
            if let previous, stillSnapped, previous.action == action, cycleLength > 1 {
                step = (previous.step + 1) % cycleLength
            }
            guard let target = WindowGeometry.frame(
                for: action, in: current.visibleFrame, current: window.frame, step: step)
            else { return false }

            // Keep the oldest pre-snap frame while the window is still where we left it; otherwise
            // the user moved it manually, so the current frame becomes the new restore point.
            restoreStore.record(restoreFrame ?? window.frame, for: window.id, overwrite: !stillSnapped)
            guard let result = apply(target, to: window, bounds: current.visibleFrame) else { return false }
            lastSnap[window.id] = LastSnap(action: action, step: step, frame: result)
            return true
        }
    }

    /// Sets the frame, degrading gracefully for fixed-size windows and size-limited apps.
    private func apply(_ target: CGRect, to window: WindowInfo, bounds: CGRect) -> CGRect? {
        var frame = target
        if !window.canResize {
            frame = WindowGeometry.clamped(CGRect(origin: target.origin, size: window.frame.size), to: bounds)
        }
        guard let result = windows.setFrame(frame, for: window.id) else { return nil }
        // An app with a minimum size may overflow the target; pull it back inside if only a move is needed.
        let fixed = WindowGeometry.clamped(result, to: bounds)
        if fixed.size == result.size, !WindowGeometry.approximatelyEqual(fixed, result, tolerance: 1) {
            return windows.setFrame(fixed, for: window.id) ?? result
        }
        return result
    }
}

// MARK: - Advanced input support

extension SnapController {
    /// Places `window` at an arbitrary `frame` on `screen` (drag zones without a keyboard action).
    @discardableResult
    public func snap(_ window: WindowInfo, toFrame target: CGRect, screen: ScreenInfo, restoreFrame: CGRect? = nil) -> Bool {
        guard window.canMove else { return false }
        let stillSnapped = lastSnap[window.id].map { WindowGeometry.approximatelyEqual(window.frame, $0.frame) } ?? false
        restoreStore.record(restoreFrame ?? window.frame, for: window.id, overwrite: !stillSnapped)
        lastSnap[window.id] = nil
        return apply(target, to: window, bounds: screen.visibleFrame) != nil
    }

    /// Moves a window to another display, honoring `displayRules`.
    fileprivate func move(_ window: WindowInfo, from current: ScreenInfo, to destination: ScreenInfo) -> Bool {
        let bounds = destination.visibleFrame
        let previous = lastSnap[window.id]
        let stillSnapped = previous.map { WindowGeometry.approximatelyEqual(window.frame, $0.frame) } ?? false
        var repeated: LastSnap?
        let target: CGRect
        if displayRules.keepSizeWhenMaximized,
            WindowGeometry.approximatelyEqual(window.frame, current.visibleFrame, tolerance: 4) {
            target = WindowGeometry.centered(size: window.frame.size, in: bounds)
        } else if displayRules.repeatLastAction, stillSnapped, let previous,
            let frame = WindowGeometry.frame(for: previous.action, in: bounds, current: window.frame, step: previous.step) {
            target = frame
            repeated = previous
        } else {
            let moved = WindowGeometry.relativeFrame(window.frame, from: current.visibleFrame, to: bounds)
            target = WindowGeometry.clamped(moved, to: bounds)
        }
        lastSnap[window.id] = nil
        guard let result = apply(target, to: window, bounds: bounds) else { return false }
        if var repeated {
            repeated.frame = result
            lastSnap[window.id] = repeated
        }
        if displayRules.moveCursorWithWindow { cursor?.move(to: CGPoint(x: result.midX, y: result.midY)) }
        return true
    }
}
