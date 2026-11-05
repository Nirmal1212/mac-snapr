import XCTest
@testable import SnaprCore

final class LayoutSettingsTests: XCTestCase {
    func testShortcutMapSavedBeforeLayoutEngineStillDecodes() throws {
        // Shape written by the core change: overrides + cleared, keyed by raw action name.
        let json = """
        {"overrides":{"left-half":{"keyCode":0,"modifiers":4096}},"cleared":["maximize"]}
        """
        let map = try JSONDecoder().decode(ShortcutMap.self, from: Data(json.utf8))
        XCTAssertEqual(map.combo(for: .leftHalf), KeyCombo(keyCode: 0, modifiers: .control))
        XCTAssertNil(map.combo(for: .maximize))
        XCTAssertEqual(map.combo(for: .rightHalf), DefaultShortcuts.combo(for: .rightHalf))
        // New actions are reachable without having been saved.
        XCTAssertEqual(map.combo(for: .larger), DefaultShortcuts.combo(for: .larger))
        XCTAssertNil(map.combo(for: .ninthTopLeft))
    }

    func testShortcutMapIgnoresUnknownSavedActions() throws {
        let json = #"{"overrides":{"does-not-exist":{"keyCode":1,"modifiers":4096}},"cleared":[]}"#
        let map = try JSONDecoder().decode(ShortcutMap.self, from: Data(json.utf8))
        XCTAssertEqual(map.combo(for: .leftHalf), DefaultShortcuts.combo(for: .leftHalf))
    }

    func testNewActionCanBeBoundAndRoundTrips() throws {
        var map = ShortcutMap()
        let combo = KeyCombo(keyCode: KeyCombo.Key.e, modifiers: [.control, .option, .shift])
        map.assign(combo, to: .ninthTopLeft)
        let decoded = try JSONDecoder().decode(ShortcutMap.self, from: JSONEncoder().encode(map))
        XCTAssertEqual(decoded.combo(for: .ninthTopLeft), combo)
        XCTAssertEqual(decoded, map)
    }

    func testLayoutDefaultsConflictFree() {
        let combos = LayoutCatalog.actions.compactMap { DefaultShortcuts.combo(for: $0) }
        XCTAssertEqual(Set(combos).count, combos.count)
        let core = SnapAction.allCases.filter { !LayoutCatalog.actions.contains($0) }
        let coreCombos = Set(core.compactMap { DefaultShortcuts.combo(for: $0) })
        XCTAssertTrue(coreCombos.isDisjoint(with: combos))
    }

    func testDefaultOptions() {
        let options = LayoutOptions()
        XCTAssertEqual(options.halfCycleOrder, .rectangle)
        XCTAssertEqual(options.resizeStep, 30)
        XCTAssertEqual(options.almostMaximizeFraction, 0.9)
        XCTAssertEqual(options.repeatBehavior, .cycleSizes)
        XCTAssertEqual(options.gaps.windowGap, 0)
    }

    func testLayoutOptionsDecodeEmptyAndPartialData() throws {
        let empty = try JSONDecoder().decode(LayoutOptions.self, from: Data("{}".utf8))
        XCTAssertEqual(empty, LayoutOptions())
        let partial = try JSONDecoder().decode(
            LayoutOptions.self, from: Data(#"{"halfCycleOrder":"spec","gaps":{"windowGap":6}}"#.utf8))
        XCTAssertEqual(partial.halfCycleOrder, .spec)
        XCTAssertEqual(partial.gaps.windowGap, 6)
        XCTAssertTrue(partial.gaps.notchAwareTopGap)
        XCTAssertEqual(partial.resizeStep, 30)
        let unknown = try JSONDecoder().decode(LayoutOptions.self, from: Data(#"{"halfCycleOrder":"bogus"}"#.utf8))
        XCTAssertEqual(unknown.halfCycleOrder, .rectangle)
    }

    func testOptionsPersistThroughSettingsStore() {
        let store = SettingsStore(storage: MemorySettingsStorage())
        XCTAssertEqual(store.get(.layoutOptions), LayoutOptions())
        var options = LayoutOptions()
        options.halfCycleOrder = .spec
        options.gaps.screenGaps = EdgeGaps(top: 4, left: 3, bottom: 2, right: 1)
        options.gaps.exemptActions = ["maximize"]
        store.set(options, for: .layoutOptions)
        XCTAssertEqual(store.get(.layoutOptions), options)
    }
}
