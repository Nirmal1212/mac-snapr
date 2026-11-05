import Foundation

public extension SettingKey {
    /// True once the welcome intro has been displayed. Per-user UI state: deliberately not part of config export.
    static var introSeen: SettingKey<Bool> { .init("introSeen", default: false) }
}

/// The two pages of the menu bar popover.
public enum MenuPage: Equatable {
    case intro
    case actions
}

/// Page selection for the menu bar popover. Pure so it can be tested without a UI.
///
/// The first open for a user shows the intro page; after it has been displayed once, every open starts on
/// the actions page. The "Intro" header button and "Show welcome intro again" (Settings) bring it back.
public struct MenuPopoverState: Equatable {
    public private(set) var page: MenuPage

    public init(introSeen: Bool = false) {
        page = introSeen ? .actions : .intro
    }

    /// Called every time the popover is shown. Returns true when the intro is now displayed for the first
    /// time and the caller should record `introSeen`.
    @discardableResult
    public mutating func didOpen(introSeen: Bool) -> Bool {
        page = introSeen ? .actions : .intro
        return !introSeen
    }

    public mutating func showActions() { page = .actions }
    public mutating func showIntro() { page = .intro }
}

/// Display order of actions in the menu bar popover. `ActionCategory` (Settings, URLs, search) is untouched.
public enum PopoverActionLayout {
    public struct Group: Equatable {
        public let title: String
        public let actions: [SnapAction]
    }

    public static let sizeActions: [SnapAction] = [.maximize, .center, .restore, .maximizeHeight]
    public static let sizeTitle = "Maximize & Center"

    /// `ActionRegistry.grouped()` with Maximize, Center, Restore and Maximize Height pulled out of their
    /// categories into one group directly after Quarters (or after Halves if Quarters is absent).
    public static func groups() -> [Group] {
        let moved = Set(sizeActions)
        var result: [Group] = []
        var inserted = false
        let size = Group(title: sizeTitle, actions: sizeActions.filter { ActionRegistry.all.contains($0) })
        for g in ActionRegistry.grouped() {
            let rest = g.actions.filter { !moved.contains($0) }
            if !rest.isEmpty { result.append(Group(title: g.category.rawValue, actions: rest)) }
            if g.category == .quarters {
                result.append(size)
                inserted = true
            }
        }
        if !inserted { result.insert(size, at: min(2, result.count)) }
        return result
    }
}

/// Text shown on the intro page.
public enum IntroContent {
    public static let summary =
        "Snapr snaps windows to halves, quarters, thirds and more with keyboard shortcuts or by dragging to a screen edge."

    /// Tip 1: a real shortcut from the user's current bindings (left half), or a generic hint when unbound.
    public static func shortcutTip(_ map: ShortcutMap) -> String {
        if let combo = map.combo(for: .leftHalf) {
            return "Press \(combo.displayString) to snap the focused window to the left half of the screen."
        }
        return "Assign a shortcut to “Left Half” in Settings to snap the focused window with the keyboard."
    }

    public static let dragTip = "Drag a window to a screen edge or corner to snap it."
    public static let settingsTip = "Open Settings to change shortcuts, gaps and more."
}

/// Remembers the last app that was frontmost other than Snapr itself.
///
/// The popover activates Snapr, so by the time an action runs the frontmost app may be Snapr. Window
/// actions therefore target the last external app, whose focused window did not change while the
/// popover was open.
public struct ExternalAppTracker: Equatable {
    public let ownPID: pid_t
    public private(set) var lastExternalPID: pid_t?

    public init(ownPID: pid_t, initialFrontmost: pid_t? = nil) {
        self.ownPID = ownPID
        if let initialFrontmost, initialFrontmost != ownPID { lastExternalPID = initialFrontmost }
    }

    /// Feed every app activation; activations of Snapr itself are ignored.
    public mutating func activated(pid: pid_t) {
        guard pid != ownPID else { return }
        lastExternalPID = pid
    }
}
