import XCTest
@testable import SnaprCore

final class SnapControllerTests: XCTestCase {
    let screen1 = ScreenInfo(
        id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
        visibleFrame: CGRect(x: 0, y: 25, width: 1000, height: 775))
    let screen2 = ScreenInfo(
        id: 2, frame: CGRect(x: 1000, y: 0, width: 2000, height: 1600),
        visibleFrame: CGRect(x: 1000, y: 0, width: 2000, height: 1600))
    let winID = WindowID(1)

    func make(
        screens: [ScreenInfo]? = nil, frame: CGRect = CGRect(x: 100, y: 100, width: 300, height: 200),
        canResize: Bool = true
    ) -> (SnapController, MockWindowProvider) {
        let windows = MockWindowProvider(windows: [WindowInfo(id: winID, frame: frame, canResize: canResize)])
        let controller = SnapController(windows: windows, screens: MockScreenProvider(screens ?? [screen1]))
        return (controller, windows)
    }

    func testSnapLeftHalf() {
        let (controller, windows) = make()
        XCTAssertTrue(controller.perform(.leftHalf))
        XCTAssertEqual(windows.windows[winID]?.frame, CGRect(x: 0, y: 25, width: 500, height: 775))
    }

    func testRepeatLeftHalfCycles() {
        let (controller, windows) = make()
        controller.perform(.leftHalf)
        controller.perform(.leftHalf)
        XCTAssertEqual(windows.windows[winID]!.frame.width, 1000.0 / 3, accuracy: 0.01)
        controller.perform(.leftHalf)
        XCTAssertEqual(windows.windows[winID]!.frame.width, 2000.0 / 3, accuracy: 0.01)
        controller.perform(.leftHalf)
        XCTAssertEqual(windows.windows[winID]!.frame.width, 500, accuracy: 0.01)
    }

    func testCycleResetsAfterOtherAction() {
        let (controller, windows) = make()
        controller.perform(.leftHalf)
        controller.perform(.topHalf)
        controller.perform(.leftHalf)
        XCTAssertEqual(windows.windows[winID]!.frame.width, 500, accuracy: 0.01)
    }

    func testRestoreReturnsToFrameBeforeFirstSnap() {
        let original = CGRect(x: 100, y: 100, width: 300, height: 200)
        let (controller, windows) = make(frame: original)
        controller.perform(.leftHalf)
        controller.perform(.topRightQuarter)
        XCTAssertTrue(controller.perform(.restore))
        XCTAssertEqual(windows.windows[winID]?.frame, original)
        XCTAssertFalse(controller.perform(.restore), "nothing left to restore")
    }

    func testManualMoveBecomesNewRestorePoint() {
        let (controller, windows) = make()
        controller.perform(.leftHalf)
        let moved = CGRect(x: 300, y: 300, width: 250, height: 250)
        windows.windows[winID]?.frame = moved
        controller.perform(.maximize)
        controller.perform(.restore)
        XCTAssertEqual(windows.windows[winID]?.frame, moved)
    }

    func testNextDisplayPreservesRelativeFrame() {
        let (controller, windows) = make(
            screens: [screen1, screen2], frame: CGRect(x: 0, y: 25, width: 500, height: 775))
        XCTAssertTrue(controller.perform(.nextDisplay))
        XCTAssertEqual(windows.windows[winID]?.frame, CGRect(x: 1000, y: 0, width: 1000, height: 1600))
    }

    func testPreviousDisplayWraps() {
        let (controller, windows) = make(
            screens: [screen1, screen2], frame: CGRect(x: 0, y: 25, width: 500, height: 775))
        XCTAssertTrue(controller.perform(.previousDisplay))
        XCTAssertGreaterThanOrEqual(windows.windows[winID]!.frame.minX, 1000)
    }

    func testSingleDisplayNextDoesNothing() {
        let (controller, windows) = make()
        let before = windows.windows[winID]
        XCTAssertFalse(controller.perform(.nextDisplay))
        XCTAssertEqual(windows.windows[winID], before)
        XCTAssertTrue(windows.setFrameCalls.isEmpty)
    }

    func testSnapUsesScreenContainingWindowCenter() {
        let (controller, windows) = make(
            screens: [screen1, screen2], frame: CGRect(x: 1500, y: 200, width: 400, height: 300))
        controller.perform(.rightHalf)
        XCTAssertEqual(windows.windows[winID]?.frame, CGRect(x: 2000, y: 0, width: 1000, height: 1600))
    }

    func testFixedSizeWindowIsMovedOnly() {
        let (controller, windows) = make(frame: CGRect(x: 100, y: 100, width: 300, height: 200), canResize: false)
        controller.perform(.rightHalf)
        let frame = windows.windows[winID]!.frame
        XCTAssertEqual(frame.size, CGSize(width: 300, height: 200))
        XCTAssertLessThanOrEqual(frame.maxX, 1000)
    }

    func testMinimumSizeOverflowIsPulledInside() {
        let (controller, windows) = make()
        windows.minimumSize = CGSize(width: 600, height: 0)
        controller.perform(.rightHalf)
        let frame = windows.windows[winID]!.frame
        XCTAssertGreaterThanOrEqual(frame.width, 600)
        XCTAssertLessThanOrEqual(frame.maxX, 1000)
    }

    func testNoFocusedWindowDoesNothing() {
        let windows = MockWindowProvider()
        let controller = SnapController(windows: windows, screens: MockScreenProvider([screen1]))
        XCTAssertFalse(controller.perform(.maximize))
    }

    func testImmovableWindowIgnored() {
        let windows = MockWindowProvider(windows: [
            WindowInfo(id: winID, frame: CGRect(x: 0, y: 0, width: 10, height: 10), canMove: false, canResize: false)
        ])
        let controller = SnapController(windows: windows, screens: MockScreenProvider([screen1]))
        XCTAssertFalse(controller.perform(.maximize))
    }

    func testFailedRestoreKeepsStoredFrame() {
        let (controller, windows) = make()
        controller.perform(.leftHalf)
        windows.windows[winID]?.canMove = false
        XCTAssertFalse(controller.perform(.restore))
        XCTAssertNotNil(controller.restoreStore.frame(for: winID))
    }
}
