import XCTest
@testable import SnaprCore

final class LayoutBehaviorTests: XCTestCase {
    let screen1 = ScreenInfo(
        id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
        visibleFrame: CGRect(x: 0, y: 25, width: 1000, height: 775))
    let screen2 = ScreenInfo(
        id: 2, frame: CGRect(x: 1000, y: 0, width: 2000, height: 1600),
        visibleFrame: CGRect(x: 1000, y: 0, width: 2000, height: 1600))
    let winID = WindowID(1)
    let original = CGRect(x: 100, y: 100, width: 300, height: 200)

    func make(
        _ configure: (inout LayoutOptions) -> Void = { _ in }, screens: [ScreenInfo]? = nil,
        frame: CGRect? = nil, minimumSize: CGSize = .zero
    ) -> (SnapController, MockWindowProvider) {
        var options = LayoutOptions()
        configure(&options)
        let windows = MockWindowProvider(windows: [WindowInfo(id: winID, frame: frame ?? original)])
        windows.minimumSize = minimumSize
        let controller = SnapController(
            windows: windows, screens: MockScreenProvider(screens ?? [screen1]), options: { options })
        return (controller, windows)
    }

    func frame(_ windows: MockWindowProvider) -> CGRect { windows.windows[winID]!.frame }

    // MARK: Cycle order

    func testDefaultCycleIsRectangleOrder() {
        let (controller, windows) = make()
        var widths: [CGFloat] = []
        for _ in 0..<4 {
            controller.perform(.rightHalf)
            widths.append(frame(windows).width)
        }
        XCTAssertEqual(widths[0], 500, accuracy: 0.51)
        XCTAssertEqual(widths[1], 2000.0 / 3, accuracy: 0.51)
        XCTAssertEqual(widths[2], 1000.0 / 3, accuracy: 0.51)
        XCTAssertEqual(widths[3], 500, accuracy: 0.51)
        XCTAssertEqual(frame(windows).maxX, 1000, accuracy: 0.51)
    }

    func testSpecCycleOrderIsConfigurable() {
        let (controller, windows) = make { $0.halfCycleOrder = .spec }
        controller.perform(.leftHalf)
        controller.perform(.leftHalf)
        XCTAssertEqual(frame(windows).width, 1000.0 / 3, accuracy: 0.51)
        controller.perform(.leftHalf)
        XCTAssertEqual(frame(windows).width, 2000.0 / 3, accuracy: 0.51)
    }

    // MARK: Repeat behaviors

    func testRepeatedSideActionMovesToAdjacentDisplay() {
        let (controller, windows) = make({ $0.repeatBehavior = .moveToAdjacentDisplay }, screens: [screen1, screen2])
        controller.perform(.rightHalf)
        XCTAssertEqual(frame(windows), CGRect(x: 500, y: 25, width: 500, height: 775))
        controller.perform(.rightHalf)
        XCTAssertEqual(frame(windows), CGRect(x: 2000, y: 0, width: 1000, height: 1600))
        // No display further right: falls back to cycling sizes.
        controller.perform(.rightHalf)
        XCTAssertEqual(frame(windows).width, 2000.0 * 2 / 3, accuracy: 0.51)
        // Left half walks back.
        controller.perform(.leftHalf)
        controller.perform(.leftHalf)
        XCTAssertEqual(frame(windows).minX, 0, accuracy: 0.51)
    }

    func testQuadrantCycling() {
        let (controller, windows) = make { $0.quadrantCycling = true }
        controller.perform(.topLeftQuarter)
        XCTAssertEqual(frame(windows).origin, CGPoint(x: 0, y: 25))
        controller.perform(.topLeftQuarter)
        XCTAssertEqual(frame(windows).origin, CGPoint(x: 500, y: 25))
        controller.perform(.topLeftQuarter)
        XCTAssertEqual(frame(windows).origin.y, 25 + 775.0 / 2, accuracy: 0.51)
        XCTAssertEqual(frame(windows).origin.x, 500, accuracy: 0.51)
    }

    func testQuarterDoesNotCycleByDefault() {
        let (controller, windows) = make()
        controller.perform(.topLeftQuarter)
        controller.perform(.topLeftQuarter)
        XCTAssertEqual(frame(windows).origin, CGPoint(x: 0, y: 25))
    }

    func testOppositeSideSwitchKeepsWidth() {
        let (controller, windows) = make { $0.oppositeSideSwitch = true }
        controller.perform(.leftHalf)
        controller.perform(.leftHalf)  // 2/3
        controller.perform(.rightHalf)
        XCTAssertEqual(frame(windows).width, 2000.0 / 3, accuracy: 0.51)
        XCTAssertEqual(frame(windows).maxX, 1000, accuracy: 0.51)
    }

    func testOppositeSideRestartsCycleByDefault() {
        let (controller, windows) = make()
        controller.perform(.leftHalf)
        controller.perform(.leftHalf)
        controller.perform(.rightHalf)
        XCTAssertEqual(frame(windows).width, 500, accuracy: 0.51)
    }

    func testRepeatedMaximizeRestores() {
        let (controller, windows) = make { $0.repeatedMaximizeRestores = true }
        controller.perform(.maximize)
        XCTAssertEqual(frame(windows), screen1.visibleFrame)
        controller.perform(.maximize)
        XCTAssertEqual(frame(windows), original)
        controller.perform(.maximize)
        XCTAssertEqual(frame(windows), screen1.visibleFrame)
    }

    func testRepeatedMaximizeStaysMaximizedByDefault() {
        let (controller, windows) = make()
        controller.perform(.maximize)
        controller.perform(.maximize)
        XCTAssertEqual(frame(windows), screen1.visibleFrame)
    }

    func testHalvesKeepOtherAxisViaController() {
        let (controller, windows) = make { $0.halvesKeepOtherAxis = true }
        controller.perform(.leftHalf)
        XCTAssertEqual(frame(windows), CGRect(x: 0, y: 100, width: 500, height: 200))
    }

    func testSizingActionThroughController() {
        let (controller, windows) = make()
        XCTAssertTrue(controller.perform(.larger))
        XCTAssertEqual(frame(windows).size, CGSize(width: 330, height: 230))
        XCTAssertTrue(controller.perform(.restore))
        XCTAssertEqual(frame(windows), original)
    }

    // MARK: Fit handling

    func testFitAlignsToRightEdgeAndReportsMinimumSize() {
        let (controller, windows) = make(minimumSize: CGSize(width: 500, height: 0))
        var reported: (CGRect, CGRect)?
        controller.onMinimumSizeReached = { reported = ($0, $1) }
        controller.perform(.rightThird)
        let result = frame(windows)
        XCTAssertEqual(result.width, 500, accuracy: 0.51)
        XCTAssertEqual(result.maxX, 1000, accuracy: 0.01, "stays flush with the right edge")
        XCTAssertNotNil(reported)
        XCTAssertEqual(reported?.0.width ?? 0, 1000.0 / 3, accuracy: 0.51)
    }

    func testFitAnchorsBottomRightCorner() {
        let (controller, windows) = make(minimumSize: CGSize(width: 700, height: 600))
        controller.perform(.bottomRightQuarter)
        let result = frame(windows)
        XCTAssertEqual(result.maxX, 1000, accuracy: 0.51)
        XCTAssertEqual(result.maxY, 800, accuracy: 0.51)
    }

    func testNoHUDWhenTargetReached() {
        let (controller, _) = make()
        var called = false
        controller.onMinimumSizeReached = { _, _ in called = true }
        controller.perform(.leftHalf)
        XCTAssertFalse(called)
    }

    func testSmallerAtLimitReportsMinimumSize() {
        let (controller, windows) = make(frame: CGRect(x: 100, y: 100, width: 200, height: 120))
        var called = false
        controller.onMinimumSizeReached = { _, _ in called = true }
        controller.perform(.smaller)
        XCTAssertEqual(frame(windows).size, CGSize(width: 200, height: 120))
        XCTAssertTrue(called)
    }

    func testFitPureFunction() {
        let area = CGRect(x: 0, y: 0, width: 900, height: 600)
        let target = CGRect(x: 0, y: 0, width: 300, height: 600)  // left third
        let actual = CGRect(x: 0, y: 0, width: 500, height: 600)
        XCTAssertEqual(LayoutEngine.fit(actual, target: target, in: area), actual)
        let centerTarget = CGRect(x: 300, y: 0, width: 300, height: 600)
        let fitted = LayoutEngine.fit(CGRect(x: 300, y: 0, width: 500, height: 600), target: centerTarget, in: area)
        XCTAssertEqual(fitted.midX, 450, accuracy: 0.51)
        let exact = CGRect(x: 300, y: 0, width: 300, height: 600)
        XCTAssertEqual(LayoutEngine.fit(exact, target: centerTarget, in: area), exact)
    }

    // MARK: Unsnap

    func testUnsnapRestoresPreviousSizeUnderCursor() {
        let (controller, windows) = make()
        controller.perform(.leftHalf)
        let snapped = frame(windows)
        let cursor = CGPoint(x: 250, y: 40)
        let moved = snapped.offsetBy(dx: 10, dy: 10)
        windows.windows[winID]?.frame = moved
        let result = controller.unsnap(winID, snappedFrame: snapped, current: moved, cursor: cursor)
        XCTAssertEqual(result?.size, original.size)
        XCTAssertEqual(frame(windows).size, original.size)
        // Cursor was at 50% of the snapped window width; it stays at 50% of the restored one.
        XCTAssertEqual((cursor.x - frame(windows).minX) / original.width, (250 - 10) / 500, accuracy: 0.51)
        XCTAssertFalse(controller.perform(.restore), "restore point consumed by unsnap")
    }

    func testUnsnapIgnoresUnsnappedWindowAndRespectsSetting() {
        let (controller, _) = make()
        XCTAssertNil(controller.unsnap(winID, snappedFrame: original, current: original, cursor: CGPoint(x: 150, y: 120)))
        let (disabled, windows) = make { $0.unsnapRestoresSize = false }
        disabled.perform(.leftHalf)
        let snapped = frame(windows)
        XCTAssertNil(disabled.unsnap(winID, snappedFrame: snapped, current: snapped, cursor: CGPoint(x: 100, y: 40)))
    }

    func testUnsnappedMath() {
        let current = CGRect(x: 0, y: 0, width: 500, height: 800)
        let result = LayoutEngine.unsnapped(current: current, restoreSize: CGSize(width: 300, height: 200), cursor: CGPoint(x: 250, y: 10))
        XCTAssertEqual(result, CGRect(x: 100, y: 0, width: 300, height: 200))
    }
}
