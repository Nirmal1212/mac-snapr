import CoreGraphics

/// Pure geometry. All rects use one global space with the origin at the top-left of the
/// primary display and y growing downwards (the Accessibility API convention).
public enum WindowGeometry {
    /// Widths a repeated left/right half action cycles through.
    public static let halfCycle: [CGFloat] = [1.0 / 2, 1.0 / 3, 2.0 / 3]

    public static func cycleLength(for action: SnapAction) -> Int {
        (action == .leftHalf || action == .rightHalf) ? halfCycle.count : 1
    }

    /// Target frame for a region action within `visible`. Returns nil for actions that are
    /// not region based (restore, display moves).
    /// - Parameters:
    ///   - current: the window's current frame (used by `.center` to keep its size).
    ///   - step: position in the repeat cycle (only affects left/right half).
    public static func frame(for action: SnapAction, in visible: CGRect, current: CGRect? = nil, step: Int = 0) -> CGRect? {
        let (x, y, w, h) = (visible.minX, visible.minY, visible.width, visible.height)
        switch action {
        case .leftHalf:
            return CGRect(x: x, y: y, width: w * halfCycle[step % halfCycle.count], height: h)
        case .rightHalf:
            let width = w * halfCycle[step % halfCycle.count]
            return CGRect(x: visible.maxX - width, y: y, width: width, height: h)
        case .topHalf: return CGRect(x: x, y: y, width: w, height: h / 2)
        case .bottomHalf: return CGRect(x: x, y: y + h / 2, width: w, height: h / 2)
        case .topLeftQuarter: return CGRect(x: x, y: y, width: w / 2, height: h / 2)
        case .topRightQuarter: return CGRect(x: x + w / 2, y: y, width: w / 2, height: h / 2)
        case .bottomLeftQuarter: return CGRect(x: x, y: y + h / 2, width: w / 2, height: h / 2)
        case .bottomRightQuarter: return CGRect(x: x + w / 2, y: y + h / 2, width: w / 2, height: h / 2)
        case .leftThird: return CGRect(x: x, y: y, width: w / 3, height: h)
        case .centerThird: return CGRect(x: x + w / 3, y: y, width: w / 3, height: h)
        case .rightThird: return CGRect(x: x + 2 * w / 3, y: y, width: w / 3, height: h)
        case .leftTwoThirds: return CGRect(x: x, y: y, width: 2 * w / 3, height: h)
        case .rightTwoThirds: return CGRect(x: x + w / 3, y: y, width: 2 * w / 3, height: h)
        case .maximize: return visible
        case .center:
            let size = current?.size ?? CGSize(width: w / 2, height: h / 2)
            return centered(size: size, in: visible)
        case .restore, .nextDisplay, .previousDisplay: return nil
        }
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
