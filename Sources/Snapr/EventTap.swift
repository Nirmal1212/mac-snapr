import AppKit
import SnaprCore

/// Thin wrapper over a `CGEventTap` on the main run loop. Each feature owns its own tap so a
/// consuming (active) tap never carries more than it needs to.
final class EventTap {
    enum Mode {
        /// Observes events only; the handler's return value is ignored.
        case listenOnly
        /// May modify an event or consume it by returning nil. Keep the handler fast.
        case active
    }

    /// Return the (possibly modified) event to deliver it, or nil to consume it (active taps only).
    typealias Handler = (CGEventType, CGEvent) -> CGEvent?

    private let types: [CGEventType]
    private let mode: Mode
    private let handler: Handler
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    init(types: [CGEventType], mode: Mode, handler: @escaping Handler) {
        self.types = types
        self.mode = mode
        self.handler = handler
    }

    deinit { stop() }

    var isRunning: Bool { tap != nil }

    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            return Unmanaged<EventTap>.fromOpaque(refcon).takeUnretainedValue().dispatch(type, event)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: mode == .listenOnly ? .listenOnly : .defaultTap,
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
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        source = nil
        tap = nil
    }

    private func dispatch(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        guard let result = handler(type, event) else {
            return mode == .active ? nil : Unmanaged.passUnretained(event)
        }
        return Unmanaged.passUnretained(result)
    }
}

extension KeyModifiers {
    /// Modifier keys held according to CGEvent flags.
    init(_ flags: CGEventFlags) {
        var result: KeyModifiers = []
        if flags.contains(.maskCommand) { result.insert(.command) }
        if flags.contains(.maskShift) { result.insert(.shift) }
        if flags.contains(.maskAlternate) { result.insert(.option) }
        if flags.contains(.maskControl) { result.insert(.control) }
        self = result
    }
}
