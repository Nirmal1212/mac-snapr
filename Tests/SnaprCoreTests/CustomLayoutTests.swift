import XCTest
@testable import SnaprCore

private final class RuntimeHost: AutomationHost {
    var performed: [SnapAction] = []
    var runtime: [RuntimeAction] = []
    var known: Set<RuntimeAction> = []
    func perform(_ action: SnapAction) { performed.append(action) }
    func perform(_ action: RuntimeAction) -> Bool {
        guard known.contains(action) else { return false }
        runtime.append(action)
        return true
    }
}

final class CustomLayoutTests: XCTestCase {
    let screen = ScreenInfo(
        id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
        visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
    let screen2 = ScreenInfo(
        id: 2, frame: CGRect(x: 1000, y: 0, width: 2000, height: 1000),
        visibleFrame: CGRect(x: 1000, y: 0, width: 2000, height: 1000))
    let combo = KeyCombo(keyCode: KeyCombo.Key.up, modifiers: [.control, .shift])

    private func makeSettings() -> SettingsStore { SettingsStore(storage: MemorySettingsStorage()) }
    private func zone(
        _ id: String = "a",
        rect: FractionRect = FractionRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5),
        shortcut: KeyCombo? = nil
    ) -> CustomZone {
        CustomZone(id: id, name: "Zone \(id)", rect: rect, shortcut: shortcut)
    }

    // MARK: Runtime action names

    func testRuntimeActionNames() {
        XCTAssertEqual(RuntimeAction.parse("custom:my-zone-1"), .zone("my-zone-1"))
        XCTAssertEqual(RuntimeAction.parse("layout:work"), .layout("work"))
        XCTAssertEqual(RuntimeAction.parse("space:next"), .space(.next))
        XCTAssertEqual(RuntimeAction.parse("space:previous"), .space(.previous))
        XCTAssertEqual(RuntimeAction.parse("space:3"), .space(.index(3)))
        for action in [RuntimeAction.zone("x"), .layout("y"), .space(.index(2)), .space(.next)] {
            XCTAssertEqual(RuntimeAction.parse(action.name), action)
        }
    }

    func testRuntimeActionRejectsBadInput() {
        for bad in [
            "custom:", "custom:UPPER", "custom:a b", "custom:a/b", "custom:../x", "custom:" + String(repeating: "a", count: 65),
            "space:0", "space:17", "space:-1", "space:1x", "space:", "other:x", "left-half", "custom", ":x"
        ] {
            XCTAssertNil(RuntimeAction.parse(bad), bad)
        }
        XCTAssertNotNil(RuntimeAction.parse("custom:" + String(repeating: "a", count: 64)))
    }

    // MARK: Models and store

    func testFractionRectValidation() {
        XCTAssertTrue(FractionRect(x: 0, y: 0, width: 1, height: 1).isValid)
        XCTAssertFalse(FractionRect(x: 0.6, y: 0, width: 0.6, height: 1).isValid)
        XCTAssertFalse(FractionRect(x: 0, y: 0, width: 0, height: 1).isValid)
        XCTAssertFalse(FractionRect(x: -0.1, y: 0, width: 0.5, height: 1).isValid)
        XCTAssertFalse(FractionRect(x: .nan, y: 0, width: 0.5, height: 1).isValid)
        XCTAssertFalse(FractionRect(x: 0, y: 0, width: .infinity, height: 1).isValid)
    }

    func testStoreAddUpdateRemove() throws {
        let store = CustomLayoutStore(settings: makeSettings())
        try store.save(zone("a"))
        try store.save(zone("b"))
        var changed = zone("a")
        changed.name = "Renamed"
        try store.save(changed)
        XCTAssertEqual(store.zones.map(\.id), ["a", "b"])
        XCTAssertEqual(store.zone(id: "a")?.name, "Renamed")
        store.removeZone(id: "a")
        XCTAssertEqual(store.zones.map(\.id), ["b"])
    }

    func testStoreRejectsInvalid() {
        let store = CustomLayoutStore(settings: makeSettings())
        XCTAssertThrowsError(try store.save(zone("Bad Id")))
        XCTAssertThrowsError(try store.save(zone("a", rect: FractionRect(x: 0, y: 0, width: 2, height: 1))))
        XCTAssertThrowsError(try store.save(CustomZone(id: "a", name: "  ", rect: FractionRect(x: 0, y: 0, width: 1, height: 1))))
        XCTAssertTrue(store.zones.isEmpty)
    }

    func testStoreLimit() throws {
        let store = CustomLayoutStore(settings: makeSettings())
        for i in 0..<CustomLayoutStore.maxZones { try store.save(zone("z\(i)")) }
        XCTAssertThrowsError(try store.save(zone("extra"))) { XCTAssertEqual($0 as? CustomLayoutStore.StoreError, .limitReached) }
        try store.save(zone("z0"))  // updating still works
    }

    func testShortcutValidationAndConflicts() throws {
        let store = CustomLayoutStore(settings: makeSettings())
        let builtIn = ShortcutMap()
        // No modifier on a non-function key
        XCTAssertThrowsError(try store.save(zone("a", shortcut: KeyCombo(keyCode: 0, modifiers: [])), builtIn: builtIn)) {
            XCTAssertEqual($0 as? CustomLayoutStore.StoreError, .invalidShortcut)
        }
        // Built-in conflict (ctrl+opt+left = left half)
        let left = DefaultShortcuts.combo(for: .leftHalf)!
        XCTAssertThrowsError(try store.save(zone("a", shortcut: left), builtIn: builtIn)) {
            XCTAssertEqual($0 as? CustomLayoutStore.StoreError, .shortcutConflict("Left Half"))
        }
        try store.save(zone("a", shortcut: combo), builtIn: builtIn)
        // Conflict with another custom item, but not with itself
        XCTAssertThrowsError(try store.save(zone("b", shortcut: combo), builtIn: builtIn))
        XCTAssertNoThrow(try store.save(zone("a", shortcut: combo), builtIn: builtIn))
        XCTAssertEqual(store.hotkeyBindings(builtIn: builtIn).map(\.action), [.zone("a")])
    }

    func testMakeIDIsValidAndUnique() throws {
        let store = CustomLayoutStore(settings: makeSettings())
        XCTAssertEqual(store.makeID(from: "My Wide Zone!"), "my-wide-zone")
        XCTAssertEqual(store.makeID(from: "###"), "item")
        try store.save(zone("my-wide-zone"))
        XCTAssertEqual(store.makeID(from: "My Wide Zone"), "my-wide-zone-2")
        XCTAssertTrue(RuntimeAction.isValidID(store.makeID(from: String(repeating: "x", count: 200))))
    }

    func testZoneFrameUsesUsableArea() {
        let frame = FractionRect(x: 0.25, y: 0, width: 0.5, height: 0.5).frame(in: CGRect(x: 0, y: 100, width: 1000, height: 600))
        XCTAssertEqual(frame, CGRect(x: 250, y: 100, width: 500, height: 300))
    }

    // MARK: Runner

    private func makeRunner(
        windows: [WindowInfo], settings: SettingsStore? = nil, lister: WindowLister? = nil, spaces: SpaceMoving? = nil
    ) -> (RuntimeActionRunner, MockWindowProvider, CustomLayoutStore, SettingsStore) {
        let settings = settings ?? makeSettings()
        let provider = MockWindowProvider(windows: windows)
        let screens = MockScreenProvider([screen, screen2])
        let controller = SnapController(windows: provider, screens: screens, options: { settings.get(.layoutOptions) })
        let store = CustomLayoutStore(settings: settings)
        let space = SpaceActionController(settings: settings, windows: provider, mover: spaces)
        let runner = RuntimeActionRunner(
            store: store, controller: controller, windows: provider, screens: screens, lister: lister, spaces: space,
            options: { settings.get(.layoutOptions) })
        return (runner, provider, store, settings)
    }

    func testRunZonePlacesWindowAndRestores() throws {
        let id = WindowID(1)
        let (runner, provider, store, _) = makeRunner(windows: [WindowInfo(id: id, frame: CGRect(x: 50, y: 50, width: 300, height: 200))])
        try store.save(zone("a", rect: FractionRect(x: 0.5, y: 0, width: 0.5, height: 0.25)))
        XCTAssertTrue(runner.perform(.zone("a")))
        XCTAssertEqual(provider.windows[id]?.frame, CGRect(x: 500, y: 0, width: 500, height: 200))
        XCTAssertFalse(runner.perform(.zone("missing")))
    }

    func testZoneHonorsGaps() throws {
        let id = WindowID(1)
        let settings = makeSettings()
        var options = LayoutOptions()
        options.gaps.screenGaps = EdgeGaps(top: 10, left: 10, bottom: 10, right: 10)
        options.gaps.windowGap = 20
        settings.set(options, for: .layoutOptions)
        let (runner, provider, store, _) = makeRunner(
            windows: [WindowInfo(id: id, frame: CGRect(x: 50, y: 50, width: 300, height: 200))], settings: settings)
        try store.save(zone("a", rect: FractionRect(x: 0, y: 0, width: 0.5, height: 1)))
        runner.perform(.zone("a"))
        // Area is (10,10,980,780); zone is the left half; the window gap trims only the inner edge.
        XCTAssertEqual(provider.windows[id]?.frame, CGRect(x: 10, y: 10, width: 480, height: 780))
    }

    // MARK: Saved layouts

    private func listed(_ id: Int, _ bundle: String, _ title: String, _ frame: CGRect) -> ListedWindow {
        ListedWindow(info: WindowInfo(id: WindowID(id), frame: frame), bundleID: bundle, title: title)
    }

    func testCaptureAndPlan() {
        let windows = [
            listed(1, "com.a", "One", CGRect(x: 0, y: 0, width: 500, height: 400)),
            listed(2, "com.b", "Two", CGRect(x: 1000, y: 0, width: 1000, height: 500))
        ]
        let entries = ArrangementPlanner.capture(windows: windows, screens: [screen2, screen])
        XCTAssertEqual(entries.map(\.screenIndex), [0, 1])
        XCTAssertEqual(entries[0].rect, FractionRect(x: 0, y: 0, width: 0.5, height: 0.5))
        let layout = SavedLayout(id: "l", name: "L", entries: entries)
        // The windows moved; the plan puts them back
        let moved = [
            listed(1, "com.a", "One", CGRect(x: 300, y: 300, width: 100, height: 100)),
            listed(2, "com.b", "Two", CGRect(x: 10, y: 10, width: 100, height: 100))
        ]
        let plan = ArrangementPlanner.plan(layout: layout, windows: moved, screens: [screen2, screen])
        XCTAssertEqual(plan.map(\.frame), [CGRect(x: 0, y: 0, width: 500, height: 400), CGRect(x: 1000, y: 0, width: 1000, height: 500)])
        XCTAssertEqual(plan.map(\.screen.id), [1, 2])
    }

    func testPlanMatchesTitlesThenOrderAndSkipsMissing() {
        let r1 = FractionRect(x: 0, y: 0, width: 0.5, height: 1)
        let r2 = FractionRect(x: 0.5, y: 0, width: 0.5, height: 1)
        let layout = SavedLayout(
            id: "l", name: "L",
            entries: [
                LayoutEntry(bundleID: "com.a", title: "Second", screenIndex: 0, rect: r1),
                LayoutEntry(bundleID: "com.a", title: nil, screenIndex: 0, rect: r2),
                LayoutEntry(bundleID: "com.gone", title: nil, screenIndex: 0, rect: r2)
            ])
        let windows = [
            listed(1, "com.a", "First", CGRect(x: 0, y: 0, width: 100, height: 100)),
            listed(2, "com.a", "Second", CGRect(x: 0, y: 0, width: 100, height: 100))
        ]
        let plan = ArrangementPlanner.plan(layout: layout, windows: windows, screens: [screen])
        XCTAssertEqual(plan.map(\.window.info.id), [WindowID(2), WindowID(1)])
        XCTAssertEqual(plan.count, 2)
    }

    func testPlanClampsMissingScreen() {
        let layout = SavedLayout(
            id: "l", name: "L",
            entries: [LayoutEntry(bundleID: "com.a", screenIndex: 5, rect: FractionRect(x: 0, y: 0, width: 1, height: 1))])
        let plan = ArrangementPlanner.plan(
            layout: layout, windows: [listed(1, "com.a", "", CGRect(x: 0, y: 0, width: 10, height: 10))], screens: [screen])
        XCTAssertEqual(plan.first?.frame, screen.visibleFrame)
    }

    func testRunnerAppliesLayout() throws {
        let lister = MockWindowLister([listed(1, "com.a", "T", CGRect(x: 300, y: 300, width: 100, height: 100))])
        let (runner, provider, store, _) = makeRunner(windows: [lister.windows[0].info], lister: lister)
        try store.save(
            SavedLayout(
                id: "l", name: "L",
                entries: [LayoutEntry(
                    bundleID: "com.a", title: "T", screenIndex: 0,
                    rect: FractionRect(x: 0, y: 0, width: 0.5, height: 0.5))]))
        XCTAssertTrue(runner.perform(.layout("l")))
        XCTAssertEqual(provider.windows[WindowID(1)]?.frame, CGRect(x: 0, y: 0, width: 500, height: 400))
        XCTAssertFalse(runner.perform(.layout("nope")))
    }

    // MARK: Config

    func testConfigRoundTrip() throws {
        let source = makeSettings()
        let store = CustomLayoutStore(settings: source)
        try store.save(zone("a", shortcut: combo))
        try store.save(
            SavedLayout(
                id: "w", name: "Work",
                entries: [LayoutEntry(
                    bundleID: "com.a", title: "T", screenIndex: 1,
                    rect: FractionRect(x: 0, y: 0, width: 0.5, height: 1))],
                shortcut: KeyCombo(keyCode: KeyCombo.Key.down, modifiers: [.control, .shift])))
        let data = try ConfigDocument.export(from: source).encoded()
        let target = makeSettings()
        let skipped = try ConfigDocument.decode(from: data).apply(to: target)
        XCTAssertTrue(skipped.isEmpty, "\(skipped)")
        let imported = CustomLayoutStore(settings: target)
        XCTAssertEqual(imported.zones, store.zones)
        XCTAssertEqual(imported.layouts, store.layouts)
    }

    func testConfigToleratesUnknownKeysAndBadElements() throws {
        let json = """
        {"future": 1, "customZones": [
          {"id": "ok", "name": "Ok", "rect": {"x": 0, "y": 0, "width": 0.5, "height": 0.5}, "extra": true},
          {"id": "no-rect", "name": "Broken"},
          "garbage",
          {"id": "Bad Id", "name": "X", "rect": {"x": 0, "y": 0, "width": 1, "height": 1}},
          {"id": "huge", "name": "X", "rect": {"x": 0, "y": 0, "width": 5, "height": 1}}
        ], "savedLayouts": [{"id": "l", "name": "L", "entries": [
          {"bundleID": "com.a", "screenIndex": 0, "rect": {"x":0,"y":0,"width":1,"height":1}}, {"nope": 1}
        ], "newField": 3}]}
        """
        let settings = makeSettings()
        let skipped = try ConfigDocument.decode(from: Data(json.utf8)).apply(to: settings)
        let store = CustomLayoutStore(settings: settings)
        XCTAssertEqual(store.zones.map(\.id), ["ok"])
        XCTAssertEqual(store.layouts.map(\.id), ["l"])
        XCTAssertEqual(store.layouts[0].entries.count, 1)
        XCTAssertEqual(skipped.count, 2)  // "Bad Id" and "huge"
    }

    func testConfigAbsentFieldsKeepCurrent() throws {
        let settings = makeSettings()
        try CustomLayoutStore(settings: settings).save(zone("a"))
        try ConfigDocument.decode(from: Data(#"{"dragSnapEnabled": false}"#.utf8)).apply(to: settings)
        XCTAssertEqual(CustomLayoutStore(settings: settings).zones.map(\.id), ["a"])
    }

    func testConfigImportValidatesShortcuts() throws {
        let left = DefaultShortcuts.combo(for: .leftHalf)!
        let doc = ConfigDocument(
            customZones: [
                zone("bare", shortcut: KeyCombo(keyCode: 0, modifiers: [])),
                zone("builtin", shortcut: left),
                zone("first", shortcut: combo),
                zone("second", shortcut: combo)
            ])
        let settings = makeSettings()
        let skipped = doc.apply(to: settings)
        let zones = CustomLayoutStore(settings: settings).zones
        XCTAssertEqual(zones.map(\.id), ["bare", "builtin", "first", "second"])
        XCTAssertEqual(zones.map { $0.shortcut != nil }, [false, false, true, false])
        XCTAssertEqual(skipped.count, 3)
    }

    func testConfigImportLastDuplicateWinsAndCaps() {
        var many = (0..<(CustomLayoutStore.maxZones + 20)).map { zone("z\($0)") }
        var renamed = zone("z0")
        renamed.name = "Last"
        many.append(renamed)
        let settings = makeSettings()
        ConfigDocument(customZones: many).apply(to: settings)
        let zones = CustomLayoutStore(settings: settings).zones
        XCTAssertEqual(zones.count, CustomLayoutStore.maxZones)
        XCTAssertEqual(zones.first?.name, "Last")
    }

    func testConfigCannotSetSpacesFlag() throws {
        let settings = makeSettings()
        try ConfigDocument.decode(from: Data(#"{"spacesEnabled": true}"#.utf8)).apply(to: settings)
        XCTAssertFalse(settings.get(.spacesEnabled))
        let exported = try ConfigDocument.export(from: settings).encoded()
        XCTAssertFalse((String(bytes: exported, encoding: .utf8) ?? "").contains("spaces"))
    }

    // MARK: Automation

    func testRouterRunsRuntimeActionById() {
        let host = RuntimeHost()
        host.known = [.zone("a")]
        let router = AutomationRouter(settings: makeSettings(), host: host)
        XCTAssertEqual(router.handle(URL(string: "snapr://execute-action?name=custom:a")!), .performedRuntime(.zone("a")))
        XCTAssertEqual(host.runtime, [.zone("a")])
        XCTAssertEqual(router.handle(URL(string: "snapr://execute-action?name=custom:b")!), .unknownAction("custom:b"))
        XCTAssertEqual(router.handle(URL(string: "snapr://execute-action?name=custom:A%20x")!), .unknownAction("custom:A x"))
        XCTAssertEqual(router.handle(URL(string: "snapr://execute-action?name=left-half")!), .performed(.leftHalf))
        XCTAssertEqual(host.runtime.count, 1)
    }

    func testHostWithoutRuntimeSupportReportsUnknown() {
        final class Plain: AutomationHost { func perform(_ action: SnapAction) {} }
        let host = Plain()
        let router = AutomationRouter(settings: makeSettings(), host: host)
        XCTAssertEqual(router.handle(URL(string: "snapr://execute-action?name=custom:a")!), .unknownAction("custom:a"))
    }

    func testRunnerExistence() throws {
        let (runner, _, store, settings) = makeRunner(windows: [])
        try store.save(zone("a"))
        XCTAssertTrue(runner.exists(.zone("a")))
        XCTAssertFalse(runner.exists(.zone("b")))
        XCTAssertFalse(runner.exists(.space(.next)), "Spaces are off by default")
        _ = settings
    }

    // MARK: Spaces

    private func spaceSetup(enabled: Bool, mover: MockSpaceMover?) -> (SpaceActionController, MockWindowProvider) {
        let settings = makeSettings()
        settings.set(enabled, for: .spacesEnabled)
        let provider = MockWindowProvider(windows: [WindowInfo(id: WindowID(1), frame: CGRect(x: 0, y: 0, width: 10, height: 10))])
        return (SpaceActionController(settings: settings, windows: provider, mover: mover), provider)
    }

    func testSpacesDefaultOff() {
        XCTAssertFalse(makeSettings().get(.spacesEnabled))
        let mover = MockSpaceMover()
        mover.indices[WindowID(1)] = 1
        let (controller, _) = spaceSetup(enabled: false, mover: mover)
        XCTAssertEqual(controller.perform(.next), .disabled)
        XCTAssertTrue(mover.moveCalls.isEmpty)
        XCTAssertFalse(controller.isActive)
    }

    func testSpacesUnavailableIsNoOp() {
        let (none, _) = spaceSetup(enabled: true, mover: nil)
        XCTAssertEqual(none.perform(.next), .unavailable)
        let mover = MockSpaceMover()
        mover.isAvailable = false
        let (controller, _) = spaceSetup(enabled: true, mover: mover)
        XCTAssertEqual(controller.perform(.index(2)), .unavailable)
        XCTAssertTrue(mover.moveCalls.isEmpty)
    }

    func testSpacesMoveTargets() {
        let mover = MockSpaceMover()
        mover.indices[WindowID(1)] = 2
        let (controller, _) = spaceSetup(enabled: true, mover: mover)
        XCTAssertEqual(controller.perform(.next), .moved(toIndex: 3))
        XCTAssertEqual(controller.perform(.previous), .moved(toIndex: 2))
        XCTAssertEqual(controller.perform(.index(4)), .moved(toIndex: 4))
        XCTAssertEqual(controller.perform(.next), .noChange)  // already on the last of 4
        XCTAssertEqual(controller.perform(.index(5)), .noChange)
        XCTAssertEqual(controller.perform(.index(4)), .noChange)
        XCTAssertEqual(mover.moveCalls.count, 3)
    }

    func testSpacesUnverifiedMoveFails() {
        let mover = MockSpaceMover()
        mover.indices[WindowID(1)] = 1
        mover.movesWindows = false
        let (controller, _) = spaceSetup(enabled: true, mover: mover)
        XCTAssertEqual(controller.perform(.next), .failed)
    }

    func testSpacesNoWindow() {
        let mover = MockSpaceMover()
        let settings = makeSettings()
        settings.set(true, for: .spacesEnabled)
        let controller = SpaceActionController(settings: settings, windows: MockWindowProvider(), mover: mover)
        XCTAssertEqual(controller.perform(.next), .noWindow)
    }
}
