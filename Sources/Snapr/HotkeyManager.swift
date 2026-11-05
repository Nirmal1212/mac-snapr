import Carbon.HIToolbox
import SnaprCore

/// Global hotkeys through Carbon `RegisterEventHotKey` (no extra permission needed).
final class HotkeyManager {
    var onAction: ((SnapAction) -> Void)?
    private var refs: [EventHotKeyRef] = []
    private var actionsByID: [UInt32: SnapAction] = [:]
    private var handler: EventHandlerRef?
    private(set) var current = ShortcutMap()
    /// When false (an ignored app is frontmost) no hotkeys are registered, so key presses reach that app.
    var enabled = true
    private static let signature: OSType = 0x534E_4150  // 'SNAP'

    /// Installs the Carbon event handler. Call once.
    func install() {
        guard handler == nil else { return }
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                    nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                guard status == noErr else { return status }
                Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue().fire(hotKeyID.id)
                return noErr
            },
            1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    /// Replaces all registrations with the bindings in `map`. Returns actions the system refused
    /// (usually because another app owns the combo).
    @discardableResult
    func register(_ map: ShortcutMap) -> [SnapAction] {
        current = map
        unregisterAll()
        guard enabled else { return [] }
        var failed: [SnapAction] = []
        for (index, binding) in map.bindings.enumerated() {
            let id = UInt32(index + 1)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                binding.combo.keyCode, binding.combo.modifiers.rawValue,
                EventHotKeyID(signature: Self.signature, id: id), GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref {
                refs.append(ref)
                actionsByID[id] = binding.action
            } else {
                failed.append(binding.action)
            }
        }
        return failed
    }

    /// Temporarily releases all hotkeys (used while recording a shortcut).
    func suspend() { unregisterAll() }
    func resume() { register(current) }

    private func unregisterAll() {
        refs.forEach { UnregisterEventHotKey($0) }
        refs.removeAll()
        actionsByID.removeAll()
    }

    private func fire(_ id: UInt32) {
        guard let action = actionsByID[id] else { return }
        onAction?(action)
    }
}
