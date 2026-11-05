import Foundation

/// Modifier flags using Carbon's raw values so they can be passed straight to `RegisterEventHotKey`.
public struct KeyModifiers: OptionSet, Codable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }

    public static let command = KeyModifiers(rawValue: 1 << 8)
    public static let shift = KeyModifiers(rawValue: 1 << 9)
    public static let option = KeyModifiers(rawValue: 1 << 11)
    public static let control = KeyModifiers(rawValue: 1 << 12)
}

/// A virtual key code plus modifiers.
public struct KeyCombo: Codable, Hashable {
    public var keyCode: UInt32
    public var modifiers: KeyModifiers

    public init(keyCode: UInt32, modifiers: KeyModifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public var displayString: String {
        var text = ""
        if modifiers.contains(.control) { text += "⌃" }
        if modifiers.contains(.option) { text += "⌥" }
        if modifiers.contains(.shift) { text += "⇧" }
        if modifiers.contains(.command) { text += "⌘" }
        return text + (KeyCombo.keyNames[keyCode] ?? "Key\(keyCode)")
    }

    // Virtual key codes (kVK_ANSI_* etc. from Carbon HIToolbox).
    public enum Key {
        public static let left: UInt32 = 123
        public static let right: UInt32 = 124
        public static let down: UInt32 = 125
        public static let up: UInt32 = 126
        public static let returnKey: UInt32 = 36
        public static let delete: UInt32 = 51
        public static let escape: UInt32 = 53
        public static let c: UInt32 = 8
        public static let d: UInt32 = 2
        public static let e: UInt32 = 14
        public static let f: UInt32 = 3
        public static let g: UInt32 = 5
        public static let i: UInt32 = 34
        public static let j: UInt32 = 38
        public static let k: UInt32 = 40
        public static let t: UInt32 = 17
        public static let u: UInt32 = 32
    }

    private static let keyNames: [UInt32: String] = [
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H", 34: "I", 38: "J", 40: "K",
        37: "L", 46: "M", 45: "N", 31: "O", 35: "P", 12: "Q", 15: "R", 1: "S", 17: "T", 32: "U",
        9: "V", 13: "W", 7: "X", 16: "Y", 6: "Z",
        18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
        27: "-", 24: "=", 33: "[", 30: "]", 41: ";", 39: "'", 43: ",", 47: ".", 44: "/", 42: "\\", 50: "`",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋", 117: "⌦",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12"
    ]

    /// Whether the combo is acceptable for a global shortcut (needs a modifier unless it is a function key).
    public var isValidGlobalShortcut: Bool {
        if !modifiers.isEmpty { return true }
        return [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111].contains(keyCode)
    }
}

/// Default key bindings. Actions without an entry are simply unbound until the user assigns one.
public enum DefaultShortcuts {
    /// Default modifier set. Ctrl+Opt avoids the common system shortcuts that use Ctrl+Cmd.
    public static let base: KeyModifiers = [.control, .option]

    public static func combo(for action: SnapAction) -> KeyCombo? {
        let key: UInt32
        var modifiers = base
        switch action {
        case .leftHalf: key = KeyCombo.Key.left
        case .rightHalf: key = KeyCombo.Key.right
        case .topHalf: key = KeyCombo.Key.up
        case .bottomHalf: key = KeyCombo.Key.down
        case .topLeftQuarter: key = KeyCombo.Key.u
        case .topRightQuarter: key = KeyCombo.Key.i
        case .bottomLeftQuarter: key = KeyCombo.Key.j
        case .bottomRightQuarter: key = KeyCombo.Key.k
        case .leftThird: key = KeyCombo.Key.d
        case .centerThird: key = KeyCombo.Key.f
        case .rightThird: key = KeyCombo.Key.g
        case .leftTwoThirds: key = KeyCombo.Key.e
        case .rightTwoThirds: key = KeyCombo.Key.t
        case .maximize: key = KeyCombo.Key.returnKey
        case .center: key = KeyCombo.Key.c
        case .restore: key = KeyCombo.Key.delete
        case .nextDisplay:
            key = KeyCombo.Key.right
            modifiers.insert(.command)
        case .previousDisplay:
            key = KeyCombo.Key.left
            modifiers.insert(.command)
        }
        return KeyCombo(keyCode: key, modifiers: modifiers)
    }
}

/// Effective key bindings: defaults overlaid with the user's customizations.
/// Only customizations are persisted, so actions added in later versions pick up their defaults.
public struct ShortcutMap: Codable, Equatable {
    private var overrides: [String: KeyCombo] = [:]
    private var cleared: Set<String> = []

    public init() {}

    public func combo(for action: SnapAction) -> KeyCombo? {
        if cleared.contains(action.name) { return nil }
        return overrides[action.name] ?? DefaultShortcuts.combo(for: action)
    }

    /// All actions that currently have a binding.
    public var bindings: [(action: SnapAction, combo: KeyCombo)] {
        SnapAction.allCases.compactMap { action in combo(for: action).map { (action, $0) } }
    }

    /// The other action already using `combo`, if any.
    public func conflict(for combo: KeyCombo, excluding action: SnapAction) -> SnapAction? {
        SnapAction.allCases.first { $0 != action && self.combo(for: $0) == combo }
    }

    /// Assigns `combo` to `action`. If another action holds it, that binding is cleared
    /// (callers should have confirmed with the user via `conflict(for:excluding:)`).
    public mutating func assign(_ combo: KeyCombo, to action: SnapAction) {
        if let other = conflict(for: combo, excluding: action) { clear(other) }
        overrides[action.name] = combo
        cleared.remove(action.name)
    }

    public mutating func clear(_ action: SnapAction) {
        overrides[action.name] = nil
        cleared.insert(action.name)
    }

    public mutating func resetToDefault(_ action: SnapAction) {
        overrides[action.name] = nil
        cleared.remove(action.name)
    }

    public mutating func resetAll() {
        overrides = [:]
        cleared = []
    }
}
