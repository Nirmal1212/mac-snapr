import CoreGraphics

/// Edge/corner hit zones for drag snapping (pure, unit tested).
public enum DragZone: String, CaseIterable, Codable, Hashable {
    // Core zones.
    case left, right, top
    case topLeft, topRight, bottomLeft, bottomRight
    // Opt-in zones: top/bottom halves beside corners, bottom thirds and two-thirds, corner sixths.
    case topHalf, bottomHalf
    case leftThird, centerThird, rightThird, leftTwoThirds, rightTwoThirds
    case topLeftSixth, topRightSixth, bottomLeftSixth, bottomRightSixth

    /// Zones enabled out of the box (the core drag behavior).
    public static let defaultEnabled: Set<DragZone> = [
        .left, .right, .top, .topLeft, .topRight, .bottomLeft, .bottomRight
    ]

    /// The keyboard action this zone corresponds to, if any (sixths have none).
    public var action: SnapAction? {
        switch self {
        case .left: return .leftHalf
        case .right: return .rightHalf
        case .top: return .maximize
        case .topLeft: return .topLeftQuarter
        case .topRight: return .topRightQuarter
        case .bottomLeft: return .bottomLeftQuarter
        case .bottomRight: return .bottomRightQuarter
        case .topHalf: return .topHalf
        case .bottomHalf: return .bottomHalf
        case .leftThird: return .leftThird
        case .centerThird: return .centerThird
        case .rightThird: return .rightThird
        case .leftTwoThirds: return .leftTwoThirds
        case .rightTwoThirds: return .rightTwoThirds
        case .topLeftSixth, .topRightSixth, .bottomLeftSixth, .bottomRightSixth: return nil
        }
    }

    public var title: String {
        switch self {
        case .left: return "Left half"
        case .right: return "Right half"
        case .top: return "Maximize (top edge)"
        case .topLeft: return "Top left quarter"
        case .topRight: return "Top right quarter"
        case .bottomLeft: return "Bottom left quarter"
        case .bottomRight: return "Bottom right quarter"
        case .topHalf: return "Top half (beside corners)"
        case .bottomHalf: return "Bottom half (beside corners)"
        case .leftThird: return "Left third (bottom edge)"
        case .centerThird: return "Center third (bottom edge)"
        case .rightThird: return "Right third (bottom edge)"
        case .leftTwoThirds: return "Left two thirds (between zones)"
        case .rightTwoThirds: return "Right two thirds (between zones)"
        case .topLeftSixth: return "Top left sixth"
        case .topRightSixth: return "Top right sixth"
        case .bottomLeftSixth: return "Bottom left sixth"
        case .bottomRightSixth: return "Bottom right sixth"
        }
    }

    /// Target frame within a screen's visible frame.
    public func frame(in visible: CGRect) -> CGRect {
        if let action, let frame = WindowGeometry.frame(for: action, in: visible) { return frame }
        let (x, y, w, h) = (visible.minX, visible.minY, visible.width / 3, visible.height / 2)
        switch self {
        case .topLeftSixth: return CGRect(x: x, y: y, width: w, height: h)
        case .topRightSixth: return CGRect(x: visible.maxX - w, y: y, width: w, height: h)
        case .bottomLeftSixth: return CGRect(x: x, y: y + h, width: w, height: h)
        default: return CGRect(x: visible.maxX - w, y: y + h, width: w, height: h)  // bottomRightSixth
        }
    }
}

public enum DragZones {
    /// Distance from a screen edge at which the cursor counts as "at the edge".
    public static let edgeThreshold: CGFloat = 5
    /// Length along an edge, measured from a corner, that counts as the corner zone.
    public static let cornerSize: CGFloat = 60

    /// The zone for a cursor position within a screen's full frame, or nil.
    /// Candidates are tried most specific first; the first enabled one wins.
    public static func zone(
        at point: CGPoint, in frame: CGRect, options: DragSnapOptions = DragSnapOptions()
    ) -> DragZone? {
        guard frame.insetBy(dx: -1, dy: -1).contains(point) else { return nil }
        let edge = CGFloat(options.edgeMargin)
        let corner = CGFloat(options.cornerSize)
        let nearLeft = point.x <= frame.minX + edge
        let nearRight = point.x >= frame.maxX - edge
        let nearTop = point.y <= frame.minY + edge
        let nearBottom = point.y >= frame.maxY - edge

        let inLeftCorner = point.x <= frame.minX + corner
        let inRightCorner = point.x >= frame.maxX - corner
        let inTopCorner = point.y <= frame.minY + corner
        let inBottomCorner = point.y >= frame.maxY - corner

        let candidates: [DragZone]
        if (nearLeft && inTopCorner) || (nearTop && inLeftCorner) {
            candidates = [.topLeftSixth, .topLeft]
        } else if (nearRight && inTopCorner) || (nearTop && inRightCorner) {
            candidates = [.topRightSixth, .topRight]
        } else if (nearLeft && inBottomCorner) || (nearBottom && inLeftCorner) {
            candidates = [.bottomLeftSixth, .bottomLeft]
        } else if (nearRight && inBottomCorner) || (nearBottom && inRightCorner) {
            candidates = [.bottomRightSixth, .bottomRight]
        } else if nearLeft {
            candidates = [.left]
        } else if nearRight {
            candidates = [.right]
        } else if nearTop {
            let beside = besideCorner(point.x, frame, corner)
            candidates = beside ? [.topHalf, .top] : [.top]
        } else if nearBottom {
            candidates = bottomEdge(point.x, frame, corner)
        } else {
            candidates = []
        }
        return candidates.first { options.enabledZones.contains($0) }
    }

    /// Strip of one corner-size next to each corner along an edge.
    private static func besideCorner(_ x: CGFloat, _ frame: CGRect, _ corner: CGFloat) -> Bool {
        (x > frame.minX + corner && x <= frame.minX + 2 * corner)
            || (x < frame.maxX - corner && x >= frame.maxX - 2 * corner)
    }

    private static func bottomEdge(_ x: CGFloat, _ frame: CGRect, _ corner: CGFloat) -> [DragZone] {
        let third = frame.width / 3
        let boundary = corner / 2
        var result: [DragZone] = []
        if abs(x - (frame.minX + third)) <= boundary { result.append(.leftTwoThirds) }
        if abs(x - (frame.minX + 2 * third)) <= boundary { result.append(.rightTwoThirds) }
        if x < frame.minX + third {
            result.append(.leftThird)
        } else if x < frame.minX + 2 * third {
            result.append(.centerThird)
        } else {
            result.append(.rightThird)
        }
        if besideCorner(x, frame, corner) { result.append(.bottomHalf) }
        return result
    }

    /// Zone for a point across all screens, together with its target frame (nil when drag snap is off).
    public static func target(
        at point: CGPoint, screens: [ScreenInfo], enabled: Bool, options: DragSnapOptions = DragSnapOptions(),
        layout: LayoutOptions = LayoutOptions()
    ) -> (zone: DragZone, screen: ScreenInfo, frame: CGRect)? {
        guard enabled, let screen = screens.first(where: { $0.frame.contains(point) }),
            let zone = zone(at: point, in: screen.frame, options: options)
        else { return nil }
        // Snap actions go through the layout engine so the preview matches the gap-aware result.
        if let action = zone.action,
            let frame = LayoutEngine.target(
                for: action, on: screen, isPrimary: LayoutEngine.isPrimary(screen, in: screens), options: layout) {
            return (zone, screen, frame)
        }
        return (zone, screen, zone.frame(in: screen.visibleFrame))
    }
}
