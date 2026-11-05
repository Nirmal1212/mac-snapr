import XCTest
@testable import SnaprCore

final class MenuIntroTests: XCTestCase {
    func testFirstOpenShowsIntro() {
        XCTAssertEqual(MenuPopoverState().page, .intro)
        var state = MenuPopoverState(introSeen: true)
        XCTAssertEqual(state.page, .actions)
        XCTAssertTrue(state.didOpen(introSeen: false))
        XCTAssertEqual(state.page, .intro)
    }

    func testAfterIntroSeenOpensOnActions() {
        var state = MenuPopoverState()
        XCTAssertFalse(state.didOpen(introSeen: true))
        XCTAssertEqual(state.page, .actions)
    }

    func testIntroButtonAndShowActions() {
        var state = MenuPopoverState(introSeen: true)
        state.showIntro()
        XCTAssertEqual(state.page, .intro)
        state.showActions()
        XCTAssertEqual(state.page, .actions)
    }

    func testResetIntroSeenShowsIntroAgain() {
        let settings = SettingsStore(storage: MemorySettingsStorage())
        XCTAssertFalse(settings.get(.introSeen))
        settings.set(true, for: .introSeen)
        var state = MenuPopoverState()
        state.didOpen(introSeen: settings.get(.introSeen))
        XCTAssertEqual(state.page, .actions)
        settings.set(false, for: .introSeen)
        state.didOpen(introSeen: settings.get(.introSeen))
        XCTAssertEqual(state.page, .intro)
    }

    func testIntroSeenToleratesGarbage() {
        let storage = MemorySettingsStorage()
        storage.set(Data("\"x\"".utf8), forKey: "introSeen")
        XCTAssertFalse(SettingsStore(storage: storage).get(.introSeen))
    }

    func testPopoverGroupOrder() {
        let groups = PopoverActionLayout.groups()
        let titles = groups.map(\.title)
        let q = titles.firstIndex(of: ActionCategory.quarters.rawValue)!
        XCTAssertEqual(titles[q + 1], "Maximize & Center")
        XCTAssertEqual(titles[q + 2], ActionCategory.thirds.rawValue)
        XCTAssertEqual(groups[q + 1].actions, [.maximize, .center, .restore, .maximizeHeight])
        // Every registry action appears exactly once.
        let all = groups.flatMap(\.actions)
        XCTAssertEqual(all.count, Set(all).count)
        XCTAssertEqual(Set(all), Set(ActionRegistry.all))
        // Moved actions are gone from their original categories.
        for g in groups where g.title != "Maximize & Center" {
            XCTAssertTrue(Set(g.actions).isDisjoint(with: PopoverActionLayout.sizeActions))
        }
    }

    func testShortcutTipUsesCurrentBinding() {
        var map = ShortcutMap()
        XCTAssertTrue(IntroContent.shortcutTip(map).contains(DefaultShortcuts.combo(for: .leftHalf)!.displayString))
        let custom = KeyCombo(keyCode: KeyCombo.Key.up, modifiers: [.control, .command])
        map.assign(custom, to: .leftHalf)
        XCTAssertTrue(IntroContent.shortcutTip(map).contains(custom.displayString))
    }

    func testShortcutTipWhenUnbound() {
        var map = ShortcutMap()
        map.clear(.leftHalf)
        XCTAssertTrue(IntroContent.shortcutTip(map).contains("Settings"))
    }

    // MARK: target window tracking

    func testTrackerIgnoresOwnActivation() {
        var tracker = ExternalAppTracker(ownPID: 1, initialFrontmost: 50)
        tracker.activated(pid: 1)  // popover takes focus
        XCTAssertEqual(tracker.lastExternalPID, 50)
        tracker.activated(pid: 60)
        XCTAssertEqual(tracker.lastExternalPID, 60)
    }

    func testTrackerStartingFrontmostIsSelf() {
        XCTAssertNil(ExternalAppTracker(ownPID: 1, initialFrontmost: 1).lastExternalPID)
    }

    func testActionAfterPopoverFocusStillMovesPreviousWindow() {
        // The provider answers for the previously focused window even after Snapr was activated.
        let id = WindowID(7)
        let windows = MockWindowProvider(windows: [
            WindowInfo(id: id, frame: CGRect(x: 100, y: 100, width: 300, height: 200))
        ])
        let screen = ScreenInfo(
            id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
            visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
        let controller = SnapController(windows: windows, screens: MockScreenProvider([screen]))
        var tracker = ExternalAppTracker(ownPID: 1, initialFrontmost: 50)
        tracker.activated(pid: 1)
        XCTAssertEqual(tracker.lastExternalPID, 50)
        XCTAssertTrue(controller.perform(.leftHalf))
        XCTAssertEqual(windows.windows[id]?.frame, CGRect(x: 0, y: 0, width: 500, height: 800))
    }
}

final class ConfigIntroTests: XCTestCase {
    func testIntroSeenIsNotExportedAndOldKeyIgnored() throws {
        let source = SettingsStore(storage: MemorySettingsStorage())
        source.set(true, for: .introSeen)
        let data = try ConfigDocument.export(from: source).encoded()
        let text = String(bytes: data, encoding: .utf8) ?? ""
        XCTAssertFalse(text.contains("introSeen"))
        XCTAssertFalse(text.contains("showIntroOnOpen"))

        let target = SettingsStore(storage: MemorySettingsStorage())
        try ConfigDocument.decode(from: Data(#"{"showIntroOnOpen": false, "introSeen": true}"#.utf8)).apply(to: target)
        XCTAssertFalse(target.get(.introSeen))
    }
}
