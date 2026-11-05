import CoreGraphics

public struct ScreenInfo: Equatable {
    public var id: Int
    /// Full frame in the global top-left/y-down space.
    public var frame: CGRect
    /// Frame excluding menu bar and Dock, same space.
    public var visibleFrame: CGRect
    /// Height of the camera-housing (notch) safe area at the top; 0 on screens without one.
    public var safeAreaTop: CGFloat

    public init(id: Int, frame: CGRect, visibleFrame: CGRect, safeAreaTop: CGFloat = 0) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.safeAreaTop = safeAreaTop
    }
}

public enum ScreenGeometry {
    /// Screens ordered left to right (then top to bottom) for stable next/previous cycling.
    public static func ordered(_ screens: [ScreenInfo]) -> [ScreenInfo] {
        screens.sorted { ($0.frame.minX, $0.frame.minY) < ($1.frame.minX, $1.frame.minY) }
    }

    /// The screen containing the center of `rect`; falls back to the nearest screen.
    public static func screen(containing rect: CGRect, in screens: [ScreenInfo]) -> ScreenInfo? {
        screen(at: CGPoint(x: rect.midX, y: rect.midY), in: screens)
    }

    public static func screen(at point: CGPoint, in screens: [ScreenInfo]) -> ScreenInfo? {
        if let hit = screens.first(where: { $0.frame.contains(point) }) { return hit }
        return screens.min { distance(from: point, to: $0.frame) < distance(from: point, to: $1.frame) }
    }

    /// Next/previous screen (wrapping). Returns nil with fewer than two screens.
    /// - Parameter byX: order by x coordinate (otherwise keep the system's order).
    public static func neighbor(
        of screen: ScreenInfo, in screens: [ScreenInfo], forward: Bool, byX: Bool = true
    ) -> ScreenInfo? {
        let list = byX ? ordered(screens) : screens
        guard list.count > 1, let index = list.firstIndex(where: { $0.id == screen.id }) else { return nil }
        let next = (index + (forward ? 1 : list.count - 1)) % list.count
        return list[next]
    }

    private static func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return (dx * dx + dy * dy).squareRoot()
    }
}

/// Conversion between Cocoa (bottom-left origin) and Accessibility (top-left origin) rects.
public enum CoordinateSpace {
    /// Flips a rect between the two spaces. The operation is its own inverse.
    /// - Parameter primaryHeight: height of the primary display (`NSScreen.screens[0].frame.height`).
    public static func flip(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    public static func flip(_ point: CGPoint, primaryHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: primaryHeight - point.y)
    }
}
