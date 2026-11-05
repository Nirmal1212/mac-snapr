import XCTest
@testable import SnaprCore

final class LayoutGeometryTests: XCTestCase {
    let area = CGRect(x: 0, y: 40, width: 1200, height: 800)

    func frame(_ action: SnapAction, current: CGRect? = nil, options: LayoutOptions = LayoutOptions()) -> CGRect {
        WindowGeometry.frame(for: action, in: area, current: current, options: options)!
    }

    func assertTiles(_ actions: [SnapAction], file: StaticString = #filePath, line: UInt = #line) {
        let frames = actions.map { frame($0) }
        let sum = frames.reduce(0) { $0 + $1.width * $1.height }
        XCTAssertEqual(sum, area.width * area.height, accuracy: 0.01, file: file, line: line)
        let union = frames.dropFirst().reduce(frames[0]) { $0.union($1) }
        XCTAssertEqual(union, area, file: file, line: line)
        for (i, a) in frames.enumerated() {
            for b in frames[(i + 1)...] {
                let overlap = a.intersection(b)
                XCTAssertTrue(overlap.isNull || overlap.isEmpty, file: file, line: line)
            }
        }
    }

    func testEveryCatalogActionHasFrameTitleAndCategory() {
        let current = CGRect(x: 100, y: 100, width: 400, height: 300)
        for action in LayoutCatalog.actions {
            XCTAssertNotNil(WindowGeometry.frame(for: action, in: area, current: current), action.name)
            XCTAssertFalse(action.title.isEmpty)
            XCTAssertNotEqual(action.title, action.rawValue, "missing title for \(action.name)")
        }
        XCTAssertEqual(LayoutCatalog.actions.count, 62)
        XCTAssertEqual(Set(SnapAction.allCases.map(\.name)).count, SnapAction.allCases.count)
    }

    func testFourths() {
        assertTiles([.firstFourth, .secondFourth, .thirdFourth, .lastFourth])
        XCTAssertEqual(frame(.leftThreeFourths), CGRect(x: 0, y: 40, width: 900, height: 800))
        XCTAssertEqual(frame(.rightThreeFourths), CGRect(x: 300, y: 40, width: 900, height: 800))
    }

    func testSixthsAndVerticalSixths() {
        assertTiles([.topLeftSixth, .topCenterSixth, .topRightSixth, .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth])
        assertTiles([
            .verticalSixthLeftTop, .verticalSixthLeftMiddle, .verticalSixthLeftBottom,
            .verticalSixthRightTop, .verticalSixthRightMiddle, .verticalSixthRightBottom
        ])
        XCTAssertEqual(frame(.bottomCenterSixth), CGRect(x: 400, y: 440, width: 400, height: 400))
        XCTAssertEqual(frame(.verticalSixthRightMiddle).size, CGSize(width: 600, height: 800.0 / 3))
    }

    func testEighthsAndVerticalEighths() {
        assertTiles([
            .topFirstEighth, .topSecondEighth, .topThirdEighth, .topFourthEighth,
            .bottomFirstEighth, .bottomSecondEighth, .bottomThirdEighth, .bottomFourthEighth
        ])
        assertTiles([
            .verticalEighthLeft1, .verticalEighthLeft2, .verticalEighthLeft3, .verticalEighthLeft4,
            .verticalEighthRight1, .verticalEighthRight2, .verticalEighthRight3, .verticalEighthRight4
        ])
        XCTAssertEqual(frame(.topFourthEighth), CGRect(x: 900, y: 40, width: 300, height: 400))
        XCTAssertEqual(frame(.verticalEighthRight3), CGRect(x: 600, y: 440, width: 600, height: 200))
    }

    func testNinths() {
        assertTiles([
            .ninthTopLeft, .ninthTopCenter, .ninthTopRight, .ninthMiddleLeft, .ninthMiddleCenter,
            .ninthMiddleRight, .ninthBottomLeft, .ninthBottomCenter, .ninthBottomRight
        ])
        XCTAssertEqual(frame(.ninthMiddleCenter).minX, 400, accuracy: 0.001)
    }

    func testCornerTwoThirds() {
        XCTAssertEqual(frame(.topLeftTwoThirds), CGRect(x: 0, y: 40, width: 800, height: 800.0 * 2 / 3))
        let br = frame(.bottomRightTwoThirds)
        XCTAssertEqual(br.maxX, area.maxX, accuracy: 0.001)
        XCTAssertEqual(br.maxY, area.maxY, accuracy: 0.001)
        XCTAssertEqual(br.width, 800, accuracy: 0.001)
    }

    func testCenteredLayouts() {
        XCTAssertEqual(frame(.centerHalf), CGRect(x: 300, y: 40, width: 600, height: 800))
        let almost = frame(.almostMaximize)
        XCTAssertEqual(almost.width, 1080, accuracy: 0.001)
        XCTAssertEqual(almost.midX, area.midX, accuracy: 0.001)
        XCTAssertEqual(almost.midY, area.midY, accuracy: 0.001)
        var options = LayoutOptions()
        options.almostMaximizeFraction = 0.8
        XCTAssertEqual(frame(.almostMaximize, options: options).height, 640, accuracy: 0.001)
        let prominent = frame(.centerProminently)
        XCTAssertEqual(prominent.midX, area.midX, accuracy: 0.001)
        XCTAssertGreaterThan(prominent.width, area.width / 2)
        XCTAssertLessThan(prominent.width, area.width)
    }

    func testMaximizeHeightKeepsHorizontalExtent() {
        let result = frame(.maximizeHeight, current: CGRect(x: 100, y: 300, width: 400, height: 200))
        XCTAssertEqual(result, CGRect(x: 100, y: 40, width: 400, height: 800))
    }

    func testPortraitAwareThirds() {
        let portrait = CGRect(x: 0, y: 0, width: 800, height: 1200)
        let top = WindowGeometry.frame(for: .leftThird, in: portrait)!
        XCTAssertEqual(top, CGRect(x: 0, y: 0, width: 800, height: 400))
        let lower = WindowGeometry.frame(for: .rightTwoThirds, in: portrait)!
        XCTAssertEqual(lower, CGRect(x: 0, y: 400, width: 800, height: 800))
        var off = LayoutOptions()
        off.portraitAwareThirds = false
        XCTAssertEqual(WindowGeometry.frame(for: .leftThird, in: portrait, options: off)!.width, 800.0 / 3, accuracy: 0.001)
        // Landscape is unchanged.
        XCTAssertEqual(frame(.leftThird).width, 400, accuracy: 0.001)
    }

    // MARK: Sizing and moving

    let window = CGRect(x: 300, y: 200, width: 400, height: 300)

    func testLargerGrowsAboutCenterByStep() {
        let result = frame(.larger, current: window)
        XCTAssertEqual(result.size, CGSize(width: 430, height: 330))
        XCTAssertEqual(result.midX, window.midX, accuracy: 0.001)
        XCTAssertEqual(result.midY, window.midY, accuracy: 0.001)
    }

    func testLargerStaysInsideArea() {
        let result = frame(.larger, current: CGRect(x: 0, y: 40, width: 1190, height: 800))
        XCTAssertEqual(result, area)
    }

    func testSmallerShrinksButHonorsMinimumSize() {
        XCTAssertEqual(frame(.smaller, current: window).size, CGSize(width: 370, height: 270))
        let tiny = CGRect(x: 300, y: 200, width: 210, height: 125)
        XCTAssertEqual(frame(.smaller, current: tiny).size, CGSize(width: 200, height: 120))
        let atMinimum = CGRect(x: 300, y: 200, width: 200, height: 120)
        XCTAssertEqual(frame(.smaller, current: atMinimum).size, atMinimum.size)
    }

    func testCustomResizeStep() {
        var options = LayoutOptions()
        options.resizeStep = 50
        XCTAssertEqual(frame(.larger, current: window, options: options).width, 450)
    }

    func testMoveWithoutResizing() {
        XCTAssertEqual(frame(.moveLeft, current: window), CGRect(x: 0, y: 200, width: 400, height: 300))
        XCTAssertEqual(frame(.moveRight, current: window), CGRect(x: 800, y: 200, width: 400, height: 300))
        XCTAssertEqual(frame(.moveUp, current: window), CGRect(x: 300, y: 40, width: 400, height: 300))
        XCTAssertEqual(frame(.moveDown, current: window), CGRect(x: 300, y: 540, width: 400, height: 300))
    }

    func testDoubleAndHalve() {
        XCTAssertEqual(frame(.doubleWidth, current: window), CGRect(x: 300, y: 200, width: 800, height: 300))
        let nearEdge = CGRect(x: 1000, y: 200, width: 200, height: 300)
        XCTAssertEqual(frame(.doubleWidth, current: nearEdge), CGRect(x: 800, y: 200, width: 400, height: 300))
        XCTAssertEqual(frame(.halveWidth, current: window), CGRect(x: 300, y: 200, width: 200, height: 300))
        XCTAssertEqual(frame(.doubleHeight, current: window), CGRect(x: 300, y: 200, width: 400, height: 600))
        XCTAssertEqual(frame(.halveHeight, current: window), CGRect(x: 300, y: 200, width: 400, height: 150))
    }

    func testDoubleClampsToArea() {
        let big = CGRect(x: 100, y: 100, width: 900, height: 300)
        XCTAssertEqual(frame(.doubleWidth, current: big).width, 1200)
    }

    func testSpecifiedSizeIsCenteredAndClamped() {
        var options = LayoutOptions()
        options.specifiedSize = CGSize(width: 800, height: 600)
        let result = frame(.specifiedSize, options: options)
        XCTAssertEqual(result, CGRect(x: 200, y: 140, width: 800, height: 600))
        options.specifiedSize = CGSize(width: 5000, height: 5000)
        XCTAssertEqual(frame(.specifiedSize, options: options), area)
    }

    func testSizingActionsNeedCurrentFrame() {
        XCTAssertNil(WindowGeometry.frame(for: .larger, in: area))
        XCTAssertNil(WindowGeometry.frame(for: .moveLeft, in: area))
    }

    // MARK: Half cycle order and axis keeping

    func testHalfCycleOrders() {
        XCTAssertEqual(HalfCycleOrder.rectangle.widths, [1.0 / 2, 2.0 / 3, 1.0 / 3])
        XCTAssertEqual(HalfCycleOrder.spec.widths, [1.0 / 2, 1.0 / 3, 2.0 / 3])
        XCTAssertEqual(WindowGeometry.cycleLength(for: .leftHalf), 3)
        XCTAssertEqual(WindowGeometry.cycleLength(for: .topHalf), 1)
        XCTAssertEqual(WindowGeometry.cycleLength(for: .topLeftQuarter), 1)
    }

    func testHalvesKeepOtherAxis() {
        var options = LayoutOptions()
        options.halvesKeepOtherAxis = true
        let current = CGRect(x: 100, y: 200, width: 300, height: 300)
        XCTAssertEqual(frame(.leftHalf, current: current, options: options), CGRect(x: 0, y: 200, width: 600, height: 300))
        XCTAssertEqual(frame(.rightHalf, current: current, options: options), CGRect(x: 600, y: 200, width: 600, height: 300))
        XCTAssertEqual(frame(.topHalf, current: current, options: options), CGRect(x: 100, y: 40, width: 300, height: 400))
        XCTAssertEqual(frame(.bottomHalf, current: current, options: options), CGRect(x: 100, y: 440, width: 300, height: 400))
    }

    func testQuadrantCyclingOrderIsClockwise() {
        var options = LayoutOptions()
        options.quadrantCycling = true
        let frames = (0..<4).map { WindowGeometry.frame(for: .topLeftQuarter, in: area, step: $0, options: options)! }
        XCTAssertEqual(frames[0].origin, CGPoint(x: 0, y: 40))
        XCTAssertEqual(frames[1].origin, CGPoint(x: 600, y: 40))
        XCTAssertEqual(frames[2].origin, CGPoint(x: 600, y: 440))
        XCTAssertEqual(frames[3].origin, CGPoint(x: 0, y: 440))
        XCTAssertEqual(WindowGeometry.cycleLength(for: .bottomRightQuarter, options: options), 4)
    }
}
