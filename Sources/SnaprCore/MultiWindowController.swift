import CoreGraphics

/// Executes the multi-window actions (tile, cascade, stack, reverse, Todo) through injected providers.
/// Pure frame math lives in `MultiWindowPlanner` and `ReservedAreas`.
public final class MultiWindowController {
    private struct Context {
        var windows: [ManagedWindow]
        var active: ScreenInfo
        var screens: [ScreenInfo]
        var options: MultiWindowOptions
        var layout: LayoutOptions
        var stageManager: Bool
    }

    private let list: WindowListProvider
    private let windows: WindowProvider
    private let screens: ScreenProvider
    private let layoutOptions: () -> LayoutOptions
    private let multiOptions: () -> MultiWindowOptions
    private let saveOptions: (MultiWindowOptions) -> Void
    private let stageManagerActive: () -> Bool
    private var stackOrder: [WindowID] = []
    private var stackPosition = 0

    /// Called after stack cycling with the 1-based position, the stack size and the front window's frame.
    public var onStackChanged: ((_ index: Int, _ count: Int, _ frame: CGRect) -> Void)?

    /// - Parameter screens: the real screens (not the reserved-area decorated ones); reserved areas are
    ///   applied here.
    public init(
        list: WindowListProvider, windows: WindowProvider, screens: ScreenProvider,
        layoutOptions: @escaping () -> LayoutOptions = { LayoutOptions() },
        options: @escaping () -> MultiWindowOptions = { MultiWindowOptions() },
        saveOptions: @escaping (MultiWindowOptions) -> Void = { _ in },
        stageManagerActive: @escaping () -> Bool = { false }
    ) {
        self.list = list
        self.windows = windows
        self.screens = screens
        self.layoutOptions = layoutOptions
        self.multiOptions = options
        self.saveOptions = saveOptions
        self.stageManagerActive = stageManagerActive
    }

    /// Performs a multi-window action. Returns true if any window changed.
    @discardableResult
    public func perform(_ action: SnapAction) -> Bool {
        switch action {
        case .tileAll, .tileRows, .tileColumns, .cascadeAll: return arrange(action, activeAppOnly: false)
        case .tileActiveApp: return arrange(action, activeAppOnly: true)
        case .cascadeActiveApp: return arrange(action, activeAppOnly: true)
        case .reverseAll: return reverseAll()
        case .stackNext: return cycleStack(forward: true)
        case .stackPrevious: return cycleStack(forward: false)
        case .toggleTodo: return toggleTodo()
        case .reflowTodo: return reflowTodo()
        default: return false
        }
    }

    // MARK: Context and areas

    private func context(activeAppOnly: Bool = false) -> Context? {
        let all = list.allWindows().filter(\.canMove)
        let screens = screens.screens()
        guard let first = all.first, let active = ScreenGeometry.screen(containing: first.frame, in: screens)
        else { return nil }
        return Context(
            windows: activeAppOnly ? all.filter(\.isActiveApp) : all, active: active, screens: screens,
            options: multiOptions(), layout: layoutOptions(), stageManager: stageManagerActive())
    }

    private func isTodo(_ window: ManagedWindow, _ context: Context) -> Bool {
        let todo = context.options.todo
        return todo.enabled && todo.bundleID != nil && window.bundleID == todo.bundleID
    }

    /// Content area (gaps and reserved areas applied) and Todo sidebar of `screen` for `action`.
    private func areas(_ screen: ScreenInfo, _ action: SnapAction, _ context: Context) -> (content: CGRect, todo: CGRect?, gap: CGFloat) {
        let primary = LayoutEngine.isPrimary(screen, in: context.screens)
        let base = LayoutEngine.area(for: screen, action: action, isPrimary: primary, options: context.layout.gaps)
        let todoID = ReservedAreas.todoScreen(in: context.screens, options: context.options)?.id
        var parts = ReservedAreas.layout(
            base, isTodoScreen: screen.id == todoID, options: context.options, stageManagerActive: context.stageManager)
        let gap = LayoutEngine.gapsApply(to: action, isPrimary: primary, options: context.layout.gaps)
            ? context.layout.gaps.windowGap : 0
        if let todo = parts.todo, gap > 0 {
            // Keep the window gap between the sidebar and the content.
            let side = context.options.todo.side
            parts.content = ReservedAreas.split(parts.content, width: gap / 2, side: side == .left ? .left : .right).rest
            parts.todo = ReservedAreas.split(todo, width: gap / 2, side: side == .left ? .right : .left).rest
        }
        return (parts.content, parts.todo, gap)
    }

    // MARK: Apply

    @discardableResult
    private func place(_ window: ManagedWindow, _ frame: CGRect, bounds: CGRect) -> Bool {
        var target = frame
        if !window.canResize {
            target = WindowGeometry.clamped(CGRect(origin: frame.origin, size: window.frame.size), to: bounds)
        }
        guard let result = windows.setFrame(target, for: window.id) else { return false }
        if window.canResize, LayoutEngine.missedTarget(result, target: target) {
            let fixed = WindowGeometry.clamped(LayoutEngine.fit(result, target: target, in: bounds), to: bounds)
            if fixed.size == result.size, !WindowGeometry.approximatelyEqual(fixed, result, tolerance: 1) {
                windows.setFrame(fixed, for: window.id)
            }
        }
        return true
    }

    // MARK: Tile and cascade

    private func arrange(_ action: SnapAction, activeAppOnly: Bool) -> Bool {
        guard let context = context(activeAppOnly: activeAppOnly) else { return false }
        let options = context.options
        let scopeScreens = options.combinedDisplays
            ? ScreenGeometry.ordered(context.screens) : [context.active]
        let scoped = context.windows.filter { window in
            guard let screen = ScreenGeometry.screen(containing: window.frame, in: context.screens) else { return false }
            return scopeScreens.contains { $0.id == screen.id }
        }
        let todoWindows = scoped.filter { isTodo($0, context) }
        let others = scoped.filter { !isTodo($0, context) }

        var changed = false
        var assignments: [(screen: ScreenInfo, windows: [ManagedWindow])] = []
        let areaList = scopeScreens.map { areas($0, action, context) }
        if scopeScreens.count > 1 {
            // Combined mode: windows by horizontal position, shared out in proportion to usable area.
            let ordered = others.sorted { $0.frame.midX < $1.frame.midX }
            let counts = MultiWindowPlanner.distribute(
                count: ordered.count, weights: areaList.map { $0.content.width * $0.content.height })
            var start = 0
            for (index, screen) in scopeScreens.enumerated() {
                assignments.append((screen, Array(ordered[start..<start + counts[index]])))
                start += counts[index]
            }
        } else {
            assignments = [(scopeScreens[0], others)]
        }

        for (index, assignment) in assignments.enumerated() {
            let area = areaList[index]
            if let sidebar = area.todo, !todoWindows.isEmpty {
                let frames = MultiWindowPlanner.grid(
                    count: todoWindows.count, columns: 1, in: sidebar, balanced: true, gap: area.gap)
                for (window, frame) in zip(todoWindows, frames) where place(window, frame, bounds: sidebar) {
                    changed = true
                }
            }
            changed = layout(action, assignment.windows, in: area.content, gap: area.gap, options: options) || changed
        }
        return changed
    }

    private func layout(
        _ action: SnapAction, _ group: [ManagedWindow], in area: CGRect, gap: CGFloat, options: MultiWindowOptions
    ) -> Bool {
        guard !group.isEmpty else { return false }
        var changed = false
        switch action {
        case .cascadeAll, .cascadeActiveApp:
            // Back window at the top-left, front window last; raised in that order to keep z-order.
            let ordered = Array(group.reversed())
            let frames = MultiWindowPlanner.cascade(sizes: ordered.map(\.frame.size), in: area, offset: options.cascadeOffset)
            for (window, frame) in zip(ordered, frames) where place(window, frame, bounds: area) {
                changed = true
            }
            ordered.forEach { list.raise($0.id) }
        default:
            let ordered = MultiWindowPlanner.readingOrder(group)
            let frames: [CGRect]
            switch action {
            case .tileRows:
                frames = MultiWindowPlanner.rows(
                    count: ordered.count, perRow: options.maxPerRow, in: area, balanced: options.balancedGrid, gap: gap)
            case .tileColumns:
                frames = MultiWindowPlanner.columns(
                    count: ordered.count, perColumn: options.maxPerColumn, in: area, balanced: options.balancedGrid,
                    gap: gap)
            default:
                let columns = options.maxPerRow > 0
                    ? min(options.maxPerRow, ordered.count)
                    : MultiWindowPlanner.balancedColumns(count: ordered.count, area: area.size)
                frames = MultiWindowPlanner.grid(
                    count: ordered.count, columns: columns, in: area, balanced: options.balancedGrid, gap: gap)
            }
            for (window, frame) in zip(ordered, frames) where place(window, frame, bounds: area) {
                changed = true
            }
        }
        return changed
    }

    // MARK: Reverse

    private func reverseAll() -> Bool {
        guard let context = context() else { return false }
        let scoped = context.windows.filter { window in
            guard !isTodo(window, context) else { return false }
            if context.options.combinedDisplays { return true }
            return ScreenGeometry.screen(containing: window.frame, in: context.screens)?.id == context.active.id
        }
        guard scoped.count > 1 else { return false }
        let byID = Dictionary(uniqueKeysWithValues: scoped.map { ($0.id, $0) })
        var changed = false
        for (id, frame) in MultiWindowPlanner.reversed(scoped) {
            guard let window = byID[id], !WindowGeometry.approximatelyEqual(window.frame, frame) else { continue }
            let bounds = ScreenGeometry.screen(containing: frame, in: context.screens)?.visibleFrame ?? frame
            if place(window, frame, bounds: bounds) { changed = true }
        }
        return changed
    }

    // MARK: Stack

    private func cycleStack(forward: Bool) -> Bool {
        guard let context = context() else { return false }
        let scoped = context.windows.filter {
            !isTodo($0, context)
                && ScreenGeometry.screen(containing: $0.frame, in: context.screens)?.id == context.active.id
        }
        guard scoped.count > 1 else { return false }
        let byID = Dictionary(uniqueKeysWithValues: scoped.map { ($0.id, $0) })
        // Keep our own order while the set of windows is unchanged; otherwise start from front-to-back.
        if Set(stackOrder) != Set(byID.keys) {
            stackOrder = scoped.map(\.id)
            stackPosition = 0
        }
        let count = stackOrder.count
        if forward {
            stackOrder.append(stackOrder.removeFirst())
            stackPosition = (stackPosition + 1) % count
        } else {
            stackOrder.insert(stackOrder.removeLast(), at: 0)
            stackPosition = (stackPosition + count - 1) % count
        }
        let ordered = stackOrder.compactMap { byID[$0] }
        let area = areas(context.active, forward ? .stackNext : .stackPrevious, context).content
        let frames = MultiWindowPlanner.stack(
            sizes: ordered.map(\.frame.size), in: area, offset: context.options.stackOffset,
            sameSize: context.options.stackSameSize)
        var changed = false
        // Back to front so each raise leaves the front window on top.
        for (window, frame) in zip(ordered, frames).reversed() {
            if place(window, frame, bounds: area) { changed = true }
            list.raise(window.id)
        }
        if context.options.showStackBadge, let front = frames.first {
            onStackChanged?(stackPosition + 1, count, front)
        }
        return changed
    }

    // MARK: Todo

    private func toggleTodo() -> Bool {
        var options = multiOptions()
        if options.todo.enabled {
            options.todo.enabled = false
            saveOptions(options)
            return true
        }
        let all = list.allWindows()
        let front = all.first(where: \.isActiveApp) ?? all.first
        if options.todo.bundleID == nil {
            guard let id = front?.bundleID else { return false }
            options.todo.bundleID = id
        }
        let screens = screens.screens()
        if let front, let screen = ScreenGeometry.screen(containing: front.frame, in: screens) {
            options.todo.screenID = screen.id
        }
        options.todo.enabled = true
        saveOptions(options)
        _ = reflowTodo()
        return true
    }

    /// Puts the Todo app's windows into the sidebar and keeps the other windows on that screen out of it.
    private func reflowTodo() -> Bool {
        guard let context = context(), context.options.todo.enabled,
            let screen = ReservedAreas.todoScreen(in: context.screens, options: context.options)
        else { return false }
        let area = areas(screen, .reflowTodo, context)
        guard let sidebar = area.todo else { return false }
        var changed = false
        let todoWindows = context.windows.filter { isTodo($0, context) }
        let frames = MultiWindowPlanner.grid(
            count: todoWindows.count, columns: 1, in: sidebar, balanced: true, gap: area.gap)
        for (window, frame) in zip(todoWindows, frames) where place(window, frame, bounds: sidebar) {
            changed = true
        }
        for window in context.windows where !isTodo(window, context) {
            guard ScreenGeometry.screen(containing: window.frame, in: context.screens)?.id == screen.id else { continue }
            let fitted = MultiWindowPlanner.fitting(window.frame, in: area.content)
            if !WindowGeometry.approximatelyEqual(fitted, window.frame), place(window, fitted, bounds: area.content) {
                changed = true
            }
        }
        return changed
    }
}
