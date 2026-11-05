import SnaprCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchError: String?
    @State private var pending: (action: SnapAction, combo: KeyCombo, other: SnapAction)?

    private var settings: SettingsStore { model.settings }

    var body: some View {
        Form {
            Section("General") {
                Toggle("Snap windows by dragging to screen edges", isOn: binding(.dragSnapEnabled))
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in
                        do {
                            try LaunchAtLogin.set(enabled)
                            settings.set(enabled, for: .launchAtLogin)
                            launchError = nil
                        } catch {
                            launchAtLogin = LaunchAtLogin.isEnabled
                            launchError = "Could not change login item: \(error.localizedDescription)"
                        }
                    }
                if let launchError { Text(launchError).font(.caption).foregroundColor(.red) }
                Toggle("Automatically check for updates", isOn: binding(.automaticUpdateChecks))
                    .disabled(!model.updater.isAvailable)
                    .help(model.updater.isAvailable ? "" : "Updates are not configured in this build")
                HStack {
                    Text(model.trusted ? "Accessibility access: granted" : "Accessibility access: not granted")
                    if !model.trusted { Button("Grant…") { model.requestAccessibility() } }
                }
                if model.trusted && !model.dragRunning {
                    HStack {
                        Text("Drag snapping is not running (event tap unavailable). Retrying…")
                            .font(.caption).foregroundColor(.orange)
                        Button("Grant Access…") { model.requestAccessibility() }
                    }
                }
            }
            InputSettingsSections(model: model)
            Section("Shortcuts") {
                ForEach(ActionRegistry.grouped(), id: \.category) { group in
                    Text(group.category.rawValue).font(.headline).padding(.top, 6)
                    ForEach(group.actions, id: \.self) { action in row(action) }
                }
                HStack {
                    Button("Restore Default Shortcuts") { model.restoreDefaultShortcuts() }
                    Button("Use Spectacle Shortcuts") { model.applySpectacleShortcuts() }
                }
            }
            Section("Ignored Apps") {
                Text("Snapr shortcuts are off while one of these apps is frontmost.")
                    .font(.caption).foregroundColor(.secondary)
                appList(.ignoredApps)
            }
            Section("Compatibility") {
                Text("Apps resized with a single size-then-position pass.")
                    .font(.caption).foregroundColor(.secondary)
                appList(.nativeResizeApps)
            }
            Section("Configuration") {
                HStack {
                    Button("Import Config…") { model.importConfig() }
                    Button("Export Config…") { model.exportConfig() }
                    Button("Debug Log…") { model.showDebugLog() }
                }
                if let message = model.configMessage { Text(message).font(.caption).foregroundColor(.secondary) }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 520, minHeight: 600)
        .alert(
            "Shortcut already in use",
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })
        ) {
            Button("Reassign") {
                if let pending { assign(pending.combo, to: pending.action) }
                pending = nil
            }
            Button("Cancel", role: .cancel) { pending = nil }
        } message: {
            if let pending {
                Text("\(pending.combo.displayString) is assigned to “\(pending.other.title)”. Reassign it to “\(pending.action.title)”?")
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
                    pending = (action, combo, other)  // warn; applied only after confirmation
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

    private func assign(_ combo: KeyCombo, to action: SnapAction) {
        update { $0.assign(combo, to: action) }
    }

    private func update(_ change: (inout ShortcutMap) -> Void) {
        var map = settings.get(.shortcuts)
        change(&map)
        settings.set(map, for: .shortcuts)
    }

    /// Editable list of bundle identifiers with an "add current app" shortcut.
    private func appList(_ key: SettingKey<[String]>) -> some View {
        let list = settings.get(key)
        return VStack(alignment: .leading) {
            ForEach(list, id: \.self) { id in
                HStack {
                    Text(id)
                    Spacer()
                    Button {
                        settings.set(list.filter { $0 != id }, for: key)
                    } label: { Image(systemName: "minus.circle") }
                        .buttonStyle(.borderless)
                }
            }
            if let app = model.targetApp, !list.contains(app.bundleID) {
                Button("Add \(app.name)") { settings.set(list + [app.bundleID], for: key) }
            }
        }
    }

    private func binding(_ key: SettingKey<Bool>) -> Binding<Bool> {
        Binding(get: { settings.get(key) }, set: { settings.set($0, for: key) })
    }
}
