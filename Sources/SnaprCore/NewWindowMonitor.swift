import CoreGraphics

/// Applies a chosen action to every new window, detected by diffing window sets between scans.
/// The first scan after the option is turned on only records the windows that already exist.
public final class NewWindowMonitor {
    private let list: WindowListProvider
    private let options: () -> MultiWindowOptions
    private let apply: (SnapAction, ManagedWindow) -> Void
    /// Window id -> scan number it was last seen. Ids are kept while a window is minimized, hidden or on
    /// another Space (the listing omits those), so it does not look new when it comes back.
    private var known: [WindowID: Int] = [:]
    private var scanNumber = 0
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
        options().newWindowAction.flatMap(ActionRegistry.action(named:)).flatMap { $0.isMultiWindow ? nil : $0 }
    }

    /// Checks for new windows. Returns the windows the action was applied to.
    @discardableResult
    public func scan() -> [WindowID] {
        guard let action = configuredAction() else {
            known = [:]
            started = false
            return []
        }
        let current = list.allWindows()
        scanNumber += 1
        guard started else {
            known = Dictionary(current.map { ($0.id, scanNumber) }, uniquingKeysWith: { a, _ in a })
            started = true
            return []
        }
        var handled: [WindowID] = []
        for window in current {
            if known[window.id] != nil {
                known[window.id] = scanNumber
            } else if window.frame.width >= Self.minimumSize.width, window.frame.height >= Self.minimumSize.height {
                known[window.id] = scanNumber
                handled.append(window.id)
                apply(action, window)
            }
        }
        if known.count > Self.maxTracked {
            // Forget the ids unseen the longest.
            let keep = known.sorted { $0.value > $1.value }.prefix(Self.maxTracked)
            known = Dictionary(uniqueKeysWithValues: keep.map { ($0.key, $0.value) })
        }
        return handled
    }
}
