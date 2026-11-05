import SnaprCore
import SwiftUI

/// The General section: drag snapping master switch, login item, update checks, Accessibility status.
struct GeneralSettingsSection: View {
    @ObservedObject var model: AppModel
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchError: String?
    private var settings: SettingsStore { model.settings }

    var body: some View {
        Section("General") {
            Toggle("Snap windows by dragging to screen edges", isOn: settings.binding(.dragSnapEnabled))
                .settingTarget("general.drag-snap")
            Toggle("Launch at login", isOn: $launchAtLogin)
                .settingTarget("general.launch-at-login")
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
            Toggle("Automatically check for updates", isOn: settings.binding(.automaticUpdateChecks))
                .disabled(!model.updater.isAvailable)
                .help(model.updater.isAvailable ? "" : "Updates are not configured in this build")
                .settingTarget("general.auto-updates")
            HStack {
                Text(model.trusted ? "Accessibility access: granted" : "Accessibility access: not granted")
                if !model.trusted { Button("Grant…") { model.requestAccessibility() } }
            }
            .settingTarget("general.accessibility")
            if model.trusted && !model.dragRunning {
                HStack {
                    Text("Drag snapping is not running (event tap unavailable). Retrying…")
                        .font(.caption).foregroundColor(.orange)
                    Button("Grant Access…") { model.requestAccessibility() }
                }
            }
            Toggle("Show intro when opening the menu", isOn: settings.binding(.showIntroOnOpen))
                .settingTarget("general.show-intro")
        }
    }
}

/// The Ignored Apps and Compatibility sections: editable lists of bundle identifiers.
struct AppListSettingsSection: View {
    @ObservedObject var model: AppModel
    let title: String
    let explanation: String
    let key: SettingKey<[String]>
    let targetID: String
    private var settings: SettingsStore { model.settings }

    var body: some View {
        let list = settings.get(key)
        Section(title) {
            Text(explanation)
                .font(.caption).foregroundColor(.secondary)
                .settingTarget(targetID)
            VStack(alignment: .leading) {
                ForEach(list, id: \.self) { id in
                    HStack {
                        Text(id)
                        Spacer()
                        Button {
                            settings.set(list.filter { $0 != id }, for: key)
                        } label: { Image(systemName: "minus.circle") }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Remove \(id)")
                    }
                }
                if let app = model.targetApp, !list.contains(app.bundleID) {
                    Button("Add \(app.name)") { settings.set(list + [app.bundleID], for: key) }
                }
            }
        }
    }
}

/// The Configuration section: import, export and the debug log.
struct ConfigurationSettingsSection: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Section("Configuration") {
            HStack {
                Button("Import Config…") { model.importConfig() }.settingTarget("config.import")
                Button("Export Config…") { model.exportConfig() }.settingTarget("config.export")
                Button("Debug Log…") { model.showDebugLog() }.settingTarget("config.debug-log")
            }
            if let message = model.configMessage { Text(message).font(.caption).foregroundColor(.secondary) }
        }
    }
}

/// The About section: version, manual update check and project links.
struct AboutSettingsSection: View {
    @ObservedObject var model: AppModel

    private static let repository = URL(string: "https://github.com/Nirmal1212/mac-snapr")

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String
        switch (short, build) {
        case let (short?, build?) where short != build: return "\(short) (\(build))"
        case let (short?, _): return short
        default: return "Development build"
        }
    }

    var body: some View {
        Section("About") {
            LabeledContent("Version", value: version)
                .settingTarget("about.version")
            HStack {
                Button("Check for Updates…") { model.updater.checkForUpdates() }
                    .disabled(!model.updater.isAvailable)
                if !model.updater.isAvailable {
                    Text("Updates are not configured in this build").font(.caption).foregroundColor(.secondary)
                }
            }
            .settingTarget("about.check-updates")
            if let repository = Self.repository {
                Link("Snapr on GitHub", destination: repository)
                    .settingTarget("about.github")
            }
        }
    }
}
