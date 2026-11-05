import CoreGraphics
import Foundation

/// Executes runtime actions (custom zones, saved layouts, Space moves) against the live window state.
/// Frames are applied through `SnapController.snap(_:toFrame:screen:)`, so Restore keeps working.
public final class RuntimeActionRunner: RuntimeActionPerforming {
    private let store: CustomLayoutStore
    private let controller: SnapController
    private let windows: WindowProvider
    private let screens: ScreenProvider
    private let lister: WindowLister?
    private let spaces: SpaceActionController?
    private let optionsProvider: () -> LayoutOptions

    public init(
        store: CustomLayoutStore, controller: SnapController, windows: WindowProvider, screens: ScreenProvider,
        lister: WindowLister? = nil, spaces: SpaceActionController? = nil,
        options: @escaping () -> LayoutOptions = { LayoutOptions() }
    ) {
        self.store = store
        self.controller = controller
        self.windows = windows
        self.screens = screens
        self.lister = lister
        self.spaces = spaces
        self.optionsProvider = options
    }

    public func exists(_ action: RuntimeAction) -> Bool {
        switch action {
        case .zone(let id): return store.zone(id: id) != nil
        case .layout(let id): return store.layout(id: id) != nil
        case .space: return spaces?.isActive ?? false
        }
    }

    @discardableResult
    public func perform(_ action: RuntimeAction) -> Bool {
        switch action {
        case .zone(let id):
            guard let zone = store.zone(id: id) else { return false }
            return place(zone)
        case .layout(let id):
            guard let layout = store.layout(id: id) else { return false }
            return apply(layout)
        case .space(let target):
            if case .moved = spaces?.perform(target) { return true }
            return false
        }
    }

    // MARK: Zones

    /// The area zones are laid out in: the usable area (notch and screen gaps) for any screen.
    static func area(for screen: ScreenInfo, all: [ScreenInfo], options: LayoutOptions) -> (area: CGRect, gapsApply: Bool) {
        var gaps = options.gaps
        gaps.exemptActions = []
        let primary = LayoutEngine.isPrimary(screen, in: all)
        let applies = LayoutEngine.gapsApply(to: .center, isPrimary: primary, options: gaps)
        return (LayoutEngine.area(for: screen, action: .center, isPrimary: primary, options: gaps), applies)
    }

    /// Final frame for `rect` on `screen`, with the same gap rules as built-in layouts.
    public static func frame(for rect: FractionRect, on screen: ScreenInfo, all: [ScreenInfo], options: LayoutOptions) -> CGRect {
        let (area, applies) = area(for: screen, all: all, options: options)
        let frame = rect.frame(in: area)
        guard applies else { return LayoutEngine.pixelAligned(frame) }
        return LayoutEngine.pixelAligned(LayoutEngine.applyWindowGap(frame, in: area, gap: options.gaps.windowGap))
    }

    private func place(_ zone: CustomZone) -> Bool {
        guard let window = windows.focusedWindow() else { return false }
        let all = screens.screens()
        guard let screen = ScreenGeometry.screen(containing: window.frame, in: all) else { return false }
        let target = Self.frame(for: zone.rect, on: screen, all: all, options: optionsProvider())
        return controller.snap(window, toFrame: target, screen: screen)
    }

    // MARK: Saved layouts

    /// Captures the currently open windows as a layout entry list.
    public func captureEntries() -> [LayoutEntry] {
        ArrangementPlanner.capture(windows: lister?.listWindows() ?? [], screens: screens.screens())
    }

    private func apply(_ layout: SavedLayout) -> Bool {
        guard let lister else { return false }
        let plan = ArrangementPlanner.plan(layout: layout, windows: lister.listWindows(), screens: screens.screens())
        // Place every window (no short-circuit); report whether any moved.
        let results = plan.map { controller.snap($0.window.info, toFrame: $0.frame, screen: $0.screen) }
        return results.contains(true)
    }
}
