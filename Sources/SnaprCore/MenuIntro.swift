import Foundation

public extension SettingKey {
    /// Whether the menu bar popover opens on the intro page (every open) instead of the actions list.
    static var showIntroOnOpen: SettingKey<Bool> { .init("showIntroOnOpen", default: true) }
}

/// The two pages of the menu bar popover.
public enum MenuPage: Equatable {
    case intro
    case actions
}

/// Page selection for the menu bar popover. Pure so it can be tested without a UI.
///
/// Every open starts on the intro page unless the user turned it off, in which case the popover
/// opens on the actions page. The user can move between the pages while the popover is open.
public struct MenuPopoverState: Equatable {
    public private(set) var page: MenuPage

    public init(introEnabled: Bool = true) {
        page = introEnabled ? .intro : .actions
    }

    /// Called every time the popover is shown; resets the page.
    public mutating func didOpen(introEnabled: Bool) {
        page = introEnabled ? .intro : .actions
    }

    public mutating func showActions() { page = .actions }
    public mutating func showIntro() { page = .intro }
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
