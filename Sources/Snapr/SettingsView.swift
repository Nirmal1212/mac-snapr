import AppKit
import SnaprCore
import SwiftUI

/// Settings window content: a sidebar of sections (or search results) and a detail pane for one section.
struct SettingsView: View {
    @ObservedObject var model: AppModel
    @AppStorage("settingsSelectedSection") private var storedSection = SettingsSection.general.rawValue
    @State private var query = ""
    @State private var resultSelection: String?
    @State private var scrollRequest: ScrollRequest?

    private static let index = SettingsIndex.standard

    /// Asks the detail pane to scroll to a setting; `token` makes repeated requests for one setting distinct.
    private struct ScrollRequest: Equatable {
        let id: String
        let token = UUID()
    }

    private var selection: SettingsSection { SettingsSection(rawValue: storedSection) ?? .general }
    private var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }
    private var results: [SettingsEntry] { Self.index.search(query) }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } detail: {
            SettingsDetail(model: model, section: selection, scrollRequest: scrollRequest?.id, token: scrollRequest?.token)
                .navigationTitle(selection.title)
        }
        .searchable(text: $query, placement: .sidebar, prompt: "Search settings")
        .onExitCommand { query = "" }
        .background(findShortcut)
        .frame(minWidth: 760, minHeight: 520)
    }

    // MARK: Sidebar

    @ViewBuilder private var sidebar: some View {
        if !isSearching {
            List(selection: sectionBinding) {
                ForEach(SettingsSection.allCases) { section in
                    Label(section.title, systemImage: section.symbol)
                        .tag(section)
                        .accessibilityLabel(section.title)
                }
            }
            .accessibilityLabel("Settings sections")
        } else if results.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.title2).foregroundColor(.secondary)
                Text("No results").font(.headline)
                Text("Nothing matches “\(query)”.").font(.caption).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)
        } else {
            List(selection: resultBinding) {
                ForEach(results) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title)
                        Label(entry.section.title, systemImage: entry.section.symbol)
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .tag(entry.id)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(entry.title), in \(entry.section.title)")
                }
            }
            .accessibilityLabel("Search results")
        }
    }

    private var sectionBinding: Binding<SettingsSection?> {
        Binding(get: { selection }, set: { if let new = $0 { storedSection = new.rawValue } })
    }

    /// Choosing a result opens its section and asks the detail pane to scroll to and highlight the setting.
    private var resultBinding: Binding<String?> {
        Binding(
            get: { resultSelection },
            set: { id in
                resultSelection = id
                guard let id, let entry = Self.index.entries.first(where: { $0.id == id }) else { return }
                storedSection = entry.section.rawValue
                scrollRequest = ScrollRequest(id: id)
            })
    }

    // MARK: Cmd+F

    /// Invisible button that owns the Cmd+F shortcut and focuses the sidebar search field.
    private var findShortcut: some View {
        Button("Search Settings") { Self.focusSearchField() }
            .keyboardShortcut("f", modifiers: .command)
            .opacity(0).frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }

    private static func focusSearchField() {
        guard let window = NSApp.keyWindow, let field = firstSearchField(in: window.contentView) else { return }
        window.makeFirstResponder(field)
    }

    private static func firstSearchField(in view: NSView?) -> NSSearchField? {
        guard let view else { return nil }
        if let field = view as? NSSearchField { return field }
        for subview in view.subviews {
            if let found = firstSearchField(in: subview) { return found }
        }
        return nil
    }
}

/// The detail pane: one section's grouped form, scrolled to and highlighting a searched setting on request.
private struct SettingsDetail: View {
    @ObservedObject var model: AppModel
    let section: SettingsSection
    let scrollRequest: String?
    let token: UUID?
    @State private var highlighted: String?
    @State private var pending: PendingShortcut?

    var body: some View {
        ScrollViewReader { proxy in
            Form { content }
                .formStyle(.grouped)
                .modifier(ShortcutConflictAlert(pending: $pending, model: model))
                .environment(\.highlightedSetting, highlighted)
                .id(section)
                .onChange(of: token) { _ in reveal(proxy) }
        }
    }

    @ViewBuilder private var content: some View {
        switch section {
        case .general: GeneralSettingsSection(model: model)
        case .shortcuts: ShortcutsSettingsSection(model: model, pending: $pending)
        case .layout: LayoutSettingsSection(model: model)
        case .gaps: GapSettingsSection(model: model)
        case .dragAndSnap: InputSettingsSections(model: model)
        case .multipleWindows: MultiWindowSettingsSections(model: model)
        case .customLayouts: CustomLayoutSections(model: model)
        case .ignoredApps:
            AppListSettingsSection(
                model: model, title: "Ignored Apps",
                explanation: "Snapr shortcuts are off while one of these apps is frontmost.",
                key: .ignoredApps, targetID: "ignored.apps")
        case .compatibility:
            AppListSettingsSection(
                model: model, title: "Compatibility",
                explanation: "Apps resized with a single size-then-position pass.",
                key: .nativeResizeApps, targetID: "compat.native-resize")
        case .configuration: ConfigurationSettingsSection(model: model)
        case .about: AboutSettingsSection(model: model)
        }
    }

    /// Scrolls to the requested setting once the section has been laid out, then flashes the highlight for ~1s.
    private func reveal(_ proxy: ScrollViewProxy) {
        guard let target = scrollRequest else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation { proxy.scrollTo(target, anchor: .center) }
            highlighted = target
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if highlighted == target { highlighted = nil }
            }
        }
    }
}
