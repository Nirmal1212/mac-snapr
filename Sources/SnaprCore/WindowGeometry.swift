import CoreGraphics

/// Pure geometry. All rects use one global space with the origin at the top-left of the
/// primary display and y growing downwards (the Accessibility API convention).
public enum WindowGeometry {
    /// Number of positions in the repeat cycle of `action` (1 = no cycling).
    public static func cycleLength(for action: SnapAction, options: LayoutOptions = LayoutOptions()) -> Int {
        switch action {
        case .leftHalf, .rightHalf: return options.halfCycleOrder.widths.count
        case .topLeftQuarter, .topRightQuarter, .bottomRightQuarter, .bottomLeftQuarter:
            return options.quadrantCycling ? quadrantOrder.count : 1
        default: return 1
        }
    }

    /// Quarter actions in clockwise order, used by quadrant cycling.
    static let quadrantOrder: [SnapAction] = [.topLeftQuarter, .topRightQuarter, .bottomRightQuarter, .bottomLeftQuarter]

    /// Target frame for a region action within `visible`. Returns nil for actions that are
    /// not region based (restore, display moves) or that need `current` and lack it.
    /// - Parameters:
    ///   - current: the window's current frame (used by center, sizing/moving and axis-keeping actions).
    ///   - step: position in the repeat cycle (left/right half widths, quadrant cycling).
    ///   - options: layout settings (cycle order, portrait thirds, ...).
    public static func frame(
        for action: SnapAction, in visible: CGRect, current: CGRect? = nil, step: Int = 0,
        options: LayoutOptions = LayoutOptions()
    ) -> CGRect? {
        let (x, y, w, h) = (visible.minX, visible.minY, visible.width, visible.height)
        let portrait = options.portraitAwareThirds && h > w
        switch action {
        case .leftHalf, .rightHalf:
            let widths = options.halfCycleOrder.widths
            let width = w * widths[((step % widths.count) + widths.count) % widths.count]
            let (top, height) = options.halvesKeepOtherAxis ? verticalSpan(of: current, in: visible) : (y, h)
            let left = action == .leftHalf ? x : visible.maxX - width
            return CGRect(x: left, y: top, width: width, height: height)
        case .topHalf, .bottomHalf:
            let (left, width) = options.halvesKeepOtherAxis ? horizontalSpan(of: current, in: visible) : (x, w)
            return CGRect(x: left, y: action == .topHalf ? y : y + h / 2, width: width, height: h / 2)
        case .topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter:
            var quadrant = action
            if options.quadrantCycling, let index = quadrantOrder.firstIndex(of: action) {
                quadrant = quadrantOrder[(index + max(step, 0)) % quadrantOrder.count]
            }
            let right = quadrant == .topRightQuarter || quadrant == .bottomRightQuarter
            let bottom = quadrant == .bottomLeftQuarter || quadrant == .bottomRightQuarter
            return CGRect(x: right ? x + w / 2 : x, y: bottom ? y + h / 2 : y, width: w / 2, height: h / 2)
        case .leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds:
            // (start, length) in thirds along the main axis; portrait screens stack thirds vertically.
            let span: (Int, Int)
            switch action {
            case .leftThird: span = (0, 1)
            case .centerThird: span = (1, 1)
            case .rightThird: span = (2, 1)
            case .leftTwoThirds: span = (0, 2)
            default: span = (1, 2)
            }
            if portrait {
                return CGRect(x: x, y: y + h * CGFloat(span.0) / 3, width: w, height: h * CGFloat(span.1) / 3)
            }
            return CGRect(x: x + w * CGFloat(span.0) / 3, y: y, width: w * CGFloat(span.1) / 3, height: h)
        case .maximize: return visible
        case .center:
            let size = current?.size ?? CGSize(width: w / 2, height: h / 2)
            return centered(size: size, in: visible)
        case .restore, .nextDisplay, .previousDisplay: return nil
        // MARK: add-layout-engine
        case .firstFourth, .secondFourth, .thirdFourth, .lastFourth, .leftThreeFourths, .rightThreeFourths:
            return LayoutCatalog.frame(for: action, in: visible, current: current, step: step, options: options)
        case .topLeftSixth, .topCenterSixth, .topRightSixth, .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth:
            return LayoutCatalog.frame(for: action, in: visible, current: current, step: step, options: options)
        case .verticalSixthLeftTop, .verticalSixthLeftMiddle, .verticalSixthLeftBottom,
            .verticalSixthRightTop, .verticalSixthRightMiddle, .verticalSixthRightBottom:
            return LayoutCatalog.frame(for: action, in: visible, current: current, step: step, options: options)
        case .topFirstEighth, .topSecondEighth, .topThirdEighth, .topFourthEighth, .bottomFirstEighth,
            .bottomSecondEighth, .bottomThirdEighth, .bottomFourthEighth:
            return LayoutCatalog.frame(for: action, in: visible, current: current, step: step, options: options)
        case .verticalEighthLeft1, .verticalEighthLeft2, .verticalEighthLeft3, .verticalEighthLeft4,
            .verticalEighthRight1, .verticalEighthRight2, .verticalEighthRight3, .verticalEighthRight4:
            return LayoutCatalog.frame(for: action, in: visible, current: current, step: step, options: options)
        case .ninthTopLeft, .ninthTopCenter, .ninthTopRight, .ninthMiddleLeft, .ninthMiddleCenter,
            .ninthMiddleRight, .ninthBottomLeft, .ninthBottomCenter, .ninthBottomRight:
            return LayoutCatalog.frame(for: action, in: visible, current: current, step: step, options: options)
        case .topLeftTwoThirds, .topRightTwoThirds, .bottomLeftTwoThirds, .bottomRightTwoThirds:
            return LayoutCatalog.frame(for: action, in: visible, current: current, step: step, options: options)
        case .centerHalf, .centerProminently, .almostMaximize, .maximizeHeight:
            return LayoutCatalog.frame(for: action, in: visible, current: current, step: step, options: options)
        case .larger, .smaller, .moveLeft, .moveRight, .moveUp, .moveDown, .doubleWidth, .halveWidth,
            .doubleHeight, .halveHeight, .specifiedSize:
            return LayoutCatalog.frame(for: action, in: visible, current: current, step: step, options: options)
        // MARK: add-multi-window-modes
        case .tileAll, .tileActiveApp, .tileRows, .tileColumns, .cascadeAll, .cascadeActiveApp, .stackNext,
            .stackPrevious, .reverseAll, .toggleTodo, .reflowTodo:
            return nil  // multi-window actions are planned by MultiWindowPlanner
        }
    }

    private static func verticalSpan(of current: CGRect?, in visible: CGRect) -> (CGFloat, CGFloat) {
        guard let current else { return (visible.minY, visible.height) }
        let clamped = clamped(current, to: visible)
        return (clamped.minY, clamped.height)
    }

    private static func horizontalSpan(of current: CGRect?, in visible: CGRect) -> (CGFloat, CGFloat) {
        guard let current else { return (visible.minX, visible.width) }
        let clamped = clamped(current, to: visible)
        return (clamped.minX, clamped.width)
    }

    /// A rect of `size` (clamped to `visible`) centered inside `visible`.
    public static func centered(size: CGSize, in visible: CGRect) -> CGRect {
        let width = min(size.width, visible.width)
        let height = min(size.height, visible.height)
        return CGRect(x: visible.midX - width / 2, y: visible.midY - height / 2, width: width, height: height)
    }

    /// Re-maps `frame` from `source` to `destination`, preserving relative position and size.
    public static func relativeFrame(_ frame: CGRect, from source: CGRect, to destination: CGRect) -> CGRect {
        guard source.width > 0, source.height > 0 else { return frame }
        let sx = destination.width / source.width
        let sy = destination.height / source.height
        return CGRect(
            x: destination.minX + (frame.minX - source.minX) * sx,
            y: destination.minY + (frame.minY - source.minY) * sy,
            width: frame.width * sx,
            height: frame.height * sy
        )
    }

    /// Moves `frame` (without resizing unless larger than `bounds`) so it lies inside `bounds`.
    public static func clamped(_ frame: CGRect, to bounds: CGRect) -> CGRect {
        let width = min(frame.width, bounds.width)
        let height = min(frame.height, bounds.height)
        let x = min(max(frame.minX, bounds.minX), bounds.maxX - width)
        let y = min(max(frame.minY, bounds.minY), bounds.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    public static func approximatelyEqual(_ a: CGRect, _ b: CGRect, tolerance: CGFloat = 2) -> Bool {
        abs(a.minX - b.minX) <= tolerance && abs(a.minY - b.minY) <= tolerance
            && abs(a.width - b.width) <= tolerance && abs(a.height - b.height) <= tolerance
    }
}
