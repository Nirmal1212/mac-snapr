import AppKit
import SnaprCore
import SwiftUI

/// Settings sections for advanced input: drag-snap tuning, display rules, mouse and title-bar triggers.
struct InputSettingsSections: View {
    @ObservedObject var model: AppModel
    private var settings: SettingsStore { model.settings }

    var body: some View {
        Section("Drag snapping") {
            Text("Zones").font(.headline).settingTarget("drag.zones")
            ForEach(DragZone.allCases, id: \.self) { zone in
                Toggle(zone.title, isOn: zoneBinding(zone))
            }
            HStack {
                Text("Require modifier")
                Spacer()
                modifierToggles(optionsBinding(\.requiredModifiers))
            }
            .settingTarget("drag.modifier")
            slider("Edge margin", optionsBinding(\.edgeMargin), 1...50).settingTarget("drag.edge-margin")
            slider("Corner size", optionsBinding(\.cornerSize), 20...200).settingTarget("drag.corner-size")
            Toggle("Animate windows", isOn: optionsBinding(\.animate)).settingTarget("drag.animate")
            Toggle("Keep dragging above the menu bar from opening Mission Control", isOn: optionsBinding(\.preventMissionControl))
                .settingTarget("drag.mission-control")
        }
        Section("Drag preview") {
            slider("Opacity", optionsBinding(\.footprint.alpha), 0.05...0.8).settingTarget("drag.preview-opacity")
            slider("Border width", optionsBinding(\.footprint.borderWidth), 0...8).settingTarget("drag.preview-border")
            Toggle("Blur", isOn: optionsBinding(\.footprint.blur)).settingTarget("drag.preview-blur")
            HStack {
                ColorPicker("Color", selection: colorBinding)
                Button("Use accent color") { updateOptions { $0.footprint.color = nil } }
                    .disabled(settings.get(.dragSnapOptions).footprint.color == nil)
            }
            .settingTarget("drag.preview-color")
        }
        Section("Displays") {
            Toggle("Order displays by x coordinate", isOn: rulesBinding(\.orderByX)).settingTarget("drag.displays-order")
            Toggle("Keep size when moving a maximized window", isOn: rulesBinding(\.keepSizeWhenMaximized))
                .settingTarget("drag.displays-keep-size")
            Toggle("Repeat last action on the other display", isOn: rulesBinding(\.repeatLastAction))
                .settingTarget("drag.displays-repeat")
            Toggle("Move cursor with window", isOn: rulesBinding(\.moveCursorWithWindow)).settingTarget("drag.displays-cursor")
        }
        Section("Mouse and title bar") {
            Toggle("Double-click title bar to maximize / restore", isOn: boolBinding(.titleBarDoubleClick))
                .settingTarget("drag.title-bar")
            ForEach(settings.get(.mouseShortcuts)) { shortcut in mouseRow(shortcut) }
            Button("Add Mouse Button Shortcut") {
                update(.mouseShortcuts) { $0.append(MouseShortcut(button: 2, action: .maximize)) }
            }
            .settingTarget("drag.mouse-shortcuts")
        }
    }

    // MARK: - Rows

    private func mouseRow(_ shortcut: MouseShortcut) -> some View {
        HStack {
            Picker("", selection: mouseBinding(shortcut.id, \.button)) {
                Text("Middle").tag(2)
                ForEach(3...6, id: \.self) { Text("Button \($0 + 1)").tag($0) }
            }
            .labelsHidden().frame(width: 100)
            modifierToggles(mouseBinding(shortcut.id, \.modifiers))
            Picker("", selection: mouseBinding(shortcut.id, \.action)) {
                ForEach(SnapAction.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .labelsHidden()
            Toggle("Under pointer", isOn: mouseBinding(shortcut.id, \.underPointer))
            Button {
                update(.mouseShortcuts) { $0.removeAll { $0.id == shortcut.id } }
            } label: { Image(systemName: "minus.circle") }
                .buttonStyle(.borderless)
        }
    }

    private func modifierToggles(_ binding: Binding<KeyModifiers>) -> some View {
        HStack(spacing: 4) {
            ForEach([("⌃", KeyModifiers.control), ("⌥", .option), ("⇧", .shift), ("⌘", .command)], id: \.1.rawValue) { item in
                Toggle(item.0, isOn: Binding(
                    get: { binding.wrappedValue.contains(item.1) },
                    set: { on in
                        var value = binding.wrappedValue
                        if on { value.insert(item.1) } else { value.remove(item.1) }
                        binding.wrappedValue = value
                    }))
                    .toggleStyle(.button)
            }
        }
    }

    private func slider(_ title: String, _ binding: Binding<Double>, _ range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
            Slider(value: binding, in: range)
            Text(String(format: "%.2f", binding.wrappedValue)).monospacedDigit().frame(width: 44)
        }
    }

    // MARK: - Bindings

    private func updateOptions(_ change: (inout DragSnapOptions) -> Void) {
        var value = settings.get(.dragSnapOptions)
        change(&value)
        settings.set(value, for: .dragSnapOptions)
    }

    private func update<V: Codable>(_ key: SettingKey<V>, _ change: (inout V) -> Void) {
        var value = settings.get(key)
        change(&value)
        settings.set(value, for: key)
    }

    private func optionsBinding<T>(_ path: WritableKeyPath<DragSnapOptions, T>) -> Binding<T> {
        Binding(
            get: { settings.get(.dragSnapOptions)[keyPath: path] },
            set: { new in updateOptions { $0[keyPath: path] = new } })
    }

    private func rulesBinding(_ path: WritableKeyPath<DisplayRules, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings.get(.displayRules)[keyPath: path] },
            set: { new in update(.displayRules) { $0[keyPath: path] = new } })
    }

    private func boolBinding(_ key: SettingKey<Bool>) -> Binding<Bool> {
        Binding(get: { settings.get(key) }, set: { settings.set($0, for: key) })
    }

    private func zoneBinding(_ zone: DragZone) -> Binding<Bool> {
        Binding(
            get: { settings.get(.dragSnapOptions).enabledZones.contains(zone) },
            set: { on in
                updateOptions { if on { $0.enabledZones.insert(zone) } else { $0.enabledZones.remove(zone) } }
            })
    }

    private func mouseBinding<T>(_ id: UUID, _ path: WritableKeyPath<MouseShortcut, T>) -> Binding<T> {
        Binding(
            get: { (settings.get(.mouseShortcuts).first { $0.id == id } ?? MouseShortcut(action: .maximize))[keyPath: path] },
            set: { new in
                update(.mouseShortcuts) { list in
                    if let index = list.firstIndex(where: { $0.id == id }) { list[index][keyPath: path] = new }
                }
            })
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: {
                if let c = settings.get(.dragSnapOptions).footprint.color, c.count >= 3 {
                    return Color(.sRGB, red: c[0], green: c[1], blue: c[2])
                }
                return Color(nsColor: .controlAccentColor)
            },
            set: { color in
                guard let rgb = NSColor(color).usingColorSpace(.sRGB) else { return }
                updateOptions {
                    $0.footprint.color = [Double(rgb.redComponent), Double(rgb.greenComponent), Double(rgb.blueComponent)]
                }
            })
    }
}
