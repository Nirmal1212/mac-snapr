import SnaprCore
import SwiftUI

/// A shortcut assignment waiting for the user to confirm a conflict.
struct PendingShortcut {
    let action: SnapAction
    let combo: KeyCombo
    let other: SnapAction
}

/// The Shortcuts section: one recorder row per action plus the preset buttons.
struct ShortcutsSettingsSection: View {
    @ObservedObject var model: AppModel
    @Binding var pending: PendingShortcut?
    private var settings: SettingsStore { model.settings }

    var body: some View {
        Section("Shortcuts") {
            ForEach(ActionRegistry.grouped(), id: \.category) { group in
                Text(group.category.rawValue).font(.headline).padding(.top, 6)
                ForEach(group.actions, id: \.self) { action in
                    row(action).settingTarget("shortcuts.action.\(action.rawValue)")
                }
            }
            HStack {
                Button("Restore Default Shortcuts") { model.restoreDefaultShortcuts() }
                    .settingTarget("shortcuts.restore-defaults")
                Button("Use Spectacle Shortcuts") { model.applySpectacleShortcuts() }
                    .settingTarget("shortcuts.spectacle")
            }
        }
    }

    private func row(_ action: SnapAction) -> some View {
        let map = settings.get(.shortcuts)
        return HStack {
            Text(action.title)
            if model.failedShortcuts.contains(action) {
                Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
                    .help("The system or another app already uses this shortcut")
            }
            Spacer()
            ShortcutRecorder(combo: map.combo(for: action)) { combo in
                if let other = map.conflict(for: combo, excluding: action) {
                    pending = PendingShortcut(action: action, combo: combo, other: other)  // applied only after confirmation
                } else {
                    assign(combo, to: action)
                }
            }
            .frame(width: 150, height: 24)
            Button {
                update { $0.clear(action) }
            } label: { Image(systemName: "xmark.circle") }
                .buttonStyle(.borderless).help("Clear shortcut")
            Button {
                update { $0.resetToDefault(action) }
            } label: { Image(systemName: "arrow.counterclockwise") }
                .buttonStyle(.borderless).help("Reset to default")
        }
    }

    func assign(_ combo: KeyCombo, to action: SnapAction) {
        update { $0.assign(combo, to: action) }
    }

    private func update(_ change: (inout ShortcutMap) -> Void) {
        var map = settings.get(.shortcuts)
        change(&map)
        settings.set(map, for: .shortcuts)
    }
}

/// Confirmation alert shown when a recorded shortcut is already assigned to another action.
struct ShortcutConflictAlert: ViewModifier {
    @Binding var pending: PendingShortcut?
    let model: AppModel

    func body(content: Content) -> some View {
        content.alert(
            "Shortcut already in use",
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })
        ) {
            Button("Reassign") {
                if let pending {
                    var map = model.settings.get(.shortcuts)
                    map.assign(pending.combo, to: pending.action)
                    model.settings.set(map, for: .shortcuts)
                }
                pending = nil
            }
            Button("Cancel", role: .cancel) { pending = nil }
        } message: {
            if let pending {
                Text("\(pending.combo.displayString) is assigned to “\(pending.other.title)”. Reassign it to “\(pending.action.title)”?")
            }
        }
    }
}
