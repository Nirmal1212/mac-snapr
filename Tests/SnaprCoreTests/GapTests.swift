import XCTest
@testable import SnaprCore

final class GapTests: XCTestCase {
    let primary = ScreenInfo(
        id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
        visibleFrame: CGRect(x: 0, y: 25, width: 1000, height: 775))
    let secondary = ScreenInfo(
        id: 2, frame: CGRect(x: 1000, y: 0, width: 1000, height: 800),
        visibleFrame: CGRect(x: 1000, y: 25, width: 1000, height: 775))

    func options(_ configure: (inout GapOptions) -> Void) -> LayoutOptions {
        var options = LayoutOptions()
        configure(&options.gaps)
        return options
    }

    func target(_ action: SnapAction, on screen: ScreenInfo? = nil, _ options: LayoutOptions) -> CGRect {
        LayoutEngine.target(
            for: action, on: screen ?? primary, isPrimary: (screen ?? primary).id == 1, options: options)!
    }

    func testWindowGapSeparatesNeighboursByExactlyGap() {
        let o = options { $0.windowGap = 10 }
        let left = target(.leftHalf, o)
        let right = target(.rightHalf, o)
        XCTAssertEqual(right.minX - left.maxX, 10, accuracy: 0.001)
        XCTAssertEqual(left.minX, 0, accuracy: 0.001)
        XCTAssertEqual(right.maxX, 1000, accuracy: 0.001)
        XCTAssertEqual(left.minY, 25, accuracy: 0.001)
        XCTAssertEqual(left.height, 775, accuracy: 0.001)
    }

    func testWindowGapInQuarterGrid() {
        let o = options { $0.windowGap = 8 }
        let tl = target(.topLeftQuarter, o)
        let br = target(.bottomRightQuarter, o)
        XCTAssertEqual(br.minX - tl.maxX, 8, accuracy: 0.001)
        XCTAssertEqual(br.minY - tl.maxY, 8, accuracy: 0.001)
    }

    func testScreenGapsInsetTheArea() {
        let o = options { $0.screenGaps = EdgeGaps(top: 5, left: 20, bottom: 10, right: 30) }
        XCTAssertEqual(target(.maximize, o), CGRect(x: 20, y: 30, width: 950, height: 760))
        XCTAssertEqual(target(.leftHalf, o).minX, 20, accuracy: 0.001)
        XCTAssertEqual(target(.rightHalf, o).maxX, 970, accuracy: 0.001)
    }

    func testMainScreenOnly() {
        let o = options {
            $0.windowGap = 10
            $0.screenGaps = EdgeGaps(top: 10, left: 10, bottom: 10, right: 10)
            $0.mainScreenOnly = true
        }
        XCTAssertEqual(target(.maximize, on: secondary, o), secondary.visibleFrame)
        XCTAssertNotEqual(target(.maximize, on: primary, o), primary.visibleFrame)
        XCTAssertTrue(LayoutEngine.isPrimary(primary, in: [secondary, primary]))
        XCTAssertFalse(LayoutEngine.isPrimary(secondary, in: [secondary, primary]))
    }

    func testPerActionExemption() {
        let o = options {
            $0.windowGap = 10
            $0.screenGaps = EdgeGaps(top: 10, left: 10, bottom: 10, right: 10)
            $0.exemptActions = [SnapAction.maximize.name]
        }
        XCTAssertEqual(target(.maximize, o), primary.visibleFrame)
        XCTAssertNotEqual(target(.leftHalf, o), WindowGeometry.frame(for: .leftHalf, in: primary.visibleFrame))
    }

    func testSizingActionsGetScreenGapsButNoWindowGap() {
        let o = options { $0.windowGap = 10 }
        let current = CGRect(x: 100, y: 100, width: 400, height: 300)
        let result = LayoutEngine.target(for: .larger, on: primary, current: current, options: o)!
        XCTAssertEqual(result.size, CGSize(width: 430, height: 330))
    }

    func testNotchAwareTopGap() {
        let notched = ScreenInfo(
            id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
            visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800), safeAreaTop: 32)
        var o = LayoutOptions()
        XCTAssertEqual(LayoutEngine.target(for: .maximize, on: notched, options: o)!.minY, 32, accuracy: 0.001)
        o.gaps.notchAwareTopGap = false
        XCTAssertEqual(LayoutEngine.target(for: .maximize, on: notched, options: o)!.minY, 0, accuracy: 0.001)
    }

    func testNotchDoesNotShiftWhenMenuBarAlreadyBelow() {
        let notched = ScreenInfo(
            id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
            visibleFrame: CGRect(x: 0, y: 38, width: 1000, height: 762), safeAreaTop: 32)
        XCTAssertEqual(LayoutEngine.target(for: .maximize, on: notched)!.minY, 38, accuracy: 0.001)
    }

    func testFullHeightWhenMenuBarHidden() {
        let hidden = ScreenInfo(
            id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
            visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
        var o = options { $0.screenGaps = EdgeGaps(top: 12) }
        XCTAssertEqual(LayoutEngine.target(for: .maximize, on: hidden, options: o)!.minY, 12, accuracy: 0.001)
        o.gaps.fullHeightWhenMenuBarHidden = true
        XCTAssertEqual(LayoutEngine.target(for: .maximize, on: hidden, options: o)!.minY, 0, accuracy: 0.001)
        // Menu bar visible: the top gap still applies.
        XCTAssertEqual(LayoutEngine.target(for: .maximize, on: primary, options: o)!.minY, 37, accuracy: 0.001)
    }

    func testDragZoneTargetUsesGaps() {
        let o = options { $0.windowGap = 10 }
        let hit = DragZones.target(at: CGPoint(x: 2, y: 400), screens: [primary], enabled: true, options: o)
        XCTAssertEqual(hit?.frame.maxX ?? 0, 495, accuracy: 0.001)
    }

    func testControllerAppliesGaps() {
        var o = LayoutOptions()
        o.gaps.windowGap = 10
        let windows = MockWindowProvider(windows: [WindowInfo(id: WindowID(1), frame: CGRect(x: 100, y: 100, width: 300, height: 200))])
        let controller = SnapController(windows: windows, screens: MockScreenProvider([primary]), options: { o })
        controller.perform(.rightHalf)
        XCTAssertEqual(windows.windows[WindowID(1)]?.frame, CGRect(x: 505, y: 25, width: 495, height: 775))
    }
}
