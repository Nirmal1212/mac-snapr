import AppKit
import ApplicationServices
import SnaprCore

/// `NSScreen`-backed screens, converted to the global top-left/y-down space.
final class SystemScreenProvider: ScreenProvider {
    func screens() -> [ScreenInfo] {
        let all = NSScreen.screens
        guard let primary = all.first else { return [] }
        let height = primary.frame.height
        return all.enumerated().map { index, screen in
            let number = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.intValue
            return ScreenInfo(
                id: number ?? index,
                frame: CoordinateSpace.flip(screen.frame, primaryHeight: height),
                visibleFrame: CoordinateSpace.flip(screen.visibleFrame, primaryHeight: height),
                safeAreaTop: screen.safeAreaInsets.top)
        }
    }

    static var primaryHeight: CGFloat { NSScreen.screens.first?.frame.height ?? 0 }
}

/// Accessibility-API-backed windows of the frontmost app other than Snapr.
final class AXWindowProvider: WindowProvider {
    private var elements: [WindowID: AXUIElement] = [:]
    private var lastExternalPID: pid_t?
    private var token: NSObjectProtocol?

    init() {
        if let app = NSWorkspace.shared.frontmostApplication, !Self.isSelf(app) {
            lastExternalPID = app.processIdentifier
        }
        token = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                !Self.isSelf(app)
            else { return }
            self?.lastExternalPID = app.processIdentifier
        }
    }

    deinit { token.map(NSWorkspace.shared.notificationCenter.removeObserver) }

    private static func isSelf(_ app: NSRunningApplication) -> Bool {
        app.processIdentifier == ProcessInfo.processInfo.processIdentifier
    }

    func focusedWindow() -> WindowInfo? {
        guard AXIsProcessTrusted(), let pid = lastExternalPID else { return nil }
        let app = AXUIElementCreateApplication(pid)
        guard let element = Self.element(app, kAXFocusedWindowAttribute) ?? Self.element(app, kAXMainWindowAttribute)
        else { return nil }
        return info(for: element)
    }

    func window(at point: CGPoint) -> WindowInfo? {
        guard AXIsProcessTrusted() else { return nil }
        var hit: AXUIElement?
        let status = AXUIElementCopyElementAtPosition(
            AXUIElementCreateSystemWide(), Float(point.x), Float(point.y), &hit)
        guard status == .success, let hit else { return nil }
        var pid: pid_t = 0
        if AXUIElementGetPid(hit, &pid) == .success, pid == ProcessInfo.processInfo.processIdentifier { return nil }
        let role = Self.string(hit, kAXRoleAttribute)
        let window = role == kAXWindowRole as String ? hit : Self.element(hit, kAXWindowAttribute)
        return window.flatMap(info(for:))
    }

    func currentFrame(of id: WindowID) -> CGRect? {
        elements[id].flatMap(Self.frame(of:))
    }

    @discardableResult
    func setFrame(_ frame: CGRect, for id: WindowID) -> CGRect? {
        guard let element = elements[id] else { return nil }
        // Size, position, size: the first resize may be clamped by the old display, the last settles it.
        Self.set(element, kAXSizeAttribute, size: frame.size)
        Self.set(element, kAXPositionAttribute, point: frame.origin)
        Self.set(element, kAXSizeAttribute, size: frame.size)
        return Self.frame(of: element)
    }

    // MARK: - Helpers

    private func info(for element: AXUIElement) -> WindowInfo? {
        guard let frame = Self.frame(of: element) else { return nil }
        // Full-screen windows live in their own Space and are not supported.
        if Self.bool(element, "AXFullScreen") == true { return nil }
        let id = WindowID(Int(truncatingIfNeeded: CFHash(element)))
        elements[id] = element
        return WindowInfo(
            id: id, frame: frame,
            canMove: Self.isSettable(element, kAXPositionAttribute),
            canResize: Self.isSettable(element, kAXSizeAttribute))
    }

    private static func element(_ parent: AXUIElement, _ attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(parent, attribute as CFString, &value) == .success,
            let value, CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return (value as! AXUIElement)  // swiftlint:disable:this force_cast
    }

    private static func string(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? String
    }

    private static func bool(_ element: AXUIElement, _ attribute: String) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return (value as? NSNumber)?.boolValue
    }

    private static func isSettable(_ element: AXUIElement, _ attribute: String) -> Bool {
        var settable: DarwinBoolean = false
        return AXUIElementIsAttributeSettable(element, attribute as CFString, &settable) == .success && settable.boolValue
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef) == .success,
            AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success,
            let posRef, let sizeRef
        else { return nil }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(posRef as! AXValue, .cgPoint, &point),  // swiftlint:disable:this force_cast
            AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)  // swiftlint:disable:this force_cast
        else { return nil }
        return CGRect(origin: point, size: size)
    }

    private static func set(_ element: AXUIElement, _ attribute: String, size: CGSize) {
        var value = size
        if let axValue = AXValueCreate(.cgSize, &value) {
            AXUIElementSetAttributeValue(element, attribute as CFString, axValue)
        }
    }

    private static func set(_ element: AXUIElement, _ attribute: String, point: CGPoint) {
        var value = point
        if let axValue = AXValueCreate(.cgPoint, &value) {
            AXUIElementSetAttributeValue(element, attribute as CFString, axValue)
        }
    }
}
