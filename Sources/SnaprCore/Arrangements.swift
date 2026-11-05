import CoreGraphics
import Foundation

/// One window of a saved layout, positioned relative to a screen.
public struct LayoutEntry: Codable, Equatable {
    public var bundleID: String
    /// Window title at capture time; used to tell windows of the same app apart.
    public var title: String?
    /// Index of the screen in left-to-right order (`ScreenGeometry.ordered`).
    public var screenIndex: Int
    /// Frame as fractions of that screen's visible frame.
    public var rect: FractionRect

    public init(bundleID: String, title: String? = nil, screenIndex: Int, rect: FractionRect) {
        self.bundleID = bundleID
        self.title = title
        self.screenIndex = screenIndex
        self.rect = rect
    }

    public var isValid: Bool {
        AutomationURL.isValidBundleID(bundleID) && screenIndex >= 0 && screenIndex < 32 && rect.isValid
    }
}

/// A named arrangement of windows that can be re-applied.
public struct SavedLayout: Codable, Equatable, Identifiable {
    public static let maxEntries = 100

    public var id: String
    public var name: String
    public var entries: [LayoutEntry]
    public var shortcut: KeyCombo?

    public init(id: String, name: String, entries: [LayoutEntry], shortcut: KeyCombo? = nil) {
        self.id = id
        self.name = name
        self.entries = entries
        self.shortcut = shortcut
    }

    private enum CodingKeys: String, CodingKey { case id, name, entries, shortcut }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        entries = (try c.decodeIfPresent(LossyArray<LayoutEntry>.self, forKey: .entries))?.elements ?? []
        shortcut = (try? c.decodeIfPresent(KeyCombo.self, forKey: .shortcut)) ?? nil
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(entries, forKey: .entries)
        try c.encodeIfPresent(shortcut, forKey: .shortcut)
    }

    public var isValid: Bool {
        RuntimeAction.isValidID(id) && CustomLayoutStore.isValidName(name) && entries.count <= Self.maxEntries
            && entries.allSatisfy(\.isValid)
    }

    public var action: RuntimeAction { .layout(id) }
}

/// A window as seen when capturing or applying a layout.
public struct ListedWindow: Equatable {
    public var info: WindowInfo
    public var bundleID: String
    public var title: String

    public init(info: WindowInfo, bundleID: String, title: String) {
        self.info = info
        self.bundleID = bundleID
        self.title = title
    }
}

/// Lists the visible, standard windows of running apps (Accessibility-backed in the app target).
public protocol WindowLister: AnyObject {
    func listWindows() -> [ListedWindow]
}

public final class MockWindowLister: WindowLister {
    public var windows: [ListedWindow]
    public init(_ windows: [ListedWindow] = []) { self.windows = windows }
    public func listWindows() -> [ListedWindow] { windows }
}

public struct PlannedPlacement: Equatable {
    public var window: ListedWindow
    public var screen: ScreenInfo
    public var frame: CGRect
}

/// Pure capture and matching for saved layouts.
public enum ArrangementPlanner {
    /// Entries describing `windows` (in the given order), skipping windows without a bundle id, that cannot
    /// move, or that lie outside every screen.
    public static func capture(windows: [ListedWindow], screens: [ScreenInfo]) -> [LayoutEntry] {
        let ordered = ScreenGeometry.ordered(screens)
        var entries: [LayoutEntry] = []
        for window in windows where window.info.canMove && AutomationURL.isValidBundleID(window.bundleID) {
            guard entries.count < SavedLayout.maxEntries,
                let screen = ScreenGeometry.screen(containing: window.info.frame, in: ordered),
                let index = ordered.firstIndex(where: { $0.id == screen.id }),
                let rect = FractionRect.of(window.info.frame, in: screen.visibleFrame)
            else { continue }
            let title = window.title.isEmpty ? nil : String(window.title.prefix(200))
            entries.append(LayoutEntry(bundleID: window.bundleID, title: title, screenIndex: index, rect: rect))
        }
        return entries
    }

    /// Matches entries to open windows: same bundle id with identical title first, then the next unused
    /// window of that app. Each window is used at most once; entries without a match are skipped.
    public static func plan(layout: SavedLayout, windows: [ListedWindow], screens: [ScreenInfo]) -> [PlannedPlacement] {
        let ordered = ScreenGeometry.ordered(screens)
        guard !ordered.isEmpty else { return [] }
        var used = Set<WindowID>()
        var result: [PlannedPlacement] = []
        func candidate(for entry: LayoutEntry) -> ListedWindow? {
            let pool = windows.filter { $0.bundleID == entry.bundleID && $0.info.canMove && !used.contains($0.info.id) }
            if let title = entry.title, let exact = pool.first(where: { $0.title == title }) { return exact }
            return pool.first
        }
        // Titled entries claim their exact matches first so untitled fallbacks cannot steal them.
        var claimed: [Int: ListedWindow] = [:]
        for (index, entry) in layout.entries.enumerated() {
            guard let title = entry.title else { continue }
            if let exact = windows.first(where: {
                $0.bundleID == entry.bundleID && $0.title == title && $0.info.canMove && !used.contains($0.info.id)
            }) {
                used.insert(exact.info.id)
                claimed[index] = exact
            }
        }
        for (index, entry) in layout.entries.enumerated() {
            guard let window = claimed[index] ?? candidate(for: entry) else { continue }
            used.insert(window.info.id)
            let screen = ordered[min(entry.screenIndex, ordered.count - 1)]
            result.append(
                PlannedPlacement(
                    window: window, screen: screen,
                    frame: LayoutEngine.pixelAligned(entry.rect.frame(in: screen.visibleFrame))))
        }
        return result
    }
}
