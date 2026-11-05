import XCTest
@testable import SnaprCore

final class ConfigTests: XCTestCase {
    private func makeSettings() -> SettingsStore { SettingsStore(storage: MemorySettingsStorage()) }

    func testRoundTrip() throws {
        let source = makeSettings()
        source.set(false, for: .dragSnapEnabled)
        source.ignore("a.b")
        source.set(["n.r"], for: .nativeResizeApps)
        var map = ShortcutMap()
        let combo = KeyCombo(keyCode: KeyCombo.Key.up, modifiers: [.control, .command])
        map.assign(combo, to: .maximize)
        map.clear(.center)
        source.set(map, for: .shortcuts)

        let data = try ConfigDocument.export(from: source).encoded()
        let target = makeSettings()
        let skipped = try ConfigDocument.decode(from: data).apply(to: target)

        XCTAssertTrue(skipped.isEmpty)
        XCTAssertFalse(target.get(.dragSnapEnabled))
        XCTAssertEqual(target.get(.ignoredApps), ["a.b"])
        XCTAssertEqual(target.get(.nativeResizeApps), ["n.r"])
        XCTAssertEqual(target.get(.shortcuts).combo(for: .maximize), combo)
        XCTAssertNil(target.get(.shortcuts).combo(for: .center))
        XCTAssertEqual(target.get(.shortcuts).combo(for: .leftHalf), DefaultShortcuts.combo(for: .leftHalf))
    }

    func testExportOnlyContainsCustomizations() {
        let doc = ConfigDocument.export(from: makeSettings())
        XCTAssertEqual(doc.shortcuts, [:])
    }

    func testUnknownKeysAreIgnored() throws {
        let json = #"{"version": 9, "futureThing": {"x": 1}, "dragSnapEnabled": false, "ignoredApps": ["a.b"]}"#
        let settings = makeSettings()
        try ConfigDocument.decode(from: Data(json.utf8)).apply(to: settings)
        XCTAssertFalse(settings.get(.dragSnapEnabled))
        XCTAssertEqual(settings.get(.ignoredApps), ["a.b"])
    }

    func testMissingKeysLeaveCurrentValues() throws {
        let settings = makeSettings()
        settings.set(false, for: .dragSnapEnabled)
        settings.ignore("keep.me")
        try ConfigDocument.decode(from: Data("{}".utf8)).apply(to: settings)
        XCTAssertFalse(settings.get(.dragSnapEnabled))
        XCTAssertEqual(settings.get(.ignoredApps), ["keep.me"])
    }

    func testMistypedFieldsAreIgnored() throws {
        let json = #"{"dragSnapEnabled": "yes", "ignoredApps": 5, "shortcuts": {"maximize": "junk", "center": null}}"#
        let settings = makeSettings()
        try ConfigDocument.decode(from: Data(json.utf8)).apply(to: settings)
        XCTAssertTrue(settings.get(.dragSnapEnabled))
        XCTAssertEqual(settings.get(.ignoredApps), [])
        XCTAssertEqual(settings.get(.shortcuts).combo(for: .maximize), DefaultShortcuts.combo(for: .maximize))
        XCTAssertNil(settings.get(.shortcuts).combo(for: .center))
    }

    func testUnknownActionsAreSkippedAndReported() throws {
        let json = #"""
        {"shortcuts": {"teleport": {"keyCode": 1, "modifiers": 4096},
                       "maximize": {"keyCode": 126, "modifiers": 4352}}}
        """#
        let settings = makeSettings()
        let skipped = try ConfigDocument.decode(from: Data(json.utf8)).apply(to: settings)
        XCTAssertEqual(skipped, ["teleport"])
        XCTAssertEqual(
            settings.get(.shortcuts).combo(for: .maximize),
            KeyCombo(keyCode: 126, modifiers: [.control, .command]))
    }

    func testInvalidGlobalShortcutIsRejected() throws {
        let json = #"{"shortcuts": {"left-half": {"keyCode": 0, "modifiers": 0}}}"#
        let settings = makeSettings()
        let skipped = try ConfigDocument.decode(from: Data(json.utf8)).apply(to: settings)
        XCTAssertEqual(skipped, ["left-half"])
        XCTAssertEqual(settings.get(.shortcuts).combo(for: .leftHalf), DefaultShortcuts.combo(for: .leftHalf))
    }

    func testNonObjectJSONThrows() {
        XCTAssertThrowsError(try ConfigDocument.decode(from: Data("[1,2]".utf8)))
        XCTAssertThrowsError(try ConfigDocument.decode(from: Data("nonsense".utf8)))
    }

    // MARK: Presets

    func testSpectaclePreset() {
        let map = ShortcutPresets.spectacle()
        XCTAssertEqual(
            map.combo(for: .leftHalf), KeyCombo(keyCode: KeyCombo.Key.left, modifiers: [.option, .command]))
        XCTAssertEqual(map.combo(for: .maximize)?.displayString, "⌥⌘F")
        // Actions Spectacle lacks stay unbound, and no two actions share a combo.
        XCTAssertNil(map.combo(for: .leftThird))
        let combos = map.bindings.map(\.combo)
        XCTAssertEqual(Set(combos).count, combos.count)
    }

    func testRestoreDefaults() {
        var map = ShortcutPresets.spectacle()
        XCTAssertNotEqual(map, ShortcutMap())
        map = ShortcutPresets.defaults()
        XCTAssertEqual(map.combo(for: .leftHalf), DefaultShortcuts.combo(for: .leftHalf))
    }
}
