import CoreGraphics

/// Applies a chosen action to every new window, detected by diffing window sets between scans.
/// The first scan after the option is turned on only records the windows that already exist.
public final class NewWindowMonitor {
    private let list: WindowListProvider
    private let options: () -> MultiWindowOptions
    private let apply: (SnapAction, ManagedWindow) -> Void
    private var known: Set<WindowID> = []
    private var started = false

    /// Windows smaller than this are still being created; they are retried on the next scan.
    static let minimumSize = CGSize(width: 50, height: 50)
    /// Bound on tracked windows (guards memory if an app spawns windows endlessly).
    static let maxTracked = 2000

    public init(
        list: WindowListProvider, options: @escaping () -> MultiWindowOptions,
        apply: @escaping (SnapAction, ManagedWindow) -> Void
    ) {
        self.list = list
        self.options = options
        self.apply = apply
    }

    /// Whether the option is currently set to a known action.
    public var isEnabled: Bool { configuredAction() != nil }

    private func configuredAction() -> SnapAction? {
        options().newWindowAction.flatMap(ActionRegistry.action(named:))
    }

    /// Checks for new windows. Returns the windows the action was applied to.
    @discardableResult
    public func scan() -> [WindowID] {
        guard let action = configuredAction() else {
            known = []
            started = false
            return []
        }
        let current = list.allWindows()
        defer { if known.count > Self.maxTracked { known = Set(current.map(\.id)) } }
        guard started else {
            known = Set(current.map(\.id))
            started = true
            return []
        }
        var handled: [WindowID] = []
        var next: Set<WindowID> = []
        for window in current {
            if known.contains(window.id) {
                next.insert(window.id)
            } else if window.frame.width >= Self.minimumSize.width, window.frame.height >= Self.minimumSize.height {
                next.insert(window.id)
                handled.append(window.id)
                apply(action, window)
            }
        }
        known = next
        return handled
    }
}
