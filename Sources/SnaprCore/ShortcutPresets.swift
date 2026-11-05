import Foundation

/// Ready-made shortcut sets. Entries are keyed by action name and resolved through `ActionRegistry`,
/// so names that are not registered are skipped and later actions can be added here freely.
public enum ShortcutPresets {
    /// Spectacle's default shortcuts. Actions Spectacle has no binding for are left unbound.
    public static func spectacle() -> ShortcutMap {
        typealias Key = KeyCombo.Key
        let optCmd: KeyModifiers = [.option, .command]
        let ctrlCmd: KeyModifiers = [.control, .command]
        let ctrlShiftCmd: KeyModifiers = [.control, .shift, .command]
        let ctrlOptCmd: KeyModifiers = [.control, .option, .command]
        let keyZ: UInt32 = 6
        let table: [(String, UInt32, KeyModifiers)] = [
            ("left-half", Key.left, optCmd),
            ("right-half", Key.right, optCmd),
            ("top-half", Key.up, optCmd),
            ("bottom-half", Key.down, optCmd),
            ("top-left-quarter", Key.left, ctrlCmd),
            ("top-right-quarter", Key.right, ctrlCmd),
            ("bottom-left-quarter", Key.left, ctrlShiftCmd),
            ("bottom-right-quarter", Key.right, ctrlShiftCmd),
            ("maximize", Key.f, optCmd),
            ("center", Key.c, optCmd),
            ("restore", keyZ, optCmd),
            ("next-display", Key.right, ctrlOptCmd),
            ("previous-display", Key.left, ctrlOptCmd)
        ]
        var map = ShortcutMap()
        for action in ActionRegistry.all { map.clear(action) }
        for (name, keyCode, modifiers) in table {
            guard let action = ActionRegistry.action(named: name) else { continue }
            map.assign(KeyCombo(keyCode: keyCode, modifiers: modifiers), to: action)
        }
        return map
    }

    /// Snapr's own defaults (no customizations).
    public static func defaults() -> ShortcutMap { ShortcutMap() }
}
