import CoreGraphics

/// Pure rules for screen regions that layouts must avoid: the Stage Manager strip and the Todo sidebar.
public enum ReservedAreas {
    /// A reserved side width is ignored when it would take half the area or more.
    static func usable(_ width: CGFloat, in rect: CGRect) -> Bool { width > 0 && width < rect.width / 2 }

    /// Splits `width` off one side. Returns the reserved strip and the remainder.
    public static func split(_ rect: CGRect, width: CGFloat, side: ScreenSide) -> (strip: CGRect, rest: CGRect) {
        switch side {
        case .left:
            return (
                CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height),
                CGRect(x: rect.minX + width, y: rect.minY, width: rect.width - width, height: rect.height))
        case .right:
            return (
                CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height),
                CGRect(x: rect.minX, y: rect.minY, width: rect.width - width, height: rect.height))
        }
    }

    /// The screen that holds the Todo sidebar: the configured one, else the primary screen.
    public static func todoScreen(in screens: [ScreenInfo], options: MultiWindowOptions) -> ScreenInfo? {
        if let id = options.todo.screenID, let found = screens.first(where: { $0.id == id }) { return found }
        return screens.first { LayoutEngine.isPrimary($0, in: screens) }
    }

    /// Removes the Stage Manager strip (when active) from `rect`.
    public static func withoutStageManager(
        _ rect: CGRect, options: MultiWindowOptions, stageManagerActive: Bool
    ) -> CGRect {
        let stage = options.stageManager
        guard stageManagerActive, stage.enabled, usable(stage.stripWidth, in: rect) else { return rect }
        return split(rect, width: stage.stripWidth, side: stage.side).rest
    }

    /// Splits `rect` (a screen's usable area) into the content area and, on the Todo screen with Todo
    /// mode on, the sidebar. The Stage Manager strip is always removed first.
    public static func layout(
        _ rect: CGRect, isTodoScreen: Bool, options: MultiWindowOptions, stageManagerActive: Bool
    ) -> (content: CGRect, todo: CGRect?) {
        let base = withoutStageManager(rect, options: options, stageManagerActive: stageManagerActive)
        let todo = options.todo
        guard isTodoScreen, todo.enabled, usable(todo.sidebarWidth, in: base) else { return (base, nil) }
        let parts = split(base, width: todo.sidebarWidth, side: todo.side)
        return (parts.rest, parts.strip)
    }
}

/// Decorates a `ScreenProvider` so every layout avoids the reserved areas: `visibleFrame` shrinks by the
/// Stage Manager strip and (on the Todo screen) the Todo sidebar.
public final class ReservedScreenProvider: ScreenProvider {
    private let base: ScreenProvider
    private let options: () -> MultiWindowOptions
    private let stageManagerActive: () -> Bool

    public init(
        base: ScreenProvider, options: @escaping () -> MultiWindowOptions,
        stageManagerActive: @escaping () -> Bool = { false }
    ) {
        self.base = base
        self.options = options
        self.stageManagerActive = stageManagerActive
    }

    public func screens() -> [ScreenInfo] {
        let raw = base.screens()
        let options = options()
        let active = stageManagerActive()
        let todoID = ReservedAreas.todoScreen(in: raw, options: options)?.id
        return raw.map { screen in
            var copy = screen
            copy.visibleFrame = ReservedAreas.layout(
                screen.visibleFrame, isTodoScreen: screen.id == todoID, options: options,
                stageManagerActive: active
            ).content
            return copy
        }
    }
}
