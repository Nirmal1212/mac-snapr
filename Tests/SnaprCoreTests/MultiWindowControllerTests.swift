import XCTest
@testable import SnaprCore

final class MultiWindowControllerTests: XCTestCase {
    let screen1 = ScreenInfo(
        id: 1, frame: CGRect(x: 0, y: 0, width: 1200, height: 825),
        visibleFrame: CGRect(x: 0, y: 25, width: 1200, height: 800))
    let screen2 = ScreenInfo(
        id: 2, frame: CGRect(x: 1200, y: 0, width: 1200, height: 825),
        visibleFrame: CGRect(x: 1200, y: 25, width: 1200, height: 800))

    struct Rig {
        var controller: MultiWindowController
        var list: MockWindowListProvider
        var provider: MockWindowProvider
        var box: OptionsBox
    }

    final class OptionsBox {
        var value = MultiWindowOptions()
        var layout = LayoutOptions()
    }

    func window(_ id: Int, _ frame: CGRect, app: String = "app.a", active: Bool = true) -> ManagedWindow {
        ManagedWindow(id: WindowID(id), frame: frame, bundleID: app, isActiveApp: active)
    }

    func rig(_ windows: [ManagedWindow], screens: [ScreenInfo]? = nil, configure: (OptionsBox) -> Void = { _ in }) -> Rig {
        let box = OptionsBox()
        configure(box)
        let provider = MockWindowProvider(windows: windows.map(\.info))
        let list = MockWindowListProvider(windows)
        list.frameSource = provider
        let controller = MultiWindowController(
            list: list, windows: provider, screens: MockScreenProvider(screens ?? [screen1]),
            layoutOptions: { box.layout }, options: { box.value }, saveOptions: { box.value = $0 })
        return Rig(controller: controller, list: list, provider: provider, box: box)
    }

    func frame(_ rig: Rig, _ id: Int) -> CGRect { rig.provider.windows[WindowID(id)]!.frame }

    func four() -> [ManagedWindow] {
        (1...4).map { window($0, CGRect(x: CGFloat($0) * 50, y: 100, width: 300, height: 300)) }
    }

    func testTileAllMakesGrid() {
        let r = rig(four())
        XCTAssertTrue(r.controller.perform(.tileAll))
        let frames = (1...4).map { frame(r, $0) }
        XCTAssertEqual(Set(frames.map(\.width)), [600])
        XCTAssertEqual(frames.reduce(CGRect.null) { $0.union($1) }, screen1.visibleFrame)
    }

    func testTileActiveAppLeavesOthers() {
        var windows = four()
        windows[2].isActiveApp = false
        windows[2].bundleID = "app.b"
        windows[3].isActiveApp = false
        windows[3].bundleID = "app.b"
        let r = rig(windows)
        let untouched = frame(r, 3)
        XCTAssertTrue(r.controller.perform(.tileActiveApp))
        XCTAssertEqual(frame(r, 3), untouched)
        XCTAssertEqual(frame(r, 1).width, 600)
        XCTAssertEqual(frame(r, 1).height, 800)
    }

    func testTileRowsRespectsMaxPerRow() {
        let r = rig(four()) { $0.value.maxPerRow = 3 }
        r.controller.perform(.tileRows)
        XCTAssertEqual(frame(r, 1).width, 400)
        XCTAssertEqual(frame(r, 4).width, 1200)  // balanced: last row stretches
        XCTAssertEqual(frame(r, 4).minY, 425)
    }

    func testTileColumns() {
        let r = rig(four()) { $0.value.maxPerColumn = 2 }
        r.controller.perform(.tileColumns)
        XCTAssertEqual(frame(r, 1), CGRect(x: 0, y: 25, width: 600, height: 400))
        XCTAssertEqual(frame(r, 3).minX, 600)
    }

    func testTileUsesWindowGap() {
        let r = rig(Array(four().prefix(2))) { $0.layout.gaps.windowGap = 10 }
        r.controller.perform(.tileAll)
        XCTAssertEqual(frame(r, 2).minX - frame(r, 1).maxX, 10, accuracy: 1)
    }

    func testTileHonorsStageManagerStrip() {
        let box = OptionsBox()
        box.value.stageManager.stripWidth = 200
        let provider = MockWindowProvider(windows: four().map(\.info))
        let list = MockWindowListProvider(four())
        list.frameSource = provider
        let controller = MultiWindowController(
            list: list, windows: provider, screens: MockScreenProvider([screen1]), options: { box.value },
            stageManagerActive: { true })
        controller.perform(.tileAll)
        let union = (1...4).map { provider.windows[WindowID($0)]!.frame }.reduce(CGRect.null) { $0.union($1) }
        XCTAssertEqual(union, CGRect(x: 200, y: 25, width: 1000, height: 800))
    }

    func testTodoSidebarAndTiling() {
        var windows = four()
        windows[0].bundleID = "app.todo"
        let r = rig(windows) {
            $0.value.todo.enabled = true
            $0.value.todo.bundleID = "app.todo"
            $0.value.todo.sidebarWidth = 300
            $0.value.todo.side = .right
        }
        XCTAssertTrue(r.controller.perform(.tileAll))
        XCTAssertEqual(frame(r, 1), CGRect(x: 900, y: 25, width: 300, height: 800))
        let others = (2...4).map { frame(r, $0) }
        XCTAssertEqual(others.reduce(CGRect.null) { $0.union($1) }, CGRect(x: 0, y: 25, width: 900, height: 800))
    }

    func testToggleTodoUsesFrontmostAppAndReflows() {
        var windows = [
            window(1, CGRect(x: 100, y: 100, width: 500, height: 500)),
            window(2, CGRect(x: 800, y: 100, width: 500, height: 500), app: "app.b", active: false)
        ]
        windows[0].bundleID = "app.todo"
        let r = rig(windows) { $0.value.todo.sidebarWidth = 300 }
        XCTAssertTrue(r.controller.perform(.toggleTodo))
        XCTAssertTrue(r.box.value.todo.enabled)
        XCTAssertEqual(r.box.value.todo.bundleID, "app.todo")
        XCTAssertEqual(frame(r, 1), CGRect(x: 900, y: 25, width: 300, height: 800))
        XCTAssertLessThanOrEqual(frame(r, 2).maxX, 900)  // pushed out of the sidebar
        XCTAssertTrue(r.controller.perform(.toggleTodo))
        XCTAssertFalse(r.box.value.todo.enabled)
    }

    func testCascadeAll() {
        let r = rig(four()) { $0.value.cascadeOffset = 40 }
        XCTAssertTrue(r.controller.perform(.cascadeAll))
        // Front window (first in the list) ends up last, at the largest offset.
        XCTAssertEqual(frame(r, 4).origin, CGPoint(x: 0, y: 25))
        XCTAssertEqual(frame(r, 1).origin, CGPoint(x: 120, y: 145))
        XCTAssertEqual(r.list.raised.last, WindowID(1))
    }

    func testReverseAllSwapsPositions() {
        let windows = [
            window(1, CGRect(x: 0, y: 25, width: 600, height: 800)),
            window(2, CGRect(x: 600, y: 25, width: 600, height: 800))
        ]
        let r = rig(windows)
        XCTAssertTrue(r.controller.perform(.reverseAll))
        XCTAssertEqual(frame(r, 1).minX, 600)
        XCTAssertEqual(frame(r, 2).minX, 0)
    }

    func testStackCyclingRotatesAndRaises() {
        let r = rig(Array(four().prefix(3)))
        var badges: [(Int, Int)] = []
        r.controller.onStackChanged = { index, count, _ in badges.append((index, count)) }
        XCTAssertTrue(r.controller.perform(.stackNext))
        // Order was 1,2,3 -> 2,3,1: window 2 is now the front (largest offset), raised last.
        XCTAssertEqual(r.list.raised.suffix(3), [1, 3, 2].map { WindowID($0) }[...])
        XCTAssertEqual(frame(r, 2).origin, CGPoint(x: 48, y: 73))
        XCTAssertEqual(badges.last?.0, 2)
        XCTAssertEqual(badges.last?.1, 3)
        r.controller.perform(.stackPrevious)
        XCTAssertEqual(r.list.raised.last, WindowID(1))
        XCTAssertEqual(badges.last?.0, 1)
    }

    func testStackBadgeCanBeDisabledAndSingleWindowIsNoop() {
        let r = rig(Array(four().prefix(3))) { $0.value.showStackBadge = false }
        var shown = false
        r.controller.onStackChanged = { _, _, _ in shown = true }
        r.controller.perform(.stackNext)
        XCTAssertFalse(shown)
        let single = rig([window(1, CGRect(x: 0, y: 0, width: 300, height: 300))])
        XCTAssertFalse(single.controller.perform(.stackNext))
    }

    func testCombinedDisplaysDistributeWindows() {
        let windows = [
            window(1, CGRect(x: 100, y: 100, width: 300, height: 300)),
            window(2, CGRect(x: 500, y: 100, width: 300, height: 300)),
            window(3, CGRect(x: 1300, y: 100, width: 300, height: 300)),
            window(4, CGRect(x: 1700, y: 100, width: 300, height: 300))
        ]
        let r = rig(windows, screens: [screen1, screen2]) { $0.value.combinedDisplays = true }
        r.controller.perform(.tileAll)
        for id in [1, 2] { XCTAssertTrue(screen1.visibleFrame.contains(frame(r, id)), "\(id)") }
        for id in [3, 4] { XCTAssertTrue(screen2.visibleFrame.contains(frame(r, id)), "\(id)") }
        XCTAssertEqual(frame(r, 1).width, 600)  // two windows per display, side by side
    }

    func testWithoutCombinedOnlyActiveScreenIsTiled() {
        let windows = [
            window(1, CGRect(x: 100, y: 100, width: 300, height: 300)),
            window(2, CGRect(x: 1300, y: 100, width: 300, height: 300))
        ]
        let r = rig(windows, screens: [screen1, screen2])
        let before = frame(r, 2)
        r.controller.perform(.tileAll)
        XCTAssertEqual(frame(r, 1), screen1.visibleFrame)
        XCTAssertEqual(frame(r, 2), before)
    }

    func testNoWindowsDoesNothing() {
        let r = rig([])
        for action in SnapAction.allCases where action.isMultiWindow {
            XCTAssertFalse(r.controller.perform(action), action.name)
        }
    }

    func testFixedSizeWindowStaysInsideCell() {
        var windows = four()
        windows[0].canResize = false
        let provider = MockWindowProvider(windows: windows.map(\.info))
        provider.windows[WindowID(1)]?.canResize = false
        let list = MockWindowListProvider(windows)
        let controller = MultiWindowController(list: list, windows: provider, screens: MockScreenProvider([screen1]))
        controller.perform(.tileAll)
        XCTAssertEqual(provider.windows[WindowID(1)]?.frame.size, CGSize(width: 300, height: 300))
        XCTAssertTrue(screen1.visibleFrame.contains(provider.windows[WindowID(1)]!.frame))
    }
}

final class MultiWindowSettingsTests: XCTestCase {
    func testActionsAreRegisteredAndNamedUniquely() {
        let multi = SnapAction.allCases.filter(\.isMultiWindow)
        XCTAssertEqual(multi.count, 11)
        for action in multi {
            XCTAssertEqual(ActionRegistry.action(named: action.name), action)
            XCTAssertEqual(action.category, .multiWindow)
            XCTAssertNotEqual(action.title, action.name)
            XCTAssertNil(DefaultShortcuts.combo(for: action))
        }
        XCTAssertEqual(Set(SnapAction.allCases.map(\.name)).count, SnapAction.allCases.count)
        XCTAssertTrue(ActionRegistry.grouped().contains { $0.category == .multiWindow })
    }

    func testTolerantDecoding() throws {
        let json = #"{"maxPerRow": 3, "cascadeOffset": "bad", "todo": {"enabled": true, "side": "nonsense"}, "unknown": 1}"#
        let options = try JSONDecoder().decode(MultiWindowOptions.self, from: Data(json.utf8))
        XCTAssertEqual(options.maxPerRow, 3)
        XCTAssertEqual(options.cascadeOffset, 30)
        XCTAssertTrue(options.todo.enabled)
        XCTAssertEqual(options.todo.side, .right)
        XCTAssertEqual(try JSONDecoder().decode(MultiWindowOptions.self, from: Data("{}".utf8)), MultiWindowOptions())
    }

    func testNegativeValuesAreClamped() throws {
        let options = try JSONDecoder().decode(
            MultiWindowOptions.self, from: Data(#"{"maxPerRow": -4, "cascadeOffset": 0}"#.utf8))
        XCTAssertEqual(options.maxPerRow, 0)
        XCTAssertEqual(options.cascadeOffset, 1)
    }

    func testConfigRoundTrip() throws {
        let source = SettingsStore(storage: MemorySettingsStorage())
        var options = MultiWindowOptions()
        options.maxPerRow = 4
        options.todo.enabled = true
        options.newWindowAction = "left-half"
        source.set(options, for: .multiWindowOptions)
        let data = try ConfigDocument.export(from: source).encoded()
        let target = SettingsStore(storage: MemorySettingsStorage())
        try ConfigDocument.decode(from: data).apply(to: target)
        XCTAssertEqual(target.get(.multiWindowOptions), options)
    }

    func testConfigWithoutFieldKeepsSettings() throws {
        let store = SettingsStore(storage: MemorySettingsStorage())
        var options = MultiWindowOptions()
        options.stackOffset = 50
        store.set(options, for: .multiWindowOptions)
        try ConfigDocument.decode(from: Data("{}".utf8)).apply(to: store)
        XCTAssertEqual(store.get(.multiWindowOptions).stackOffset, 50)
    }

    func testURLSchemeReachesNewActions() {
        final class Host: AutomationHost {
            var performed: [SnapAction] = []
            func perform(_ action: SnapAction) { performed.append(action) }
        }
        let host = Host()
        let router = AutomationRouter(settings: SettingsStore(storage: MemorySettingsStorage()), host: host)
        XCTAssertEqual(router.handle(URL(string: "snapr://execute-action?name=tile-all")!), .performed(.tileAll))
        XCTAssertEqual(router.handle(URL(string: "snapr://execute-action?name=stack-next")!), .performed(.stackNext))
        XCTAssertEqual(host.performed, [.tileAll, .stackNext])
    }
}

final class NewWindowMonitorTests: XCTestCase {
    func make(action: String?) -> (NewWindowMonitor, MockWindowListProvider, () -> [(SnapAction, WindowID)], (String?) -> Void) {
        var options = MultiWindowOptions()
        options.newWindowAction = action
        var applied: [(SnapAction, WindowID)] = []
        let list = MockWindowListProvider([
            ManagedWindow(id: WindowID(1), frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        ])
        let monitor = NewWindowMonitor(list: list, options: { options }) { action, window in
            applied.append((action, window.id))
        }
        return (monitor, list, { applied }, { options.newWindowAction = $0 })
    }

    func testExistingWindowsAreNotTouchedAndNewOnesAre() {
        let (monitor, list, applied, _) = make(action: "left-half")
        XCTAssertEqual(monitor.scan(), [])
        list.windows.append(ManagedWindow(id: WindowID(2), frame: CGRect(x: 0, y: 0, width: 300, height: 300)))
        XCTAssertEqual(monitor.scan(), [WindowID(2)])
        XCTAssertEqual(applied().map(\.0), [.leftHalf])
        XCTAssertEqual(monitor.scan(), [])  // not applied twice
        XCTAssertEqual(applied().count, 1)
    }

    func testDisabledOrUnknownActionDoesNothing() {
        let (monitor, list, applied, _) = make(action: nil)
        XCTAssertFalse(monitor.isEnabled)
        monitor.scan()
        list.windows.append(ManagedWindow(id: WindowID(2), frame: CGRect(x: 0, y: 0, width: 300, height: 300)))
        monitor.scan()
        XCTAssertTrue(applied().isEmpty)
        let (unknown, _, _, _) = make(action: "no-such-action")
        XCTAssertFalse(unknown.isEnabled)
    }

    func testTinyWindowsAreRetriedLater() {
        let (monitor, list, applied, _) = make(action: "maximize")
        monitor.scan()
        list.windows.append(ManagedWindow(id: WindowID(2), frame: CGRect(x: 0, y: 0, width: 0, height: 0)))
        XCTAssertEqual(monitor.scan(), [])
        list.windows[1].frame = CGRect(x: 0, y: 0, width: 400, height: 300)
        XCTAssertEqual(monitor.scan(), [WindowID(2)])
        XCTAssertEqual(applied().count, 1)
    }

    func testMultiWindowActionIsNotAllowedAsNewWindowAction() {
        let (monitor, list, applied, _) = make(action: "tile-all")
        XCTAssertFalse(monitor.isEnabled)
        monitor.scan()
        list.windows.append(ManagedWindow(id: WindowID(2), frame: CGRect(x: 0, y: 0, width: 300, height: 300)))
        monitor.scan()
        XCTAssertTrue(applied().isEmpty)
    }

    func testUnminimizedOrReappearingWindowIsNotNew() {
        let (monitor, list, applied, _) = make(action: "left-half")
        monitor.scan()
        let extra = ManagedWindow(id: WindowID(2), frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        list.windows.append(extra)
        XCTAssertEqual(monitor.scan(), [WindowID(2)])
        // Minimized / other Space: dropped from the listing for many scans, then back.
        list.windows.removeLast()
        for _ in 0..<50 { monitor.scan() }
        list.windows.append(extra)
        XCTAssertEqual(monitor.scan(), [])
        XCTAssertEqual(applied().count, 1)
    }

    func testTrackedIdsAreBounded() {
        let (monitor, list, _, _) = make(action: "left-half")
        monitor.scan()
        for i in 10..<(10 + NewWindowMonitor.maxTracked + 50) {
            list.windows = [ManagedWindow(id: WindowID(i), frame: CGRect(x: 0, y: 0, width: 300, height: 300))]
            monitor.scan()
        }
        // Oldest ids were forgotten; the newest is still known.
        XCTAssertEqual(monitor.scan(), [])
    }
}

final class MultiWindowSecurityTests: XCTestCase {
    func testTodoActionsRefusedFromURL() {
        final class Host: AutomationHost {
            var performed: [SnapAction] = []
            func perform(_ action: SnapAction) { performed.append(action) }
        }
        let host = Host()
        let router = AutomationRouter(settings: SettingsStore(storage: MemorySettingsStorage()), host: host)
        XCTAssertEqual(
            router.handle(URL(string: "snapr://execute-action?name=toggle-todo")!), .refused("toggle-todo"))
        XCTAssertEqual(
            router.handle(URL(string: "snapr://execute-action?name=reflow-todo")!), .refused("reflow-todo"))
        XCTAssertTrue(host.performed.isEmpty)
        XCTAssertEqual(router.handle(URL(string: "snapr://execute-action?name=tile-all")!), .performed(.tileAll))
    }

    func testImportSanitizesOptions() throws {
        var options = MultiWindowOptions()
        options.newWindowAction = "toggle-todo"
        options.todo.bundleID = "bad id; rm"
        let store = SettingsStore(storage: MemorySettingsStorage())
        ConfigDocument(multiWindow: options).apply(to: store)
        XCTAssertNil(store.get(.multiWindowOptions).newWindowAction)
        XCTAssertNil(store.get(.multiWindowOptions).todo.bundleID)
        options.newWindowAction = "no-such"
        XCTAssertNil(options.sanitized().newWindowAction)
        options.newWindowAction = "left-half"
        options.todo.bundleID = "com.example.todo"
        XCTAssertEqual(options.sanitized(), options)
    }

    func testReservedProviderCachesUntilSettingsChange() {
        let store = SettingsStore(storage: MemorySettingsStorage())
        var stageCalls = 0
        let screen = ScreenInfo(
            id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
            visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
        let provider = ReservedScreenProvider(
            base: MockScreenProvider([screen]), settings: store, stageManagerActive: { stageCalls += 1; return true })
        _ = provider.screens()
        _ = provider.screens()
        XCTAssertEqual(stageCalls, 1)
        XCTAssertEqual(provider.screens()[0].visibleFrame.minX, 190)
        var options = MultiWindowOptions()
        options.stageManager.stripWidth = 100
        store.set(options, for: .multiWindowOptions)
        XCTAssertEqual(provider.screens()[0].visibleFrame.minX, 100)
        XCTAssertEqual(stageCalls, 2)
    }
}
