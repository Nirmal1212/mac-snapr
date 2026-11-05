import CoreGraphics

/// Edge/corner hit zones for drag snapping (pure, unit tested).
public enum DragZone: Equatable {
    case left, right, top
    case topLeft, topRight, bottomLeft, bottomRight

    public var action: SnapAction {
        switch self {
        case .left: return .leftHalf
        case .right: return .rightHalf
        case .top: return .maximize
        case .topLeft: return .topLeftQuarter
        case .topRight: return .topRightQuarter
        case .bottomLeft: return .bottomLeftQuarter
        case .bottomRight: return .bottomRightQuarter
        }
    }
}

public enum DragZones {
    /// Distance from a screen edge at which the cursor counts as "at the edge".
    public static let edgeThreshold: CGFloat = 5
    /// Length along an edge, measured from a corner, that counts as the corner zone.
    public static let cornerSize: CGFloat = 60

    /// The zone for a cursor position within a screen's full frame, or nil.
    public static func zone(
        at point: CGPoint, in frame: CGRect,
        edgeThreshold: CGFloat = DragZones.edgeThreshold, cornerSize: CGFloat = DragZones.cornerSize
    ) -> DragZone? {
        guard frame.insetBy(dx: -1, dy: -1).contains(point) else { return nil }
        let nearLeft = point.x <= frame.minX + edgeThreshold
        let nearRight = point.x >= frame.maxX - edgeThreshold
        let nearTop = point.y <= frame.minY + edgeThreshold
        let nearBottom = point.y >= frame.maxY - edgeThreshold

        let inLeftCorner = point.x <= frame.minX + cornerSize
        let inRightCorner = point.x >= frame.maxX - cornerSize
        let inTopCorner = point.y <= frame.minY + cornerSize
        let inBottomCorner = point.y >= frame.maxY - cornerSize

        if (nearLeft && inTopCorner) || (nearTop && inLeftCorner) { return .topLeft }
        if (nearRight && inTopCorner) || (nearTop && inRightCorner) { return .topRight }
        if (nearLeft && inBottomCorner) || (nearBottom && inLeftCorner) { return .bottomLeft }
        if (nearRight && inBottomCorner) || (nearBottom && inRightCorner) { return .bottomRight }
        if nearLeft { return .left }
        if nearRight { return .right }
        if nearTop { return .top }
        return nil
    }

    /// Zone for a point across all screens, together with its target frame (nil when drag snap is off).
    public static func target(
        at point: CGPoint, screens: [ScreenInfo], enabled: Bool, options: LayoutOptions = LayoutOptions()
    ) -> (zone: DragZone, screen: ScreenInfo, frame: CGRect)? {
        guard enabled, let screen = screens.first(where: { $0.frame.contains(point) }),
            let zone = zone(at: point, in: screen.frame),
            let frame = LayoutEngine.target(
                for: zone.action, on: screen, isPrimary: LayoutEngine.isPrimary(screen, in: screens), options: options)
        else { return nil }
        return (zone, screen, frame)
    }
}
