import Foundation
import SnaprCore

/// App-side glue for custom zones, saved layouts and Space moves (`RuntimeAction`s).
extension AppModel {
    /// Runs a runtime action; also the `AutomationHost` entry point for `snapr://execute-action?name=custom:…`.
    @discardableResult
    func perform(_ action: RuntimeAction) -> Bool {
        if !trusted { showOnboarding(); return false }
        guard runner.exists(action) else {
            debugLog.log("runtime \(action.name) -> unknown or disabled")
            return false
        }
        let changed = runner.perform(action)
        debugLog.log("runtime \(action.name) -> \(changed ? "done" : "no change")")
        return changed
    }

    var customZones: [CustomZone] { layoutStore.zones }
    var savedLayouts: [SavedLayout] { layoutStore.layouts }
    var spacesEnabled: Bool { settings.get(.spacesEnabled) }
    /// Whether the private functions needed for Space moves exist on this macOS version.
    var spaceMoverAvailable: Bool { spaceMover.isAvailable }
    /// Whether Space actions should be offered (flag on and available).
    var spaceActionsActive: Bool { spaces.isActive }

    func setSpacesEnabled(_ enabled: Bool) {
        settings.set(enabled, for: .spacesEnabled)
        layoutMessage = enabled && !spaceMover.isAvailable ? "Space moves are not supported on this macOS version." : nil
    }

    /// Saves (adds or updates) a zone and reports validation problems in `layoutMessage`.
    @discardableResult
    func saveZone(_ zone: CustomZone) -> Bool {
        do {
            try layoutStore.save(zone, builtIn: settings.get(.shortcuts))
            layoutMessage = nil
            return true
        } catch {
            layoutMessage = Self.describe(error)
            return false
        }
    }

    func addZone() {
        let name = "Zone \(customZones.count + 1)"
        saveZone(
            CustomZone(
                id: layoutStore.makeID(from: name), name: name, rect: FractionRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)))
    }

    func removeZone(_ id: String) { layoutStore.removeZone(id: id) }

    /// Captures the open windows as a new saved layout.
    func saveCurrentLayout(named name: String) {
        guard trusted else { showOnboarding(); return }
        let entries = runner.captureEntries()
        guard !entries.isEmpty else {
            layoutMessage = "No movable windows found to save."
            return
        }
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let layout = SavedLayout(
            id: layoutStore.makeID(from: title), name: title.isEmpty ? "Layout \(savedLayouts.count + 1)" : title,
            entries: entries)
        do {
            try layoutStore.save(layout)
            layoutMessage = "Saved “\(layout.name)” with \(entries.count) windows."
        } catch {
            layoutMessage = Self.describe(error)
        }
    }

    @discardableResult
    func saveLayout(_ layout: SavedLayout) -> Bool {
        do {
            try layoutStore.save(layout, builtIn: settings.get(.shortcuts))
            layoutMessage = nil
            return true
        } catch {
            layoutMessage = Self.describe(error)
            return false
        }
    }

    func removeLayout(_ id: String) { layoutStore.removeLayout(id: id) }

    private static func describe(_ error: Error) -> String {
        switch error as? CustomLayoutStore.StoreError {
        case .invalid: return "That name or rectangle is not valid."
        case .limitReached: return "Limit reached; remove an item first."
        case .notFound: return "Item not found."
        case .invalidShortcut: return "Shortcuts need a modifier key (or be a function key)."
        case .shortcutConflict(let other): return "That shortcut is already used by “\(other)”."
        case nil: return error.localizedDescription
        }
    }
}
