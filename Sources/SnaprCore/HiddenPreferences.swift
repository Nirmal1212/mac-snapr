import Foundation

/// Advanced options read natively from user defaults, so they can be set with
/// `defaults write com.you.snapr <key> -bool true` (or `-array`). Absent or mistyped values use defaults.
public struct HiddenPreferences {
    public enum Key {
        public static let debugLogging = "debugLogging"
        public static let enhancedUIHandling = "enhancedUIHandling"
        public static let nativeResizeApps = "nativeResizeApps"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    private func bool(_ key: String, default value: Bool) -> Bool {
        (defaults.object(forKey: key) as? NSNumber)?.boolValue ?? value
    }

    /// Record events in the debug log. Default off.
    public var debugLogging: Bool { bool(Key.debugLogging, default: false) }

    /// Temporarily disable apps' Enhanced User Interface while resizing. Default on.
    public var enhancedUIHandling: Bool { bool(Key.enhancedUIHandling, default: true) }

    /// Extra native-resize apps given via `defaults write`; merged with the in-app list.
    public var nativeResizeApps: [String] {
        defaults.array(forKey: Key.nativeResizeApps)?.compactMap { $0 as? String } ?? []
    }
}

/// Per-app window-handling quirks combining settings and hidden preferences.
public struct WindowCompatibility {
    private let settings: SettingsStore
    private let hidden: HiddenPreferences

    public init(settings: SettingsStore, hidden: HiddenPreferences = HiddenPreferences()) {
        self.settings = settings
        self.hidden = hidden
    }

    public func usesNativeResize(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return settings.get(.nativeResizeApps).contains(bundleID) || hidden.nativeResizeApps.contains(bundleID)
    }

    public var handlesEnhancedUI: Bool { hidden.enhancedUIHandling }
}
