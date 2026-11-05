import Combine
import Foundation

/// Persistence backend for `SettingsStore` (UserDefaults in the app, memory in tests).
public protocol SettingsStorage: AnyObject {
    func data(forKey key: String) -> Data?
    func set(_ data: Data?, forKey key: String)
}

public final class UserDefaultsStorage: SettingsStorage {
    private let defaults: UserDefaults
    public init(_ defaults: UserDefaults = .standard) { self.defaults = defaults }
    public func data(forKey key: String) -> Data? { defaults.data(forKey: key) }
    public func set(_ data: Data?, forKey key: String) {
        if let data { defaults.set(data, forKey: key) } else { defaults.removeObject(forKey: key) }
    }
}

public final class MemorySettingsStorage: SettingsStorage {
    private var values: [String: Data] = [:]
    public init() {}
    public func data(forKey key: String) -> Data? { values[key] }
    public func set(_ data: Data?, forKey key: String) { values[key] = data }
}

/// A typed settings key. Declare new keys as static members in an extension.
public struct SettingKey<Value: Codable> {
    public let name: String
    public let defaultValue: Value
    public init(_ name: String, default defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

public extension SettingKey {
    /// Master toggle for drag-to-edge snapping.
    static var dragSnapEnabled: SettingKey<Bool> { .init("dragSnapEnabled", default: true) }
    /// Whether the user asked to launch Snapr at login.
    static var launchAtLogin: SettingKey<Bool> { .init("launchAtLogin", default: false) }
    /// Persisted shortcut customizations.
    static var shortcuts: SettingKey<ShortcutMap> { .init("shortcuts", default: ShortcutMap()) }
}

/// Typed key-value settings. Publishes the changed key name on every write.
public final class SettingsStore: ObservableObject {
    private let storage: SettingsStorage
    public let changes = PassthroughSubject<String, Never>()

    public init(storage: SettingsStorage = UserDefaultsStorage()) {
        self.storage = storage
    }

    public func get<V: Codable>(_ key: SettingKey<V>) -> V {
        guard let data = storage.data(forKey: key.name),
            let value = try? JSONDecoder().decode(V.self, from: data)
        else { return key.defaultValue }
        return value
    }

    public func set<V: Codable>(_ value: V, for key: SettingKey<V>) {
        objectWillChange.send()
        storage.set(try? JSONEncoder().encode(value), forKey: key.name)
        changes.send(key.name)
    }

    public func reset<V>(_ key: SettingKey<V>) {
        objectWillChange.send()
        storage.set(nil, forKey: key.name)
        changes.send(key.name)
    }
}
