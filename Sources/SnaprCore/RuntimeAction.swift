import Foundation

/// Which Space a "move to Space" action targets.
public enum SpaceTarget: Hashable {
    case next
    case previous
    /// One-based Space number on the window's display.
    case index(Int)

    public static let maxIndex = 16
}

/// An action defined at run time, next to the closed `SnapAction` enum.
///
/// Names are stable and URL friendly: `custom:<id>` (custom zone), `layout:<id>` (saved layout) and
/// `space:next|previous|<n>`. Ids are validated by `isValidID` before any lookup.
public enum RuntimeAction: Hashable {
    case zone(String)
    case layout(String)
    case space(SpaceTarget)

    /// Ids are 1...64 characters of `a-z`, `0-9` and `-`.
    public static func isValidID(_ id: String) -> Bool {
        guard !id.isEmpty, id.utf8.count <= 64 else { return false }
        return id.utf8.allSatisfy { ($0 >= 97 && $0 <= 122) || ($0 >= 48 && $0 <= 57) || $0 == 45 }
    }

    public var name: String {
        switch self {
        case .zone(let id): return "custom:\(id)"
        case .layout(let id): return "layout:\(id)"
        case .space(.next): return "space:next"
        case .space(.previous): return "space:previous"
        case .space(.index(let n)): return "space:\(n)"
        }
    }

    /// Parses a runtime action name; nil for anything malformed (including invalid ids).
    public static func parse(_ name: String) -> RuntimeAction? {
        guard name.utf8.count <= 80, let colon = name.firstIndex(of: ":") else { return nil }
        let kind = name[..<colon]
        let rest = String(name[name.index(after: colon)...])
        switch kind {
        case "custom": return isValidID(rest) ? .zone(rest) : nil
        case "layout": return isValidID(rest) ? .layout(rest) : nil
        case "space":
            switch rest {
            case "next": return .space(.next)
            case "previous": return .space(.previous)
            default:
                guard rest.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }), let n = Int(rest),
                    (1...SpaceTarget.maxIndex).contains(n)
                else { return nil }
                return .space(.index(n))
            }
        default: return nil
        }
    }
}

/// Carries out runtime actions. Implemented by `RuntimeActionRunner`.
public protocol RuntimeActionPerforming: AnyObject {
    /// Whether the action refers to something that exists (zone / layout id known; Space targets are always known).
    func exists(_ action: RuntimeAction) -> Bool
    /// Performs the action; returns true if something was changed.
    @discardableResult
    func perform(_ action: RuntimeAction) -> Bool
}
