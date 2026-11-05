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
            layoutSection
            gapSection
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

    // MARK: Layout options

    private var layoutSection: some View {
        Section("Layout") {
            Picker("Repeat half cycle order", selection: layout(\.halfCycleOrder)) {
                ForEach(HalfCycleOrder.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            Picker("Repeating left/right half", selection: layout(\.repeatBehavior)) {
                ForEach(RepeatBehavior.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            Toggle("Repeating a quarter cycles through quadrants", isOn: layout(\.quadrantCycling))
            Toggle("Opposite half keeps the current width", isOn: layout(\.oppositeSideSwitch))
            Toggle("Repeating Maximize restores the window", isOn: layout(\.repeatedMaximizeRestores))
            Toggle("Halves keep the window's other axis", isOn: layout(\.halvesKeepOtherAxis))
            Toggle("Dragging a snapped window restores its size", isOn: layout(\.unsnapRestoresSize))
            Toggle("Thirds stack vertically on portrait displays", isOn: layout(\.portraitAwareThirds))
            Stepper(
                "Almost Maximize: \(Int((layoutOptions.almostMaximizeFraction * 100).rounded()))%",
                value: layout(\.almostMaximizeFraction), in: 0.5...1, step: 0.05)
            Stepper("Larger / Smaller step: \(Int(layoutOptions.resizeStep)) pt", value: layout(\.resizeStep), in: 5...200, step: 5)
            Stepper(
                "Specified size width: \(Int(layoutOptions.specifiedSize.width)) pt",
                value: layoutSize(\.width), in: 200...8000, step: 20)
            Stepper(
                "Specified size height: \(Int(layoutOptions.specifiedSize.height)) pt",
                value: layoutSize(\.height), in: 200...8000, step: 20)
        }
    }

    private var gapSection: some View {
        Section("Gaps") {
            Stepper("Between windows: \(Int(layoutOptions.gaps.windowGap)) pt", value: gap(\.windowGap), in: 0...100, step: 1)
            Stepper("Screen top: \(Int(layoutOptions.gaps.screenGaps.top)) pt", value: gap(\.screenGaps.top), in: 0...200, step: 1)
            Stepper("Screen left: \(Int(layoutOptions.gaps.screenGaps.left)) pt", value: gap(\.screenGaps.left), in: 0...200, step: 1)
            Stepper("Screen bottom: \(Int(layoutOptions.gaps.screenGaps.bottom)) pt", value: gap(\.screenGaps.bottom), in: 0...200, step: 1)
            Stepper("Screen right: \(Int(layoutOptions.gaps.screenGaps.right)) pt", value: gap(\.screenGaps.right), in: 0...200, step: 1)
            Toggle("Only on the main screen", isOn: gap(\.mainScreenOnly))
            Toggle("Keep windows below the notch", isOn: gap(\.notchAwareTopGap))
            Toggle("Use full height when the menu bar is hidden", isOn: gap(\.fullHeightWhenMenuBarHidden))
            DisclosureGroup("Actions exempt from gaps") {
                ForEach(ActionRegistry.all, id: \.self) { action in
                    Toggle(action.title, isOn: exempt(action))
                }
            }
        }
    }

    private var layoutOptions: LayoutOptions { settings.get(.layoutOptions) }

    private func updateLayout(_ change: (inout LayoutOptions) -> Void) {
        var options = settings.get(.layoutOptions)
        change(&options)
        settings.set(options, for: .layoutOptions)
    }

    private func layout<V>(_ keyPath: WritableKeyPath<LayoutOptions, V>) -> Binding<V> {
        Binding(get: { layoutOptions[keyPath: keyPath] }, set: { value in updateLayout { $0[keyPath: keyPath] = value } })
    }

    private func layoutSize(_ keyPath: WritableKeyPath<CGSize, CGFloat>) -> Binding<CGFloat> {
        Binding(
            get: { layoutOptions.specifiedSize[keyPath: keyPath] },
            set: { value in updateLayout { $0.specifiedSize[keyPath: keyPath] = value } })
    }

    private func gap<V>(_ keyPath: WritableKeyPath<GapOptions, V>) -> Binding<V> {
        Binding(
            get: { layoutOptions.gaps[keyPath: keyPath] },
            set: { value in updateLayout { $0.gaps[keyPath: keyPath] = value } })
    }

    private func exempt(_ action: SnapAction) -> Binding<Bool> {
        Binding(
            get: { layoutOptions.gaps.isExempt(action) },
            set: { on in
                updateLayout {
                    if on { $0.gaps.exemptActions.insert(action.name) } else { $0.gaps.exemptActions.remove(action.name) }
                }
            })
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
