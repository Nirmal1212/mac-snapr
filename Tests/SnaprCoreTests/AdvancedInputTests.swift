import XCTest
@testable import SnaprCore

final class AdvancedDragZoneTests: XCTestCase {
    let frame = CGRect(x: 0, y: 0, width: 900, height: 600)

    func options(_ extra: Set<DragZone>) -> DragSnapOptions {
        var o = DragSnapOptions()
        o.enabledZones.formUnion(extra)
        return o
    }

    func testBottomThirdsAreOptIn() {
        let point = CGPoint(x: 150, y: 599)
        XCTAssertNil(DragZones.zone(at: point, in: frame))
        XCTAssertEqual(DragZones.zone(at: point, in: frame, options: options([.leftThird])), .leftThird)
    }

    func testBottomThirdsAcrossEdge() {
        let o = options([.leftThird, .centerThird, .rightThird])
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 450, y: 599), in: frame, options: o), .centerThird)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 750, y: 599), in: frame, options: o), .rightThird)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 5, y: 599), in: frame, options: o), .bottomLeft, "corner wins")
    }

    func testTwoThirdsAtBoundaries() {
        let o = options([.leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds])
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 300, y: 599), in: frame, options: o), .leftTwoThirds)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 600, y: 599), in: frame, options: o), .rightTwoThirds)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 450, y: 599), in: frame, options: o), .centerThird)
    }

    func testDisabledTwoThirdsFallsBackToThird() {
        let o = options([.leftThird, .centerThird])
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 290, y: 599), in: frame, options: o), .leftThird)
    }

    func testHalfZonesBesideCorners() {
        let o = options([.topHalf, .bottomHalf])
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 90, y: 0), in: frame, options: o), .topHalf)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 450, y: 0), in: frame, options: o), .top)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 810, y: 599), in: frame, options: o), .bottomHalf)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 30, y: 0), in: frame, options: o), .topLeft)
    }

    func testSixthsReplaceQuartersWhenEnabled() {
        let o = options([.topLeftSixth])
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 0, y: 0), in: frame, options: o), .topLeftSixth)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 899, y: 0), in: frame, options: o), .topRight)
    }

    func testSixthFrames() {
        let visible = CGRect(x: 0, y: 30, width: 900, height: 600)
        XCTAssertEqual(DragZone.topLeftSixth.frame(in: visible), CGRect(x: 0, y: 30, width: 300, height: 300))
        XCTAssertEqual(DragZone.bottomRightSixth.frame(in: visible), CGRect(x: 600, y: 330, width: 300, height: 300))
        XCTAssertEqual(DragZone.leftTwoThirds.frame(in: visible), CGRect(x: 0, y: 30, width: 600, height: 600))
    }

    func testDisablingACoreZone() {
        var o = DragSnapOptions()
        o.enabledZones.remove(.left)
        XCTAssertNil(DragZones.zone(at: CGPoint(x: 0, y: 300), in: frame, options: o))
    }

    func testMargins() {
        var o = DragSnapOptions()
        XCTAssertNil(DragZones.zone(at: CGPoint(x: 20, y: 300), in: frame, options: o))
        o.edgeMargin = 25
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 20, y: 300), in: frame, options: o), .left)
        o.cornerSize = 200
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 150, y: 0), in: frame, options: o), .topLeft)
    }

    func testModifierRequirement() {
        var o = DragSnapOptions()
        XCTAssertTrue(o.modifiersSatisfied(by: []))
        o.requiredModifiers = [.option]
        XCTAssertFalse(o.modifiersSatisfied(by: []))
        XCTAssertFalse(o.modifiersSatisfied(by: [.shift]))
        XCTAssertTrue(o.modifiersSatisfied(by: [.option, .shift]))
    }

    func testOptionsDecodeTolerantly() throws {
        let decoded = try JSONDecoder().decode(DragSnapOptions.self, from: Data("{\"edgeMargin\":12}".utf8))
        XCTAssertEqual(decoded.edgeMargin, 12)
        XCTAssertEqual(decoded.enabledZones, DragZone.defaultEnabled)
        let roundTrip = try JSONDecoder().decode(DragSnapOptions.self, from: JSONEncoder().encode(options([.leftThird])))
        XCTAssertTrue(roundTrip.enabledZones.contains(.leftThird))
    }
}

final class TriggerHelperTests: XCTestCase {
    func testMouseShortcutMatching() {
        let list = [
            MouseShortcut(button: 2, modifiers: [], action: .maximize),
            MouseShortcut(button: 3, modifiers: [.option], action: .leftHalf, underPointer: true)
        ]
        XCTAssertEqual(MouseShortcuts.match(list, button: 2, modifiers: [])?.action, .maximize)
        XCTAssertEqual(MouseShortcuts.match(list, button: 3, modifiers: [.option])?.underPointer, true)
        XCTAssertNil(MouseShortcuts.match(list, button: 3, modifiers: []), "modifiers must match exactly")
        XCTAssertNil(MouseShortcuts.match(list, button: 4, modifiers: []))
        XCTAssertNil(MouseShortcuts.match([MouseShortcut(button: 0, action: .maximize)], button: 0, modifiers: []))
    }

    func testRouterConsumesMatchedPressDragsAndRelease() {
        let shortcut = MouseShortcut(button: 3, modifiers: [.option], action: .maximize)
        var router = MouseButtonRouter(shortcuts: [shortcut])
        XCTAssertEqual(router.route(.down, button: 3, modifiers: [.option]), .run(shortcut))
        XCTAssertEqual(router.route(.dragged, button: 3, modifiers: []), .consume)
        XCTAssertEqual(router.route(.up, button: 3, modifiers: []), .consume)
        XCTAssertEqual(router.route(.up, button: 3, modifiers: []), .passThrough, "release consumed only once")
    }

    func testRouterPassesThroughUnmatched() {
        var router = MouseButtonRouter(shortcuts: [MouseShortcut(button: 3, modifiers: [.option], action: .maximize)])
        XCTAssertEqual(router.route(.down, button: 3, modifiers: []), .passThrough)
        XCTAssertEqual(router.route(.up, button: 3, modifiers: []), .passThrough)
        XCTAssertEqual(router.route(.down, button: 2, modifiers: [.option]), .passThrough)
        XCTAssertEqual(router.route(.dragged, button: 2, modifiers: []), .passThrough)
        XCTAssertEqual(router.route(.down, button: 0, modifiers: [.option]), .passThrough)
    }

    func testTitleBarHitAndToggle() {
        let window = CGRect(x: 100, y: 100, width: 400, height: 300)
        XCTAssertTrue(TitleBar.contains(CGPoint(x: 200, y: 110), in: window))
        XCTAssertFalse(TitleBar.contains(CGPoint(x: 200, y: 200), in: window))
        XCTAssertFalse(TitleBar.contains(CGPoint(x: 50, y: 110), in: window))
        let visible = CGRect(x: 0, y: 25, width: 1000, height: 775)
        XCTAssertEqual(TitleBar.toggleAction(windowFrame: window, visible: visible), .maximize)
        XCTAssertEqual(TitleBar.toggleAction(windowFrame: visible, visible: visible), .restore)
    }

    func testFrameAnimation() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 100, y: 200, width: 300, height: 400)
        let frames = FrameAnimation.frames(from: a, to: b, steps: 5)
        XCTAssertEqual(frames.count, 5)
        XCTAssertEqual(frames.last, b)
        XCTAssertTrue(frames[0].minX > 0 && frames[0].minX < frames[1].minX)
        XCTAssertEqual(FrameAnimation.frames(from: a, to: b, steps: 1), [b])
    }
}

final class DisplayRulesTests: XCTestCase {
    // System order lists the right display first.
    let right = ScreenInfo(id: 2, frame: CGRect(x: 1000, y: 0, width: 2000, height: 1000),
                           visibleFrame: CGRect(x: 1000, y: 0, width: 2000, height: 1000))
    let left = ScreenInfo(id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
                          visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))

    func makeController(frame: CGRect, rules: DisplayRules) -> (SnapController, MockWindowProvider, MockCursorProvider) {
        let window = WindowInfo(id: WindowID(1), frame: frame)
        let provider = MockWindowProvider(windows: [window])
        let controller = SnapController(windows: provider, screens: MockScreenProvider([right, left]))
        let cursor = MockCursorProvider()
        controller.displayRules = rules
        controller.cursor = cursor
        return (controller, provider, cursor)
    }

    func testNeighborOrdering() {
        XCTAssertEqual(ScreenGeometry.neighbor(of: left, in: [right, left], forward: true)?.id, 2)
        XCTAssertEqual(ScreenGeometry.neighbor(of: left, in: [right, left], forward: true, byX: false)?.id, 2)
        XCTAssertEqual(ScreenGeometry.neighbor(of: right, in: [right, left], forward: true, byX: false)?.id, 1)
        XCTAssertEqual(ScreenGeometry.neighbor(of: right, in: [right, left], forward: true)?.id, 1, "wraps")
    }

    func testKeepSizeWhenMaximized() {
        var rules = DisplayRules()
        rules.keepSizeWhenMaximized = true
        let (controller, provider, _) = makeController(frame: left.visibleFrame, rules: rules)
        controller.perform(.nextDisplay)
        XCTAssertEqual(provider.windows[WindowID(1)]?.frame, CGRect(x: 1500, y: 100, width: 1000, height: 800))
    }

    func testMaximizedScalesByDefault() {
        let (controller, provider, _) = makeController(frame: left.visibleFrame, rules: DisplayRules())
        controller.perform(.nextDisplay)
        XCTAssertEqual(provider.windows[WindowID(1)]?.frame, right.visibleFrame)
    }

    func testRepeatLastActionOnOtherDisplay() {
        var rules = DisplayRules()
        rules.repeatLastAction = true
        let (controller, provider, _) = makeController(frame: CGRect(x: 100, y: 100, width: 300, height: 300), rules: rules)
        controller.perform(.topLeftQuarter)
        controller.perform(.nextDisplay)
        XCTAssertEqual(provider.windows[WindowID(1)]?.frame, CGRect(x: 1000, y: 0, width: 1000, height: 500))
        controller.perform(.nextDisplay)
        XCTAssertEqual(provider.windows[WindowID(1)]?.frame, CGRect(x: 0, y: 0, width: 500, height: 400), "still repeating")
    }

    func testNoRepeatAfterManualMove() {
        var rules = DisplayRules()
        rules.repeatLastAction = true
        let (controller, provider, _) = makeController(frame: CGRect(x: 100, y: 100, width: 300, height: 300), rules: rules)
        controller.perform(.leftHalf)
        provider.windows[WindowID(1)]?.frame = CGRect(x: 50, y: 50, width: 200, height: 200)
        controller.perform(.nextDisplay)
        XCTAssertEqual(provider.windows[WindowID(1)]?.frame.size, CGSize(width: 400, height: 250))
    }

    func testCursorFollowsWindow() {
        var rules = DisplayRules()
        rules.moveCursorWithWindow = true
        let (controller, _, cursor) = makeController(frame: left.visibleFrame, rules: rules)
        controller.perform(.nextDisplay)
        XCTAssertEqual(cursor.moves, [CGPoint(x: 2000, y: 500)])
        let (off, _, offCursor) = makeController(frame: left.visibleFrame, rules: DisplayRules())
        off.perform(.nextDisplay)
        XCTAssertTrue(offCursor.moves.isEmpty)
    }

    func testSnapToArbitraryFrameRecordsRestore() {
        let (controller, provider, _) = makeController(frame: CGRect(x: 10, y: 10, width: 300, height: 200), rules: DisplayRules())
        let window = provider.windows[WindowID(1)]!
        let target = DragZone.topLeftSixth.frame(in: left.visibleFrame)
        XCTAssertTrue(controller.snap(window, toFrame: target, screen: left))
        XCTAssertEqual(provider.windows[WindowID(1)]?.frame, target)
        controller.perform(.restore)
        XCTAssertEqual(provider.windows[WindowID(1)]?.frame, CGRect(x: 10, y: 10, width: 300, height: 200))
    }
}
