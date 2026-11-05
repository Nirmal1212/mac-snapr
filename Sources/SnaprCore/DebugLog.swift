import Combine
import Foundation

/// Bounded in-memory log shown in the debug viewer. Nothing is written to disk or sent anywhere.
public final class DebugLog: ObservableObject {
    public struct Entry: Equatable {
        public let date: Date
        public let message: String
    }

    @Published public private(set) var entries: [Entry] = []
    public let capacity: Int
    /// Entries are only recorded while this returns true (backed by the `debugLogging` hidden preference).
    public var isEnabled: () -> Bool
    private let now: () -> Date

    public init(capacity: Int = 500, now: @escaping () -> Date = Date.init, isEnabled: @escaping () -> Bool = { true }) {
        self.capacity = capacity
        self.now = now
        self.isEnabled = isEnabled
    }

    public func log(_ message: String) {
        guard isEnabled() else { return }
        entries.append(Entry(date: now(), message: message))
        if entries.count > capacity { entries.removeFirst(entries.count - capacity) }
    }

    public func clear() { entries.removeAll() }

    public var text: String {
        let formatter = ISO8601DateFormatter()
        return entries.map { "\(formatter.string(from: $0.date)) \($0.message)" }.joined(separator: "\n")
    }
}
