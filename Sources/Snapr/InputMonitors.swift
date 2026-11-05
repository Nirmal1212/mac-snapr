import AppKit
import Combine
import SnaprCore

/// Moves the cursor with Quartz (same global top-left space as Accessibility frames).
final class SystemCursorProvider: CursorProvider {
    func move(to point: CGPoint) { CGWarpMouseCursorPosition(point) }
}

/// Middle/extra mouse-button shortcuts. Uses its own *active* tap because matched button events are
/// consumed; unmatched events and all other buttons pass through untouched. Window lookups and the
/// action itself run asynchronously, never inside the tap callback.
final class MouseButtonMonitor {
    private let windows: WindowProvider
    private let controller: SnapController
    private var shortcuts: [MouseShortcut] = []
    private var consumed: Set<Int> = []

    private lazy var tap = EventTap(
        types: [.otherMouseDown, .otherMouseUp, .otherMouseDragged], mode: .active
    ) { [weak self] type, event in self?.handle(type, event) ?? event }

    init(windows: WindowProvider, controller: SnapController) {
        self.windows = windows
        self.controller = controller
    }

    var isRunning: Bool { tap.isRunning }

    /// Runs the tap only while at least one shortcut is configured.
    func update(_ shortcuts: [MouseShortcut], enabled: Bool) {
        self.shortcuts = shortcuts
        if enabled, !shortcuts.isEmpty {
            tap.start()
        } else {
            tap.stop()
            consumed.removeAll()
        }
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> CGEvent? {
        let button = Int(event.getIntegerValueField(.mouseEventButtonNumber))
        switch type {
        case .otherMouseDown:
            guard let match = MouseShortcuts.match(shortcuts, button: button, modifiers: KeyModifiers(event.flags))
            else { return event }
            consumed.insert(button)
            let point = event.location
            DispatchQueue.main.async { [weak self] in self?.run(match, at: point) }
            return nil
        case .otherMouseUp:
            return consumed.remove(button) != nil ? nil : event
        case .otherMouseDragged:
            return consumed.contains(button) ? nil : event
        default:
            return event
        }
    }

    private func run(_ shortcut: MouseShortcut, at point: CGPoint) {
        if shortcut.underPointer {
            guard let window = windows.window(at: point) else { return }
            controller.perform(shortcut.action, on: window)
        } else {
            controller.perform(shortcut.action)
        }
    }
}

/// Double-click a title bar to maximize / restore. Listen-only: the click is never consumed, and the
/// decision uses the frame before the system's own zoom so the two cannot undo each other.
final class TitleBarClickMonitor {
    private let windows: WindowProvider
    private let screens: ScreenProvider
    private let controller: SnapController

    private lazy var tap = EventTap(types: [.leftMouseDown], mode: .listenOnly) { [weak self] _, event in
        if event.getIntegerValueField(.mouseEventClickState) == 2 { self?.doubleClick(at: event.location) }
        return event
    }

    init(windows: WindowProvider, screens: ScreenProvider, controller: SnapController) {
        self.windows = windows
        self.screens = screens
        self.controller = controller
    }

    func update(enabled: Bool) {
        if enabled { tap.start() } else { tap.stop() }
    }

    private func doubleClick(at point: CGPoint) {
        // Hit-test only on double-clicks, outside the tap callback.
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = windows.window(at: point), window.canMove,
                TitleBar.contains(point, in: window.frame),
                let screen = ScreenGeometry.screen(containing: window.frame, in: screens.screens())
            else { return }
            let action = TitleBar.toggleAction(windowFrame: window.frame, visible: screen.visibleFrame)
            let before = window.frame
            // After the system's own title-bar zoom has settled.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [controller, windows] in
                var info = window
                info.frame = windows.currentFrame(of: window.id) ?? window.frame
                controller.perform(action, on: info, screen: screen, restoreFrame: before)
            }
        }
    }
}

/// Keeps a window drag one point below the top screen edge so it cannot trigger Mission Control.
/// Own *active* tap on drag events only; created only while the option is on. The handler does
/// arithmetic on cached geometry and nothing else.
final class DragEdgeGuard {
    private struct Line { var minX: CGFloat; var maxX: CGFloat; var y: CGFloat }
    private let screens: ScreenProvider
    private var lines: [Line] = []
    private var observer: NSObjectProtocol?

    private lazy var tap = EventTap(types: [.leftMouseDragged], mode: .active) { [weak self] _, event in
        guard let self else { return event }
        let p = event.location
        if lines.contains(where: { p.x >= $0.minX && p.x < $0.maxX && p.y < $0.y + 1 }) {
            let line = lines.first { p.x >= $0.minX && p.x < $0.maxX }
            event.location = CGPoint(x: p.x, y: (line?.y ?? p.y) + 1)
        }
        return event
    }

    init(screens: ScreenProvider) { self.screens = screens }

    func update(enabled: Bool) {
        if enabled {
            refreshGeometry()
            if observer == nil {
                observer = NotificationCenter.default.addObserver(
                    forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
                ) { [weak self] _ in self?.refreshGeometry() }
            }
            tap.start()
        } else {
            tap.stop()
            observer.map(NotificationCenter.default.removeObserver)
            observer = nil
        }
    }

    /// Top edges that no other display sits above (shared edges between stacked displays stay crossable).
    private func refreshGeometry() {
        let frames = screens.screens().map(\.frame)
        lines = frames.compactMap { frame in
            let above = frames.contains { other in
                other != frame && other.minX < frame.maxX && other.maxX > frame.minX && other.maxY <= frame.minY + 1
            }
            return above ? nil : Line(minX: frame.minX, maxX: frame.maxX, y: frame.minY)
        }
    }
}

/// Owns the input extras and keeps them in sync with settings. Each consuming feature has its own
/// tap, created only while its setting needs it.
final class InputCoordinator {
    private let settings: SettingsStore
    private let provider: AXWindowProvider
    private let controller: SnapController
    private let overlay: PreviewOverlay
    private let mouse: MouseButtonMonitor
    private let titleBar: TitleBarClickMonitor
    private let edgeGuard: DragEdgeGuard
    private var running = false
    private var subscription: AnyCancellable?

    init(
        settings: SettingsStore, windows: AXWindowProvider, screens: ScreenProvider,
        controller: SnapController, overlay: PreviewOverlay
    ) {
        self.settings = settings
        self.provider = windows
        self.controller = controller
        self.overlay = overlay
        mouse = MouseButtonMonitor(windows: windows, controller: controller)
        titleBar = TitleBarClickMonitor(windows: windows, screens: screens, controller: controller)
        edgeGuard = DragEdgeGuard(screens: screens)
        controller.cursor = SystemCursorProvider()
        subscription = settings.changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.apply() }
        apply()
    }

    /// Starts the taps that settings call for (idempotent).
    func start() {
        running = true
        apply()
    }

    func stop() {
        running = false
        apply()
    }

    private func apply() {
        let options = settings.get(.dragSnapOptions)
        controller.displayRules = settings.get(.displayRules)
        overlay.apply(options.footprint)
        provider.animationDuration = options.animate ? 0.12 : 0
        mouse.update(settings.get(.mouseShortcuts), enabled: running)
        titleBar.update(enabled: running && settings.get(.titleBarDoubleClick))
        edgeGuard.update(enabled: running && options.preventMissionControl && settings.get(.dragSnapEnabled))
    }
}
