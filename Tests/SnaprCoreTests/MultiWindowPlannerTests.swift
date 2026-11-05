import XCTest
@testable import SnaprCore

final class MultiWindowPlannerTests: XCTestCase {
    let area = CGRect(x: 0, y: 0, width: 1200, height: 800)

    func testBalancedColumnsFollowAspectRatio() {
        XCTAssertEqual(MultiWindowPlanner.balancedColumns(count: 1, area: area.size), 1)
        XCTAssertEqual(MultiWindowPlanner.balancedColumns(count: 4, area: area.size), 2)
        XCTAssertEqual(MultiWindowPlanner.balancedColumns(count: 2, area: area.size), 2)
        // Portrait area stacks windows.
        XCTAssertEqual(MultiWindowPlanner.balancedColumns(count: 2, area: CGSize(width: 600, height: 1200)), 1)
    }

    func testGridTwoByTwoCoversArea() {
        let frames = MultiWindowPlanner.grid(count: 4, columns: 2, in: area, balanced: true)
        XCTAssertEqual(frames[0], CGRect(x: 0, y: 0, width: 600, height: 400))
        XCTAssertEqual(frames[3], CGRect(x: 600, y: 400, width: 600, height: 400))
        XCTAssertEqual(frames.map { $0.width * $0.height }.reduce(0, +), area.width * area.height)
    }

    func testBalancedLastRowStretches() {
        let frames = MultiWindowPlanner.grid(count: 5, columns: 3, in: area, balanced: true)
        XCTAssertEqual(frames[3].width, 600)
        XCTAssertEqual(frames[4].maxX, area.maxX)
        let loose = MultiWindowPlanner.grid(count: 5, columns: 3, in: area, balanced: false)
        XCTAssertEqual(loose[3].width, 400)
    }

    func testRowsMaxPerRow() {
        let frames = MultiWindowPlanner.rows(count: 5, perRow: 3, in: area, balanced: true)
        XCTAssertEqual(frames.prefix(3).map(\.minY), [0, 0, 0])
        XCTAssertEqual(frames[3].minY, 400)
        XCTAssertEqual(frames[3].width, 600)
        XCTAssertEqual(MultiWindowPlanner.rows(count: 3, perRow: 0, in: area, balanced: true).map(\.minY), [0, 0, 0])
    }

    func testColumnsMaxPerColumn() {
        let frames = MultiWindowPlanner.columns(count: 5, perColumn: 3, in: area, balanced: true)
        XCTAssertEqual(frames[0], CGRect(x: 0, y: 0, width: 600, height: 267))
        XCTAssertEqual(frames[1].minX, 0)
        XCTAssertEqual(frames[3].minX, 600)
        XCTAssertEqual(frames[3].height, 400)
        XCTAssertEqual(frames[4].maxY, area.maxY)
    }

    func testGapAndNoOverlap() {
        let frames = MultiWindowPlanner.grid(count: 6, columns: 3, in: area, balanced: true, gap: 10)
        for (i, a) in frames.enumerated() {
            XCTAssertTrue(area.contains(a))
            for b in frames[(i + 1)...] {
                let overlap = a.intersection(b)
                XCTAssertTrue(overlap.isNull || overlap.isEmpty)
            }
        }
        XCTAssertEqual(frames[1].minX - frames[0].maxX, 10, accuracy: 1)
        XCTAssertEqual(frames[3].minY - frames[0].maxY, 10, accuracy: 1)
        XCTAssertEqual(frames[0].minX, 0)  // no gap at the screen edge
    }

    func testCascadeOffsets() {
        let size = CGSize(width: 500, height: 400)
        let frames = MultiWindowPlanner.cascade(sizes: [size, size, size], in: area, offset: 30)
        XCTAssertEqual(frames.map(\.origin), [CGPoint(x: 0, y: 0), CGPoint(x: 30, y: 30), CGPoint(x: 60, y: 60)])
        XCTAssertEqual(frames[0].size, size)
    }

    func testCascadeKeepsWindowsInsideAndWraps() {
        let size = CGSize(width: 1100, height: 780)
        let frames = MultiWindowPlanner.cascade(sizes: Array(repeating: size, count: 40), in: area, offset: 30)
        for frame in frames { XCTAssertTrue(area.contains(frame), "\(frame)") }
        let steps = MultiWindowPlanner.maxSteps(in: area, offset: 30)
        XCTAssertEqual(frames[steps].origin, frames[0].origin)
    }

    func testStackFrontAtLargestOffset() {
        let sizes = [CGSize(width: 800, height: 600), CGSize(width: 500, height: 400), CGSize(width: 300, height: 300)]
        let same = MultiWindowPlanner.stack(sizes: sizes, in: area, offset: 24, sameSize: true)
        XCTAssertEqual(same[0].origin, CGPoint(x: 48, y: 48))
        XCTAssertEqual(same[2].origin, CGPoint(x: 0, y: 0))
        XCTAssertTrue(same.allSatisfy { $0.size == sizes[0] })
        let own = MultiWindowPlanner.stack(sizes: sizes, in: area, offset: 24, sameSize: false)
        XCTAssertEqual(own[1].size, sizes[1])
    }

    func testReverseSwapsFrames() {
        let left = ManagedWindow(id: WindowID(1), frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let right = ManagedWindow(id: WindowID(2), frame: CGRect(x: 500, y: 0, width: 200, height: 100))
        let result = Dictionary(uniqueKeysWithValues: MultiWindowPlanner.reversed([right, left]).map { ($0.id, $0.frame) })
        XCTAssertEqual(result[WindowID(1)], right.frame)
        XCTAssertEqual(result[WindowID(2)], left.frame)
    }

    func testDistributeProportional() {
        XCTAssertEqual(MultiWindowPlanner.distribute(count: 4, weights: [1, 1]), [2, 2])
        XCTAssertEqual(MultiWindowPlanner.distribute(count: 6, weights: [1, 2]), [2, 4])
        XCTAssertEqual(MultiWindowPlanner.distribute(count: 5, weights: [1, 1]).reduce(0, +), 5)
        XCTAssertEqual(MultiWindowPlanner.distribute(count: 3, weights: [0, 0]), [0, 0])
    }

    func testFittingShrinksAndMovesInside() {
        let content = CGRect(x: 0, y: 0, width: 800, height: 600)
        let fitted = MultiWindowPlanner.fitting(CGRect(x: 700, y: 100, width: 300, height: 700), in: content)
        XCTAssertEqual(fitted, CGRect(x: 500, y: 0, width: 300, height: 600))
    }
}

final class ReservedAreasTests: XCTestCase {
    let rect = CGRect(x: 0, y: 25, width: 1000, height: 775)

    func testStageManagerStrip() {
        var options = MultiWindowOptions()
        options.stageManager.stripWidth = 190
        let parts = ReservedAreas.layout(rect, isTodoScreen: true, options: options, stageManagerActive: true)
        XCTAssertEqual(parts.content, CGRect(x: 190, y: 25, width: 810, height: 775))
        XCTAssertNil(parts.todo)
        XCTAssertEqual(ReservedAreas.layout(rect, isTodoScreen: true, options: options, stageManagerActive: false).content, rect)
        options.stageManager.enabled = false
        XCTAssertEqual(ReservedAreas.layout(rect, isTodoScreen: true, options: options, stageManagerActive: true).content, rect)
    }

    func testTodoSidebarRight() {
        var options = MultiWindowOptions()
        options.todo.enabled = true
        options.todo.sidebarWidth = 300
        let parts = ReservedAreas.layout(rect, isTodoScreen: true, options: options, stageManagerActive: false)
        XCTAssertEqual(parts.todo, CGRect(x: 700, y: 25, width: 300, height: 775))
        XCTAssertEqual(parts.content, CGRect(x: 0, y: 25, width: 700, height: 775))
        XCTAssertNil(ReservedAreas.layout(rect, isTodoScreen: false, options: options, stageManagerActive: false).todo)
    }

    func testStageThenTodo() {
        var options = MultiWindowOptions()
        options.todo.enabled = true
        options.todo.sidebarWidth = 300
        options.todo.side = .left
        let parts = ReservedAreas.layout(rect, isTodoScreen: true, options: options, stageManagerActive: true)
        XCTAssertEqual(parts.todo, CGRect(x: 190, y: 25, width: 300, height: 775))
        XCTAssertEqual(parts.content.minX, 490)
    }

    func testOversizedReservationIgnored() {
        var options = MultiWindowOptions()
        options.todo.enabled = true
        options.todo.sidebarWidth = 600
        XCTAssertNil(ReservedAreas.layout(rect, isTodoScreen: true, options: options, stageManagerActive: false).todo)
    }

    func testTodoScreenSelection() {
        let a = ScreenInfo(id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800), visibleFrame: rect)
        let b = ScreenInfo(id: 2, frame: CGRect(x: 1000, y: 0, width: 1000, height: 800), visibleFrame: rect)
        var options = MultiWindowOptions()
        XCTAssertEqual(ReservedAreas.todoScreen(in: [b, a], options: options)?.id, 1)
        options.todo.screenID = 2
        XCTAssertEqual(ReservedAreas.todoScreen(in: [a, b], options: options)?.id, 2)
        options.todo.screenID = 99
        XCTAssertEqual(ReservedAreas.todoScreen(in: [a, b], options: options)?.id, 1)
    }

    func testReservedScreenProviderShrinksVisibleFrame() {
        let screen = ScreenInfo(id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800), visibleFrame: rect)
        var options = MultiWindowOptions()
        options.stageManager.stripWidth = 100
        let provider = ReservedScreenProvider(
            base: MockScreenProvider([screen]), options: { options }, stageManagerActive: { true })
        XCTAssertEqual(provider.screens()[0].visibleFrame, CGRect(x: 100, y: 25, width: 900, height: 775))
        XCTAssertEqual(provider.screens()[0].frame, screen.frame)
    }

    func testSnapControllerAvoidsStripThroughDecorator() {
        let screen = ScreenInfo(id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800), visibleFrame: rect)
        var options = MultiWindowOptions()
        options.stageManager.stripWidth = 200
        let provider = ReservedScreenProvider(
            base: MockScreenProvider([screen]), options: { options }, stageManagerActive: { true })
        let windows = MockWindowProvider(windows: [WindowInfo(id: WindowID(1), frame: CGRect(x: 300, y: 100, width: 300, height: 200))])
        let controller = SnapController(windows: windows, screens: provider)
        XCTAssertTrue(controller.perform(.leftHalf))
        XCTAssertEqual(windows.windows[WindowID(1)]?.frame, CGRect(x: 200, y: 25, width: 400, height: 775))
    }
}
