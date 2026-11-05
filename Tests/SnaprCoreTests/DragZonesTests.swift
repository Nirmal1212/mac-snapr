import XCTest
@testable import SnaprCore

final class DragZonesTests: XCTestCase {
    let frame = CGRect(x: 0, y: 0, width: 1000, height: 800)

    func testEdges() {
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 0, y: 400), in: frame), .left)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 999, y: 400), in: frame), .right)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 500, y: 0), in: frame), .top)
        XCTAssertNil(DragZones.zone(at: CGPoint(x: 500, y: 799), in: frame), "bottom edge alone has no zone")
    }

    func testCorners() {
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 0, y: 0), in: frame), .topLeft)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 999, y: 0), in: frame), .topRight)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 0, y: 799), in: frame), .bottomLeft)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 999, y: 799), in: frame), .bottomRight)
        XCTAssertEqual(DragZones.zone(at: CGPoint(x: 30, y: 0), in: frame), .topLeft)
    }

    func testInteriorIsNoZone() {
        XCTAssertNil(DragZones.zone(at: CGPoint(x: 500, y: 400), in: frame))
        XCTAssertNil(DragZones.zone(at: CGPoint(x: 20, y: 400), in: frame))
    }

    func testActionMapping() {
        XCTAssertEqual(DragZone.left.action, .leftHalf)
        XCTAssertEqual(DragZone.top.action, .maximize)
        XCTAssertEqual(DragZone.bottomRight.action, .bottomRightQuarter)
    }

    func testTargetFrameUsesVisibleFrame() {
        let screen = ScreenInfo(id: 1, frame: frame, visibleFrame: CGRect(x: 0, y: 25, width: 1000, height: 775))
        let hit = DragZones.target(at: CGPoint(x: 0, y: 400), screens: [screen], enabled: true)
        XCTAssertEqual(hit?.frame, CGRect(x: 0, y: 25, width: 500, height: 775))
    }

    func testDisabledProducesNoTarget() {
        let screen = ScreenInfo(id: 1, frame: frame, visibleFrame: frame)
        XCTAssertNil(DragZones.target(at: CGPoint(x: 0, y: 400), screens: [screen], enabled: false))
    }
}
