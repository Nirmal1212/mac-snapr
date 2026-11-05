import Foundation

/// Portable JSON configuration. Every field is optional on import: absent or mistyped fields and
/// unknown keys are ignored, so files from older or newer versions load without error.
public struct ConfigDocument: Codable, Equatable {
    public static let currentVersion = 1

    /// A shortcut entry: bind to a combo, or `null` to clear.
    public enum ShortcutEntry: Equatable {
        case bind(KeyCombo)
        case clear
    }

    public var version: Int?
    public var dragSnapEnabled: Bool?
    public var ignoredApps: [String]?
    public var nativeResizeApps: [String]?
    /// Keyed by action name. Only customizations (differences from default) are exported.
    public var shortcuts: [String: ShortcutEntry]?

    public init(
        version: Int? = ConfigDocument.currentVersion, dragSnapEnabled: Bool? = nil, ignoredApps: [String]? = nil,
        nativeResizeApps: [String]? = nil, shortcuts: [String: ShortcutEntry]? = nil
    ) {
        self.version = version
        self.dragSnapEnabled = dragSnapEnabled
        self.ignoredApps = ignoredApps
        self.nativeResizeApps = nativeResizeApps
        self.shortcuts = shortcuts
    }

    private enum CodingKeys: String, CodingKey {
        case version, dragSnapEnabled, ignoredApps, nativeResizeApps, shortcuts
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = (try? c.decodeIfPresent(Int.self, forKey: .version)) ?? nil
        dragSnapEnabled = (try? c.decodeIfPresent(Bool.self, forKey: .dragSnapEnabled)) ?? nil
        ignoredApps = (try? c.decodeIfPresent([String].self, forKey: .ignoredApps)) ?? nil
        nativeResizeApps = (try? c.decodeIfPresent([String].self, forKey: .nativeResizeApps)) ?? nil
        let raw = (try? c.decodeIfPresent([String: LenientEntry].self, forKey: .shortcuts)) ?? nil
        shortcuts = raw?.compactMapValues(\.entry)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(version, forKey: .version)
        try c.encodeIfPresent(dragSnapEnabled, forKey: .dragSnapEnabled)
        try c.encodeIfPresent(ignoredApps, forKey: .ignoredApps)
        try c.encodeIfPresent(nativeResizeApps, forKey: .nativeResizeApps)
        try c.encodeIfPresent(shortcuts?.mapValues(LenientEntry.init), forKey: .shortcuts)
    }

    /// Decodes one shortcut value, mapping `null` to clear and malformed values to nil (skipped).
    private struct LenientEntry: Codable {
        var entry: ShortcutEntry?
        init(_ entry: ShortcutEntry) { self.entry = entry }
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if c.decodeNil() {
                entry = .clear
            } else {
                entry = (try? c.decode(KeyCombo.self)).map(ShortcutEntry.bind)
            }
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch entry {
            case .bind(let combo): try c.encode(combo)
            default: try c.encodeNil()
            }
        }
    }

    // MARK: - JSON

    public static func decode(from data: Data) throws -> ConfigDocument {
        try JSONDecoder().decode(ConfigDocument.self, from: data)
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    // MARK: - Settings bridge

    /// Snapshot of the user's current configuration.
    public static func export(from settings: SettingsStore) -> ConfigDocument {
        let map = settings.get(.shortcuts)
        var shortcuts: [String: ShortcutEntry] = [:]
        for action in ActionRegistry.all {
            let current = map.combo(for: action)
            guard current != DefaultShortcuts.combo(for: action) else { continue }
            shortcuts[action.name] = current.map(ShortcutEntry.bind) ?? .clear
        }
        return ConfigDocument(
            dragSnapEnabled: settings.get(.dragSnapEnabled), ignoredApps: settings.get(.ignoredApps),
            nativeResizeApps: settings.get(.nativeResizeApps), shortcuts: shortcuts)
    }

    /// Applies present fields; absent ones leave current values untouched. Shortcut entries naming
    /// actions unknown to `ActionRegistry` are skipped. Returns the skipped names.
    @discardableResult
    public func apply(to settings: SettingsStore) -> [String] {
        if let dragSnapEnabled { settings.set(dragSnapEnabled, for: .dragSnapEnabled) }
        if let ignoredApps { settings.set(ignoredApps, for: .ignoredApps) }
        if let nativeResizeApps { settings.set(nativeResizeApps, for: .nativeResizeApps) }
        var skipped: [String] = []
        if let shortcuts, !shortcuts.isEmpty {
            var map = settings.get(.shortcuts)
            let ordered = shortcuts.sorted { $0.key < $1.key }
            // Clears first so a binding never steals from an entry that is itself being rebound.
            for (name, entry) in ordered where entry == .clear {
                if let action = ActionRegistry.action(named: name) { map.clear(action) } else { skipped.append(name) }
            }
            for (name, entry) in ordered {
                guard case .bind(let combo) = entry else { continue }
                if let action = ActionRegistry.action(named: name) {
                    map.assign(combo, to: action)
                } else {
                    skipped.append(name)
                }
            }
            settings.set(map, for: .shortcuts)
        }
        return skipped
    }

    /// Default location loaded on launch.
    public static func defaultFileURL(fileManager: FileManager = .default) -> URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Snapr", isDirectory: true).appendingPathComponent("config.json")
    }
}
