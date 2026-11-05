import SnaprCore
import SwiftUI

/// Settings sections for custom zones, saved layouts and the experimental Spaces feature.
struct CustomLayoutSections: View {
    @ObservedObject var model: AppModel
    @State private var newLayoutName = ""

    var body: some View {
        Section("Custom Zones") {
            Text("Zones are fractions of the usable screen area (after gaps). Run them from the menu, a shortcut, or snapr://execute-action?name=custom:<id>.")
                .font(.caption).foregroundColor(.secondary)
            ForEach(model.customZones) { zone in zoneRow(zone) }
            HStack {
                Button("Add Zone") { model.addZone() }
                if let message = model.layoutMessage { Text(message).font(.caption).foregroundColor(.red) }
            }
        }
        Section("Saved Layouts") {
            Text("Save where your windows are now and bring them back later. Windows are matched by app and title; closed apps are not launched.")
                .font(.caption).foregroundColor(.secondary)
            ForEach(model.savedLayouts) { layout in layoutRow(layout) }
            HStack {
                TextField("Layout name", text: $newLayoutName)
                Button("Save Current Windows") {
                    model.saveCurrentLayout(named: newLayoutName)
                    newLayoutName = ""
                }
            }
        }
        Section("Spaces (experimental)") {
            Toggle(
                "Enable moving windows to other Spaces",
                isOn: Binding(get: { model.spacesEnabled }, set: { model.setSpacesEnabled($0) }))
            Text("Uses undocumented macOS functions. It may stop working in any macOS update and does nothing when unsupported. Use snapr://execute-action?name=space:next, space:previous or space:1 … space:16, or the menu.")
                .font(.caption).foregroundColor(.secondary)
            if model.spacesEnabled && !model.spaceMoverAvailable {
                Text("Not supported on this macOS version.").font(.caption).foregroundColor(.red)
            }
        }
    }

    private func zoneRow(_ zone: CustomZone) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("Name", text: zoneBinding(zone, \.name))
                Spacer()
                ShortcutRecorder(combo: zone.shortcut) { combo in
                    var updated = zone
                    updated.shortcut = combo
                    model.saveZone(updated)
                }
                .frame(width: 150, height: 24)
                Button("Clear") {
                    var updated = zone
                    updated.shortcut = nil
                    model.saveZone(updated)
                }
                .disabled(zone.shortcut == nil)
                Button("Remove") { model.removeZone(zone.id) }
            }
            HStack {
                percent("X", zone, \.rect.x)
                percent("Y", zone, \.rect.y)
                percent("W", zone, \.rect.width)
                percent("H", zone, \.rect.height)
                Text("id: \(zone.id)").font(.caption2).foregroundColor(.secondary).textSelection(.enabled)
            }
        }
        .padding(.vertical, 2)
    }

    private func layoutRow(_ layout: SavedLayout) -> some View {
        HStack {
            Text("\(layout.name) (\(layout.entries.count))")
            Spacer()
            ShortcutRecorder(combo: layout.shortcut) { combo in
                var updated = layout
                updated.shortcut = combo
                model.saveLayout(updated)
            }
            .frame(width: 150, height: 24)
            Button("Clear") {
                var updated = layout
                updated.shortcut = nil
                model.saveLayout(updated)
            }
            .disabled(layout.shortcut == nil)
            Button("Apply") { model.perform(layout.action) }
            Button("Remove") { model.removeLayout(layout.id) }
        }
    }

    private func zoneBinding(_ zone: CustomZone, _ path: WritableKeyPath<CustomZone, String>) -> Binding<String> {
        Binding(
            get: { zone[keyPath: path] },
            set: { value in
                var updated = zone
                updated[keyPath: path] = value
                model.saveZone(updated)
            })
    }

    /// A percent field (0...100) for one edge of the zone rectangle; invalid rectangles are rejected by the store.
    private func percent(_ label: String, _ zone: CustomZone, _ path: WritableKeyPath<CustomZone, Double>) -> some View {
        HStack(spacing: 2) {
            Text(label).font(.caption)
            TextField(
                "", value: Binding(
                    get: { (zone[keyPath: path] * 100).rounded() },
                    set: { value in
                        var updated = zone
                        updated[keyPath: path] = value / 100
                        model.saveZone(updated)
                    }), format: .number
            )
            .frame(width: 44)
            Text("%").font(.caption)
        }
    }
}
