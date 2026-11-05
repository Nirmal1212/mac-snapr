import XCTest
@testable import SnaprCore

final class ShortcutsAndSettingsTests: XCTestCase {
    func testDefaultLeftHalfIsCtrlOptLeft() {
        let combo = ShortcutMap().combo(for: .leftHalf)
        XCTAssertEqual(combo, KeyCombo(keyCode: KeyCombo.Key.left, modifiers: [.control, .option]))
        XCTAssertEqual(combo?.displayString, "⌃⌥←")
    }

    func testEveryActionHasUniqueDefault() {
        let combos = SnapAction.allCases.compactMap { DefaultShortcuts.combo(for: $0) }
        XCTAssertEqual(combos.count, SnapAction.allCases.count)
        XCTAssertEqual(Set(combos).count, combos.count)
    }

    func testRebindReleasesOldShortcut() {
        var map = ShortcutMap()
        let old = map.combo(for: .maximize)!
        let new = KeyCombo(keyCode: KeyCombo.Key.up, modifiers: [.control, .command])
        map.assign(new, to: .maximize)
        XCTAssertEqual(map.combo(for: .maximize), new)
        XCTAssertNil(map.conflict(for: old, excluding: .center))
        XCTAssertFalse(map.bindings.contains { $0.combo == old })
    }

    func testConflictDetection() {
        let map = ShortcutMap()
        let leftHalf = map.combo(for: .leftHalf)!
        XCTAssertEqual(map.conflict(for: leftHalf, excluding: .maximize), .leftHalf)
        XCTAssertNil(map.conflict(for: leftHalf, excluding: .leftHalf))
    }

    func testAssigningConflictStealsBinding() {
        var map = ShortcutMap()
        let leftHalf = map.combo(for: .leftHalf)!
        map.assign(leftHalf, to: .maximize)
        XCTAssertNil(map.combo(for: .leftHalf))
        XCTAssertEqual(map.combo(for: .maximize), leftHalf)
    }

    func testClearAndReset() {
        var map = ShortcutMap()
        map.clear(.center)
        XCTAssertNil(map.combo(for: .center))
        map.resetToDefault(.center)
        XCTAssertNotNil(map.combo(for: .center))
    }

    func testSettingsPersistShortcutsAcrossInstances() {
        let storage = MemorySettingsStorage()
        var map = ShortcutMap()
        map.assign(KeyCombo(keyCode: KeyCombo.Key.c, modifiers: [.command, .shift]), to: .maximize)
        map.clear(.center)
        SettingsStore(storage: storage).set(map, for: .shortcuts)

        let loaded = SettingsStore(storage: storage).get(.shortcuts)
        XCTAssertEqual(loaded, map)
        XCTAssertNil(loaded.combo(for: .center))
        XCTAssertEqual(loaded.combo(for: .maximize)?.keyCode, KeyCombo.Key.c)
    }

    func testTypedKeysDefaultsAndRoundTrip() {
        let store = SettingsStore(storage: MemorySettingsStorage())
        XCTAssertTrue(store.get(.dragSnapEnabled))
        store.set(false, for: .dragSnapEnabled)
        XCTAssertFalse(store.get(.dragSnapEnabled))
        store.reset(.dragSnapEnabled)
        XCTAssertTrue(store.get(.dragSnapEnabled))
    }

    func testActionRegistryLookup() {
        XCTAssertEqual(ActionRegistry.action(named: "left-half"), .leftHalf)
        XCTAssertNil(ActionRegistry.action(named: "nope"))
        XCTAssertEqual(ActionRegistry.grouped().flatMap(\.actions).count, SnapAction.allCases.count)
    }

    func testGlobalShortcutValidity() {
        XCTAssertFalse(KeyCombo(keyCode: KeyCombo.Key.c, modifiers: []).isValidGlobalShortcut)
        XCTAssertTrue(KeyCombo(keyCode: 122, modifiers: []).isValidGlobalShortcut)
    }
}
