import AppKit
import ApplicationServices
import SnaprCore

/// Lists the windows of all regular apps through the Accessibility API (multi-window actions).
extension AXWindowProvider: WindowListProvider {
    /// Upper bound on windows listed per call, so a runaway app cannot stall an action.
    private static let maxWindows = 200
    private static let maxCachedElements = 500

    func allWindows() -> [ManagedWindow] {
        guard AXIsProcessTrusted() else { return [] }
        let selfPID = ProcessInfo.processInfo.processIdentifier
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isHidden && $0.processIdentifier != selfPID
        }
        let front = lastExternalPID
        let ordered = apps.sorted { ($0.processIdentifier == front ? 0 : 1) < ($1.processIdentifier == front ? 0 : 1) }
        var result: [ManagedWindow] = []
        for app in ordered {
            let element = AXUIElementCreateApplication(app.processIdentifier)
            AXUIElementSetMessagingTimeout(element, Self.messagingTimeout)
            var value: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &value) == .success,
                let windows = value as? [AXUIElement]
            else { continue }
            for window in windows {
                guard result.count < Self.maxWindows else { return prune(keeping: result) }
                AXUIElementSetMessagingTimeout(window, Self.messagingTimeout)
                guard Self.string(window, kAXSubroleAttribute) == kAXStandardWindowSubrole as String,
                    Self.bool(window, kAXMinimizedAttribute) != true,
                    let info = info(for: window)
                else { continue }
                result.append(
                    ManagedWindow(
                        id: info.id, frame: info.frame, bundleID: app.bundleIdentifier,
                        isActiveApp: app.processIdentifier == front, canMove: info.canMove,
                        canResize: info.canResize))
            }
        }
        return prune(keeping: result)
    }

    /// Bounds the element cache: past the cap, ids not in the latest listing are dropped (they are
    /// re-registered when seen again).
    private func prune(keeping result: [ManagedWindow]) -> [ManagedWindow] {
        if elements.count > Self.maxCachedElements {
            let live = Set(result.map(\.id))
            elements = elements.filter { live.contains($0.key) }
        }
        return result
    }

    func raise(_ id: WindowID) {
        guard let element = elements[id] else { return }
        AXUIElementPerformAction(element, kAXRaiseAction as CFString)
        AXUIElementSetAttributeValue(element, kAXMainAttribute as CFString, kCFBooleanTrue)
        var pid: pid_t = 0
        if AXUIElementGetPid(element, &pid) == .success {
            NSRunningApplication(processIdentifier: pid)?.activate(options: [])
        }
    }
}
