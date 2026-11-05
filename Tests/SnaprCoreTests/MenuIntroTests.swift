import XCTest
@testable import SnaprCore

final class MenuIntroTests: XCTestCase {
    func testOpensOnIntroByDefault() {
        XCTAssertEqual(MenuPopoverState().page, .intro)
    }

    func testOpensOnActionsWhenIntroDisabled() {
        XCTAssertEqual(MenuPopoverState(introEnabled: false).page, .actions)
    }

    func testEveryOpenResetsToIntro() {
        var state = MenuPopoverState()
        state.showActions()
        XCTAssertEqual(state.page, .actions)
        state.didOpen(introEnabled: true)
        XCTAssertEqual(state.page, .intro)
    }

    func testIntroButtonReturnsToIntro() {
        var state = MenuPopoverState(introEnabled: false)
        state.showIntro()
        XCTAssertEqual(state.page, .intro)
        state.showActions()
        XCTAssertEqual(state.page, .actions)
    }

    func testReopenHonorsSettingChange() {
        var state = MenuPopoverState()
        state.didOpen(introEnabled: false)
        XCTAssertEqual(state.page, .actions)
    }

    func testShowIntroSettingDefaultsOnAndPersists() {
        let settings = SettingsStore(storage: MemorySettingsStorage())
        XCTAssertTrue(settings.get(.showIntroOnOpen))
        settings.set(false, for: .showIntroOnOpen)
        XCTAssertFalse(settings.get(.showIntroOnOpen))
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
    func testShowIntroRoundTripsAndTolerates() throws {
        let source = SettingsStore(storage: MemorySettingsStorage())
        source.set(false, for: .showIntroOnOpen)
        let data = try ConfigDocument.export(from: source).encoded()
        let target = SettingsStore(storage: MemorySettingsStorage())
        try ConfigDocument.decode(from: data).apply(to: target)
        XCTAssertFalse(target.get(.showIntroOnOpen))

        let bad = SettingsStore(storage: MemorySettingsStorage())
        try ConfigDocument.decode(from: Data(#"{"showIntroOnOpen": "nope"}"#.utf8)).apply(to: bad)
        XCTAssertTrue(bad.get(.showIntroOnOpen))

        let absent = SettingsStore(storage: MemorySettingsStorage())
        absent.set(false, for: .showIntroOnOpen)
        try ConfigDocument.decode(from: Data("{}".utf8)).apply(to: absent)
        XCTAssertFalse(absent.get(.showIntroOnOpen))
    }
}
