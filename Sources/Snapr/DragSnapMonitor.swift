import AppKit
import SnaprCore

/// Listen-only event tap that detects window drags to screen zones and snaps on release.
///
/// The window under the pointer is hit-tested lazily: not on every mouse-down, but once per gesture
/// after the pointer has moved past a small slop, so plain clicks never touch the Accessibility API.
final class DragSnapMonitor {
    private static let slop: CGFloat = 4

    private let windows: WindowProvider
    private let screens: ScreenProvider
    private let controller: SnapController
    private let settings: SettingsStore
    private let overlay: PreviewOverlay

    private lazy var tap = EventTap(
        types: [.leftMouseDown, .leftMouseDragged, .leftMouseUp], mode: .listenOnly
    ) { [weak self] type, event in
        self?.handle(type, event)
        return event
    }

    private var options = DragSnapOptions()
    private var downPoint: CGPoint?
    private var hitTested = false
    private var startPoint: CGPoint = .zero
    private var tracked: WindowInfo?
    private var startFrame: CGRect = .zero
    private var confirmedDrag = false
    private var activeTarget: (zone: DragZone, screen: ScreenInfo, frame: CGRect)?

    init(
        windows: WindowProvider, screens: ScreenProvider, controller: SnapController,
        settings: SettingsStore, overlay: PreviewOverlay
    ) {
        self.windows = windows
        self.screens = screens
        self.controller = controller
        self.settings = settings
        self.overlay = overlay
    }

    var isRunning: Bool { tap.isRunning }

    /// True while a window (resolved at mouse-down) is being dragged from its top strip, i.e. a move
    /// rather than a resize or in-content drag. Cheap: reads cached state only.
    var isWindowDrag: Bool {
        guard tracked != nil else { return false }
        return TitleBar.contains(startPoint, in: startFrame, height: 100)
    }

    @discardableResult
    func start() -> Bool { tap.start() }

    func stop() {
        tap.stop()
        reset()
    }

    private func reset() {
        downPoint = nil
        hitTested = false
        tracked = nil
        confirmedDrag = false
        activeTarget = nil
        overlay.hide()
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) {
        switch type {
        case .leftMouseDown:
            reset()
            guard settings.get(.dragSnapEnabled) else { return }
            options = settings.get(.dragSnapOptions)  // once per gesture
            downPoint = event.location
        case .leftMouseDragged:
            guard let down = downPoint, settings.get(.dragSnapEnabled) else { return }
            if !hitTested {
                let here = event.location
                guard hypot(here.x - down.x, here.y - down.y) >= Self.slop else { return }
                hitTested = true
                resolveWindow(downPoint: down, now: here)
            }
            if let window = tracked { drag(window, at: event.location, held: KeyModifiers(event.flags)) }
        case .leftMouseUp:
            finish(held: KeyModifiers(event.flags))
        default:
            break
        }
    }

    /// One AX hit-test per gesture. The window has only just started moving, so its origin at
    /// mouse-down is its current origin minus the pointer travel.
    private func resolveWindow(downPoint: CGPoint, now: CGPoint) {
        guard let window = windows.window(at: downPoint) else { return }
        tracked = window
        startPoint = downPoint
        startFrame = window.frame.offsetBy(dx: downPoint.x - now.x, dy: downPoint.y - now.y)
    }

    private func drag(_ window: WindowInfo, at point: CGPoint, held: KeyModifiers) {
        guard options.modifiersSatisfied(by: held),
            let target = DragZones.target(at: point, screens: screens.screens(), enabled: true, options: options)
        else {
            activeTarget = nil
            overlay.hide()
            return
        }
        if !confirmedDrag {
            // Only a moved (not resized) window counts as a window drag; checked lazily near zones.
            guard let now = windows.currentFrame(of: window.id), isMove(from: startFrame, to: now) else { return }
            confirmedDrag = true
        }
        activeTarget = target
        overlay.show(frame: target.frame)
    }

    private func isMove(from old: CGRect, to new: CGRect) -> Bool {
        let moved = abs(new.minX - old.minX) > 2 || abs(new.minY - old.minY) > 2
        let resized = abs(new.width - old.width) > 2 || abs(new.height - old.height) > 2
        return moved && !resized
    }

    private func finish(held: KeyModifiers) {
        defer { reset() }
        guard settings.get(.dragSnapEnabled), confirmedDrag, options.modifiersSatisfied(by: held),
            let window = tracked, let target = activeTarget
        else { return }
        let original = startFrame
        // Let the system finish its own drag-release move before we place the window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [controller, windows] in
            var info = window
            info.frame = windows.currentFrame(of: window.id) ?? window.frame
            if let action = target.zone.action {
                controller.perform(action, on: info, screen: target.screen, restoreFrame: original)
            } else {
                controller.snap(info, toFrame: target.frame, screen: target.screen, restoreFrame: original)
            }
        }
    }
}
