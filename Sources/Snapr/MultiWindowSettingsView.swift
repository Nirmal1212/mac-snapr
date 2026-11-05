import SnaprCore
import SwiftUI

/// Settings sections for the multi-window modes: tiling, cascade/stack, Todo, Stage Manager, new windows.
struct MultiWindowSettingsSections: View {
    @ObservedObject var model: AppModel
    private var settings: SettingsStore { model.settings }

    var body: some View {
        Section("Multiple windows") {
            Stepper("Max windows per row: \(options.maxPerRow == 0 ? "unlimited" : "\(options.maxPerRow)")",
                value: binding(\.maxPerRow), in: 0...12)
                .settingTarget("multi.max-per-row")
            Stepper("Max windows per column: \(options.maxPerColumn == 0 ? "unlimited" : "\(options.maxPerColumn)")",
                value: binding(\.maxPerColumn), in: 0...12)
                .settingTarget("multi.max-per-column")
            Toggle("Balanced grids (last row or column fills the space)", isOn: binding(\.balancedGrid))
                .settingTarget("multi.balanced-grid")
            Toggle("Combined displays (tile across all displays)", isOn: binding(\.combinedDisplays))
                .settingTarget("multi.combined-displays")
            Stepper("Cascade offset: \(Int(options.cascadeOffset)) pt", value: binding(\.cascadeOffset), in: 10...100, step: 5)
                .settingTarget("multi.cascade-offset")
            Stepper("Stack overlap offset: \(Int(options.stackOffset)) pt", value: binding(\.stackOffset), in: 10...100, step: 2)
                .settingTarget("multi.stack-offset")
            Toggle("Stacked windows share one size", isOn: binding(\.stackSameSize))
                .settingTarget("multi.stack-same-size")
            Toggle("Show stack badge when cycling", isOn: binding(\.showStackBadge))
                .settingTarget("multi.stack-badge")
        }
        Section("Todo mode") {
            Toggle("Todo mode", isOn: binding(\.todo.enabled))
                .settingTarget("multi.todo")
            HStack {
                Text("Todo app")
                TextField("Bundle identifier (set from the frontmost app by Toggle Todo)", text: Binding(
                    get: { options.todo.bundleID ?? "" },
                    set: { new in update { $0.todo.bundleID = new.isEmpty ? nil : new } }))
                    .textFieldStyle(.roundedBorder)
            }
            .settingTarget("multi.todo-app")
            Stepper("Sidebar width: \(Int(options.todo.sidebarWidth)) pt", value: binding(\.todo.sidebarWidth), in: 150...1000, step: 10)
                .settingTarget("multi.todo-width")
            Picker("Sidebar side", selection: binding(\.todo.side)) {
                ForEach(ScreenSide.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .settingTarget("multi.todo-side")
        }
        Section("Stage Manager") {
            Toggle("Keep layouts clear of the Stage Manager strip", isOn: binding(\.stageManager.enabled))
                .settingTarget("multi.stage-manager")
            Text("Applies only while Stage Manager is turned on in System Settings.")
                .font(.caption).foregroundColor(.secondary)
            Stepper("Strip width: \(Int(options.stageManager.stripWidth)) pt", value: binding(\.stageManager.stripWidth), in: 50...400, step: 10)
                .settingTarget("multi.stage-width")
            Picker("Strip side", selection: binding(\.stageManager.side)) {
                ForEach(ScreenSide.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .settingTarget("multi.stage-side")
        }
        Section("New windows") {
            Picker("Apply to every new window", selection: Binding(
                get: { options.newWindowAction ?? "" },
                set: { new in update { $0.newWindowAction = new.isEmpty ? nil : new } })) {
                Text("Nothing").tag("")
                ForEach(SnapAction.allCases.filter { !$0.isMultiWindow && $0 != .restore }, id: \.self) {
                    Text($0.title).tag($0.name)
                }
            }
            .settingTarget("multi.new-window-action")
        }
    }

    private var options: MultiWindowOptions { settings.get(.multiWindowOptions) }

    private func update(_ change: (inout MultiWindowOptions) -> Void) {
        var value = settings.get(.multiWindowOptions)
        change(&value)
        settings.set(value, for: .multiWindowOptions)
    }

    private func binding<T>(_ path: WritableKeyPath<MultiWindowOptions, T>) -> Binding<T> {
        Binding(get: { options[keyPath: path] }, set: { new in update { $0[keyPath: path] = new } })
    }

    private func binding(_ path: WritableKeyPath<MultiWindowOptions, CGFloat>) -> Binding<Double> {
        Binding(get: { Double(options[keyPath: path]) }, set: { new in update { $0[keyPath: path] = CGFloat(new) } })
    }
}
