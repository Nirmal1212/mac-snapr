import CoreGraphics

/// Pure rules around the raw geometry: usable area, gaps, fit handling and unsnap.
public enum LayoutEngine {
    // MARK: Usable area and gaps

    /// The primary screen is the one whose frame origin is the global origin (falls back to the first).
    public static func isPrimary(_ screen: ScreenInfo, in screens: [ScreenInfo]) -> Bool {
        if let primary = screens.first(where: { $0.frame.origin == .zero }) { return primary.id == screen.id }
        return screens.first?.id == screen.id
    }

    /// Whether gaps (screen and window) apply to `action` on a screen.
    public static func gapsApply(to action: SnapAction, isPrimary: Bool, options: GapOptions) -> Bool {
        if options.mainScreenOnly && !isPrimary { return false }
        return !options.isExempt(action)
    }

    /// Visible frame reduced by notch avoidance and screen gaps (when they apply to `action`).
    public static func area(for screen: ScreenInfo, action: SnapAction, isPrimary: Bool, options: GapOptions) -> CGRect {
        guard gapsApply(to: action, isPrimary: isPrimary, options: options) else { return screen.visibleFrame }
        var rect = screen.visibleFrame
        let menuBarHidden = rect.minY - screen.frame.minY < 1
        var topGap = options.screenGaps.top
        if options.fullHeightWhenMenuBarHidden && menuBarHidden && screen.safeAreaTop == 0 { topGap = 0 }
        if options.notchAwareTopGap && screen.safeAreaTop > 0 {
            let limit = screen.frame.minY + screen.safeAreaTop
            if rect.minY < limit {
                rect = CGRect(x: rect.minX, y: limit, width: rect.width, height: rect.maxY - limit)
            }
        }
        let gaps = options.screenGaps
        let inset = CGRect(
            x: rect.minX + gaps.left, y: rect.minY + topGap,
            width: rect.width - gaps.left - gaps.right, height: rect.height - topGap - gaps.bottom)
        return inset.width > 0 && inset.height > 0 ? inset : rect
    }

    /// Shrinks `frame` by half the gap on each side that does not lie on the `area` edge, so two
    /// neighbouring windows end up exactly `gap` apart.
    public static func applyWindowGap(_ frame: CGRect, in area: CGRect, gap: CGFloat) -> CGRect {
        guard gap > 0 else { return frame }
        let half = gap / 2
        let tolerance: CGFloat = 0.5
        let left = abs(frame.minX - area.minX) <= tolerance ? 0 : half
        let right = abs(frame.maxX - area.maxX) <= tolerance ? 0 : half
        let top = abs(frame.minY - area.minY) <= tolerance ? 0 : half
        let bottom = abs(frame.maxY - area.maxY) <= tolerance ? 0 : half
        let result = CGRect(
            x: frame.minX + left, y: frame.minY + top,
            width: frame.width - left - right, height: frame.height - top - bottom)
        return result.width > 0 && result.height > 0 ? result : frame
    }

    /// Final target frame for `action` on `screen`: usable area → geometry → window gap.
    public static func target(
        for action: SnapAction, on screen: ScreenInfo, isPrimary: Bool = true, current: CGRect? = nil,
        step: Int = 0, options: LayoutOptions = LayoutOptions()
    ) -> CGRect? {
        let area = area(for: screen, action: action, isPrimary: isPrimary, options: options.gaps)
        guard let frame = WindowGeometry.frame(for: action, in: area, current: current, step: step, options: options)
        else { return nil }
        guard LayoutCatalog.usesWindowGap(action),
            gapsApply(to: action, isPrimary: isPrimary, options: options.gaps)
        else { return frame }
        return applyWindowGap(frame, in: area, gap: options.gaps.windowGap)
    }

    // MARK: Fit handling

    /// Whether the window ended up larger than the target (minimum size, fixed size).
    public static func missedTarget(_ actual: CGRect, target: CGRect, tolerance: CGFloat = 1) -> Bool {
        actual.width > target.width + tolerance || actual.height > target.height + tolerance
    }

    /// Positions a window that could not reach `target`'s size: it is aligned to the edge or corner of
    /// `area` that the target touches (centered on the target otherwise), then kept inside `area`.
    public static func fit(_ actual: CGRect, target: CGRect, in area: CGRect) -> CGRect {
        guard missedTarget(actual, target: target) else { return actual }
        let tolerance: CGFloat = 1
        func anchor(
            _ lower: CGFloat, _ upper: CGFloat, targetLower: CGFloat, targetUpper: CGFloat, length: CGFloat
        ) -> CGFloat {
            let touchesLower = targetLower <= lower + tolerance
            let touchesUpper = targetUpper >= upper - tolerance
            if touchesLower && !touchesUpper { return targetLower }
            if touchesUpper && !touchesLower { return targetUpper - length }
            return (targetLower + targetUpper) / 2 - length / 2
        }
        let x = anchor(area.minX, area.maxX, targetLower: target.minX, targetUpper: target.maxX, length: actual.width)
        let y = anchor(area.minY, area.maxY, targetLower: target.minY, targetUpper: target.maxY, length: actual.height)
        return WindowGeometry.clamped(CGRect(x: x, y: y, width: actual.width, height: actual.height), to: area)
    }

    // MARK: Unsnap

    /// Frame for a window dragged out of a snap: `restoreSize` with the cursor keeping its relative
    /// horizontal position (and vertical offset from the top) inside the window.
    public static func unsnapped(current: CGRect, restoreSize: CGSize, cursor: CGPoint) -> CGRect {
        let fx = current.width > 0 ? min(max((cursor.x - current.minX) / current.width, 0), 1) : 0.5
        let dy = min(max(cursor.y - current.minY, 0), restoreSize.height)
        return CGRect(
            x: cursor.x - restoreSize.width * fx, y: cursor.y - dy,
            width: restoreSize.width, height: restoreSize.height)
    }
}
