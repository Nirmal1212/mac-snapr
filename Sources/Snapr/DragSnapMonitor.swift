import AppKit
import SnaprCore

/// Listen-only CGEventTap that detects window drags to screen edges and snaps on release.
final class DragSnapMonitor {
    private let windows: WindowProvider
    private let screens: ScreenProvider
    private let controller: SnapController
    private let settings: SettingsStore
    private let overlay: PreviewOverlay

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

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

    var isRunning: Bool { tap != nil }

    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }
        let mask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            Unmanaged<DragSnapMonitor>.fromOpaque(refcon).takeUnretainedValue().handle(type, event)
            return Unmanaged.passUnretained(event)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
            eventsOfInterest: mask, callback: callback, userInfo: Unmanaged.passUnretained(self).toOpaque())
        else { return false }
        self.tap = tap
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        source = nil
        tap = nil
        reset()
    }

    private func reset() {
        tracked = nil
        confirmedDrag = false
        activeTarget = nil
        overlay.hide()
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        case .leftMouseDown:
            reset()
            guard settings.get(.dragSnapEnabled), let window = windows.window(at: event.location) else { return }
            tracked = window
            startFrame = window.frame
        case .leftMouseDragged:
            guard let window = tracked, settings.get(.dragSnapEnabled) else { return }
            drag(window, at: event.location)
        case .leftMouseUp:
            finish()
        default:
            break
        }
    }

    private func drag(_ window: WindowInfo, at point: CGPoint) {
        let target = DragZones.target(at: point, screens: screens.screens(), enabled: true)
        guard let target else {
            activeTarget = nil
            overlay.hide()
            return
        }
        if !confirmedDrag {
            // Only a moved (not resized) window counts as a window drag; checked lazily near edges.
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

    private func finish() {
        defer { reset() }
        guard confirmedDrag, let window = tracked, let target = activeTarget else { return }
        let original = startFrame
        // Let the system finish its own drag-release move before we place the window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [controller, windows] in
            var info = window
            info.frame = windows.currentFrame(of: window.id) ?? window.frame
            controller.perform(target.zone.action, on: info, screen: target.screen, restoreFrame: original)
        }
    }
}
