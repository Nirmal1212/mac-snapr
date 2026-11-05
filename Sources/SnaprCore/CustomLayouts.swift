import CoreGraphics
import Foundation

/// A rectangle in fractions (0...1, top-left origin) of a reference area.
public struct FractionRect: Codable, Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// Finite, positive size and fully inside the unit square (with a tiny tolerance for rounding).
    public var isValid: Bool {
        let values = [x, y, width, height]
        guard values.allSatisfy(\.isFinite) else { return false }
        let eps = 1e-6
        return x >= 0 && y >= 0 && width > 0.001 && height > 0.001 && x + width <= 1 + eps && y + height <= 1 + eps
    }

    public func frame(in area: CGRect) -> CGRect {
        CGRect(
            x: area.minX + area.width * x, y: area.minY + area.height * y,
            width: area.width * width, height: area.height * height)
    }

    /// The fractions of `rect` relative to `area` (clamped to the area); nil when they do not overlap.
    public static func of(_ rect: CGRect, in area: CGRect) -> FractionRect? {
        let clipped = rect.intersection(area)
        guard !clipped.isNull, clipped.width > 0, clipped.height > 0, area.width > 0, area.height > 0 else { return nil }
        let result = FractionRect(
            x: Double((clipped.minX - area.minX) / area.width), y: Double((clipped.minY - area.minY) / area.height),
            width: Double(clipped.width / area.width), height: Double(clipped.height / area.height))
        return result.isValid ? result : nil
    }
}

/// A user-defined zone: any size and position, optionally with its own global shortcut.
public struct CustomZone: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var rect: FractionRect
    public var shortcut: KeyCombo?

    public init(id: String, name: String, rect: FractionRect, shortcut: KeyCombo? = nil) {
        self.id = id
        self.name = name
        self.rect = rect
        self.shortcut = shortcut
    }

    public var isValid: Bool {
        RuntimeAction.isValidID(id) && CustomLayoutStore.isValidName(name) && rect.isValid
    }

    public var action: RuntimeAction { .zone(id) }
}

/// Decodes arrays element by element, dropping elements that fail to decode.
public struct LossyArray<Element: Codable>: Codable {
    public var elements: [Element]
    public init(_ elements: [Element]) { self.elements = elements }

    private struct Box: Decodable {
        var value: Element?
        init(from decoder: Decoder) throws { value = try? Element(from: decoder) }
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Element] = []
        while !container.isAtEnd {
            if let box = try? container.decode(Box.self), let value = box.value { result.append(value) }
        }
        elements = result
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for element in elements { try container.encode(element) }
    }
}

public extension SettingKey {
    static var customZones: SettingKey<LossyArray<CustomZone>> { .init("customZones", default: LossyArray([])) }
    static var savedLayouts: SettingKey<LossyArray<SavedLayout>> { .init("savedLayouts", default: LossyArray([])) }
}

/// A binding for a runtime action, for hotkeys and menus.
public struct RuntimeBinding: Equatable {
    public var action: RuntimeAction
    public var title: String
    public var combo: KeyCombo?
}

/// Owns custom zones and saved layouts; the only writer of their settings keys.
public final class CustomLayoutStore {
    public static let maxZones = 200
    public static let maxLayouts = 50

    public enum StoreError: Error, Equatable {
        case invalid
        case limitReached
        case notFound
        case invalidShortcut
        /// The combo is used by the named built-in action or custom item.
        case shortcutConflict(String)
    }

    private let settings: SettingsStore

    public init(settings: SettingsStore) { self.settings = settings }

    public static func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && name.count <= 100
    }

    // MARK: Reading

    public var zones: [CustomZone] { settings.get(.customZones).elements }
    public var layouts: [SavedLayout] { settings.get(.savedLayouts).elements }
    public func zone(id: String) -> CustomZone? { zones.first { $0.id == id } }
    public func layout(id: String) -> SavedLayout? { layouts.first { $0.id == id } }

    /// Every custom item as a runtime binding (zones first), with or without a shortcut.
    public var bindings: [RuntimeBinding] {
        zones.map { RuntimeBinding(action: $0.action, title: $0.name, combo: $0.shortcut) }
            + layouts.map { RuntimeBinding(action: $0.action, title: $0.name, combo: $0.shortcut) }
    }

    /// Shortcuts to register: one per distinct combo, built-in bindings win over custom ones.
    public func hotkeyBindings(builtIn: ShortcutMap) -> [(action: RuntimeAction, combo: KeyCombo)] {
        var taken = Set(builtIn.bindings.map(\.combo))
        var result: [(RuntimeAction, KeyCombo)] = []
        for binding in bindings {
            guard let combo = binding.combo, combo.isValidGlobalShortcut, taken.insert(combo).inserted else { continue }
            result.append((binding.action, combo))
        }
        return result
    }

    /// Describes the built-in action or custom item already using `combo`, if any.
    public func conflict(for combo: KeyCombo, excluding action: RuntimeAction? = nil, builtIn: ShortcutMap) -> String? {
        if let other = builtIn.bindings.first(where: { $0.combo == combo }) { return other.action.title }
        return bindings.first { $0.combo == combo && $0.action != action }?.title
    }

    // MARK: Writing

    /// Makes an unused id from `name` (lowercase letters, digits and hyphens).
    public func makeID(from name: String) -> String {
        var slug = ""
        for scalar in name.lowercased().unicodeScalars {
            if scalar.isASCII, (scalar.value >= 97 && scalar.value <= 122) || (scalar.value >= 48 && scalar.value <= 57) {
                slug.unicodeScalars.append(scalar)
            } else if !slug.hasSuffix("-") {
                slug += "-"
            }
        }
        slug = String(slug.trimmingCharacters(in: CharacterSet(charactersIn: "-")).prefix(48))
        if slug.isEmpty { slug = "item" }
        let used = Set(zones.map(\.id) + layouts.map(\.id))
        var candidate = slug
        var n = 2
        while used.contains(candidate) {
            candidate = "\(slug)-\(n)"
            n += 1
        }
        return candidate
    }

    private func checkShortcut(_ combo: KeyCombo?, action: RuntimeAction, builtIn: ShortcutMap) throws {
        guard let combo else { return }
        guard combo.isValidGlobalShortcut else { throw StoreError.invalidShortcut }
        if let other = conflict(for: combo, excluding: action, builtIn: builtIn) { throw StoreError.shortcutConflict(other) }
    }

    public func save(_ zone: CustomZone, builtIn: ShortcutMap? = nil) throws {
        guard zone.isValid else { throw StoreError.invalid }
        try checkShortcut(zone.shortcut, action: zone.action, builtIn: builtIn ?? settings.get(.shortcuts))
        var list = zones
        if let index = list.firstIndex(where: { $0.id == zone.id }) {
            list[index] = zone
        } else {
            guard list.count < Self.maxZones else { throw StoreError.limitReached }
            list.append(zone)
        }
        settings.set(LossyArray(list), for: .customZones)
    }

    public func save(_ layout: SavedLayout, builtIn: ShortcutMap? = nil) throws {
        guard layout.isValid else { throw StoreError.invalid }
        try checkShortcut(layout.shortcut, action: layout.action, builtIn: builtIn ?? settings.get(.shortcuts))
        var list = layouts
        if let index = list.firstIndex(where: { $0.id == layout.id }) {
            list[index] = layout
        } else {
            guard list.count < Self.maxLayouts else { throw StoreError.limitReached }
            list.append(layout)
        }
        settings.set(LossyArray(list), for: .savedLayouts)
    }

    public func removeZone(id: String) {
        settings.set(LossyArray(zones.filter { $0.id != id }), for: .customZones)
    }

    public func removeLayout(id: String) {
        settings.set(LossyArray(layouts.filter { $0.id != id }), for: .savedLayouts)
    }

    // MARK: Import

    /// Cleans imported items: invalid ones are dropped, duplicate ids resolve to the last one, and
    /// shortcuts that are not valid global shortcuts or collide with another binding are removed.
    /// Returns the cleaned lists and a description of every problem.
    public static func sanitized(
        zones: [CustomZone]?, layouts: [SavedLayout]?, builtIn: ShortcutMap
    ) -> (zones: [CustomZone]?, layouts: [SavedLayout]?, skipped: [String]) {
        var skipped: [String] = []
        var taken = Set(builtIn.bindings.map(\.combo))

        func unique<T>(_ items: [T], id: (T) -> String, valid: (T) -> Bool, limit: Int) -> [T] {
            var order: [String] = []
            var byID: [String: T] = [:]
            for item in items {
                guard valid(item) else { skipped.append("invalid item \(id(item).prefix(64))"); continue }
                if byID[id(item)] == nil { order.append(id(item)) }
                byID[id(item)] = item
            }
            return order.prefix(limit).compactMap { byID[$0] }
        }
        func checked(_ combo: KeyCombo?, name: String) -> KeyCombo? {
            guard let combo else { return nil }
            guard combo.isValidGlobalShortcut else { skipped.append("\(name) shortcut"); return nil }
            guard taken.insert(combo).inserted else { skipped.append("\(name) shortcut (in use)"); return nil }
            return combo
        }

        var zoneResult = zones.map { list in
            unique(list, id: \.id, valid: { $0.isValid }, limit: maxZones)
        }
        var layoutResult = layouts.map { list in
            unique(list, id: \.id, valid: { $0.isValid }, limit: maxLayouts)
        }
        // Ids are shared between zones and layouts only through their prefixes, so no cross-check is needed.
        if zoneResult != nil {
            zoneResult = zoneResult?.map { zone in
                var zone = zone
                zone.shortcut = checked(zone.shortcut, name: zone.action.name)
                return zone
            }
        }
        if layoutResult != nil {
            layoutResult = layoutResult?.map { layout in
                var layout = layout
                layout.shortcut = checked(layout.shortcut, name: layout.action.name)
                return layout
            }
        }
        return (zoneResult, layoutResult, skipped)
    }
}
