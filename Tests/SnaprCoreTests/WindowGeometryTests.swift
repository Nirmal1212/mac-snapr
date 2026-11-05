import XCTest
@testable import SnaprCore

final class WindowGeometryTests: XCTestCase {
    let visible = CGRect(x: 0, y: 25, width: 1200, height: 775)

    func testLeftHalf() {
        XCTAssertEqual(WindowGeometry.frame(for: .leftHalf, in: visible), CGRect(x: 0, y: 25, width: 600, height: 775))
    }

    func testRightHalfAnchorsToRightEdge() {
        XCTAssertEqual(WindowGeometry.frame(for: .rightHalf, in: visible), CGRect(x: 600, y: 25, width: 600, height: 775))
        var spec = LayoutOptions()
        spec.halfCycleOrder = .spec
        let third = WindowGeometry.frame(for: .rightHalf, in: visible, step: 1, options: spec)!
        XCTAssertEqual(third.maxX, visible.maxX, accuracy: 0.001)
        XCTAssertEqual(third.width, 400, accuracy: 0.001)
    }

    func testTopQuarterRight() {
        XCTAssertEqual(
            WindowGeometry.frame(for: .topRightQuarter, in: visible),
            CGRect(x: 600, y: 25, width: 600, height: 387.5))
    }

    func testThirdsTileTheScreen() {
        let l = WindowGeometry.frame(for: .leftThird, in: visible)!
        let c = WindowGeometry.frame(for: .centerThird, in: visible)!
        let r = WindowGeometry.frame(for: .rightThird, in: visible)!
        XCTAssertEqual(l.maxX, c.minX, accuracy: 0.001)
        XCTAssertEqual(c.maxX, r.minX, accuracy: 0.001)
        XCTAssertEqual(r.maxX, visible.maxX, accuracy: 0.001)
    }

    func testTwoThirds() {
        XCTAssertEqual(WindowGeometry.frame(for: .leftTwoThirds, in: visible)!.width, 800, accuracy: 0.001)
        XCTAssertEqual(WindowGeometry.frame(for: .rightTwoThirds, in: visible)!.maxX, 1200, accuracy: 0.001)
    }

    func testMaximizeIsVisibleFrame() {
        XCTAssertEqual(WindowGeometry.frame(for: .maximize, in: visible), visible)
    }

    func testCenterKeepsSize() {
        let current = CGRect(x: 0, y: 0, width: 400, height: 300)
        let frame = WindowGeometry.frame(for: .center, in: visible, current: current)!
        XCTAssertEqual(frame.size, current.size)
        XCTAssertEqual(frame.midX, visible.midX, accuracy: 0.001)
        XCTAssertEqual(frame.midY, visible.midY, accuracy: 0.001)
    }

    func testCenterClampsOversizedWindow() {
        let frame = WindowGeometry.centered(size: CGSize(width: 5000, height: 5000), in: visible)
        XCTAssertEqual(frame, visible)
    }

    func testNonRegionActionsHaveNoFrame() {
        XCTAssertNil(WindowGeometry.frame(for: .restore, in: visible))
        XCTAssertNil(WindowGeometry.frame(for: .nextDisplay, in: visible))
    }

    func testRelativeFramePreservesPosition() {
        let src = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let dst = CGRect(x: 1000, y: 0, width: 2000, height: 1600)
        let moved = WindowGeometry.relativeFrame(CGRect(x: 500, y: 400, width: 250, height: 200), from: src, to: dst)
        XCTAssertEqual(moved, CGRect(x: 2000, y: 800, width: 500, height: 400))
    }

    func testClampedKeepsWindowInside() {
        let frame = WindowGeometry.clamped(CGRect(x: 1100, y: -50, width: 300, height: 200), to: visible)
        XCTAssertEqual(frame, CGRect(x: 900, y: 25, width: 300, height: 200))
    }

    func testCoordinateFlipIsInvolution() {
        let rect = CGRect(x: 10, y: 20, width: 300, height: 200)
        let flipped = CoordinateSpace.flip(rect, primaryHeight: 900)
        XCTAssertEqual(flipped, CGRect(x: 10, y: 680, width: 300, height: 200))
        XCTAssertEqual(CoordinateSpace.flip(flipped, primaryHeight: 900), rect)
        XCTAssertEqual(CoordinateSpace.flip(CGPoint(x: 5, y: 100), primaryHeight: 900), CGPoint(x: 5, y: 800))
    }
}
