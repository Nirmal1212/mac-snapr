import AppKit
import SnaprCore
import SwiftUI

/// Content of the menu bar popover (`MenuBarExtra` in `.window` style): an Intro page and an Actions page.
struct MenuPopoverView: View {
    @ObservedObject var model: AppModel
    @State private var state = MenuPopoverState()
    @State private var popover: NSWindow?

    private static let width: CGFloat = 320

    var body: some View {
        Group {
            switch state.page {
            case .intro:
                MenuIntroPage(model: model, showActions: { state.showActions() }, openSettings: openSettings)
            case .actions:
                MenuActionsPage(model: model, showIntro: { state.showIntro() }, close: close)
            }
        }
        .frame(width: Self.width)
        .background(WindowReader { popover = $0 })
        // Escape closes the popover (also reachable through the hidden cancel button below).
        .onExitCommand(perform: close)
        .background(Button("Close", action: close).keyboardShortcut(.cancelAction).opacity(0).accessibilityHidden(true))
        // The popover content view is created once and kept alive, so `onAppear` only fires for the
        // first open. The panel becoming key is the signal for every open.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { note in
            guard let window = note.object as? NSWindow, window === popover else { return }
            state.didOpen(introEnabled: model.settings.get(.showIntroOnOpen))
        }
        .onAppear { state.didOpen(introEnabled: model.settings.get(.showIntroOnOpen)) }
    }

    private func close() { popover?.close() }

    private func openSettings() {
        close()
        DispatchQueue.main.async { model.showSettings() }
    }
}

// MARK: - Intro

private struct MenuIntroPage: View {
    @ObservedObject var model: AppModel
    let showActions: () -> Void
    let openSettings: () -> Void

    private static let icon: NSImage? = {
        // Only the packaged app has an AppIcon; `swift run` would show the generic executable icon.
        Bundle.main.bundleURL.pathExtension == "app" ? NSApp.applicationIconImage : nil
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Group {
                    if let icon = Self.icon {
                        Image(nsImage: icon).resizable()
                    } else {
                        Image(systemName: "rectangle.split.2x2").resizable().scaledToFit().padding(8)
                            .foregroundColor(.accentColor)
                    }
                }
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)
                Text("Welcome to Snapr").font(.title3).bold().accessibilityAddTraits(.isHeader)
            }
            Text(IntroContent.summary).fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 8) {
                tip("keyboard", IntroContent.shortcutTip(model.settings.get(.shortcuts)))
                tip("macwindow.badge.plus", IntroContent.dragTip)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "gearshape").frame(width: 18).foregroundColor(.accentColor).accessibilityHidden(true)
                    Text(IntroContent.settingsTip).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button("Settings…", action: openSettings).controlSize(.small)
                }
            }
            if !model.trusted {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).accessibilityHidden(true)
                    Text("Accessibility access: not granted").font(.callout)
                    Spacer(minLength: 0)
                    Button("Grant…") { model.showOnboarding() }.controlSize(.small)
                }
                .accessibilityElement(children: .contain)
            } else {
                Label("Accessibility access: granted", systemImage: "checkmark.circle.fill")
                    .font(.callout).foregroundColor(.secondary)
            }
            Divider()
            HStack {
                Button("Quit Snapr") { NSApplication.shared.terminate(nil) }
                Spacer()
                Button("Show all options", action: showActions).keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
    }

    private func tip(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol).frame(width: 18).foregroundColor(.accentColor).accessibilityHidden(true)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Actions

private struct MenuActionsPage: View {
    @ObservedObject var model: AppModel
    let showIntro: () -> Void
    let close: () -> Void

    @State private var expanded: Set<String> = []
    @FocusState private var focus: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Snapr").font(.headline).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Intro", action: showIntro).controlSize(.small)
                    .accessibilityLabel("Show introduction")
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !model.trusted {
                        row(id: "grant", title: "Grant Accessibility Access…", symbol: "lock.open") {
                            runAfterClose { model.showOnboarding() }
                        }
                    }
                    ForEach(ActionRegistry.grouped(), id: \.category) { group in
                        let key = group.category.rawValue
                        // Large categories start collapsed, as submenus did in the old menu.
                        section(key, defaultOpen: group.actions.count <= 8) {
                            ForEach(group.actions, id: \.self) { action in
                                row(id: "a:\(action.name)", title: action.title, shortcut: shortcut(action)) {
                                    runAfterClose { model.perform(action) }
                                }
                            }
                        }
                    }
                    customSections
                    if let app = model.targetApp {
                        Divider().padding(.vertical, 4)
                        row(
                            id: "ignore", title: model.targetAppIgnored ? "Stop Ignoring \(app.name)" : "Ignore \(app.name)",
                            symbol: "nosign"
                        ) {
                            model.toggleIgnoreTargetApp()
                        }
                    }
                }
                .padding(6)
            }
            .frame(height: 380)
            .onMoveCommand(perform: move)
            Divider()
            VStack(spacing: 0) {
                row(id: "settings", title: "Settings…", shortcut: "⌘,", symbol: "gearshape") {
                    runAfterClose { model.showSettings() }
                }
                .keyboardShortcut(",")
                row(id: "updates", title: "Check for Updates…", symbol: "arrow.triangle.2.circlepath") {
                    runAfterClose { model.updater.checkForUpdates() }
                }
                .disabled(!model.updater.isAvailable)
                row(id: "quit", title: "Quit Snapr", shortcut: "⌘Q", symbol: "power") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding(6)
        }
        .onAppear { if focus == nil { focus = firstRowID } }
    }

    // MARK: custom zones, layouts, spaces

    @ViewBuilder
    private var customSections: some View {
        let zones = model.customZones
        let layouts = model.savedLayouts
        if !zones.isEmpty {
            section("Custom Zones", defaultOpen: false) {
                ForEach(zones) { zone in
                    row(id: "z:\(zone.id)", title: zone.name, shortcut: zone.shortcut?.displayString) {
                        runAfterClose { model.perform(zone.action) }
                    }
                }
            }
        }
        if !layouts.isEmpty {
            section("Saved Layouts", defaultOpen: false) {
                ForEach(layouts) { layout in
                    row(id: "l:\(layout.id)", title: layout.name, shortcut: layout.shortcut?.displayString) {
                        runAfterClose { model.perform(layout.action) }
                    }
                }
            }
        }
        if model.spaceActionsActive {
            section("Move to Space", defaultOpen: false) {
                row(id: "s:next", title: "Next Space") { runAfterClose { model.perform(.space(.next)) } }
                row(id: "s:prev", title: "Previous Space") { runAfterClose { model.perform(.space(.previous)) } }
                ForEach(1...9, id: \.self) { n in
                    row(id: "s:\(n)", title: "Space \(n)") { runAfterClose { model.perform(.space(.index(n))) } }
                }
            }
        }
    }

    // MARK: building blocks

    private func isOpen(_ key: String, _ defaultOpen: Bool) -> Bool {
        expanded.contains(key) ? !defaultOpen : defaultOpen
    }

    private func section<Content: View>(
        _ title: String, defaultOpen: Bool, @ViewBuilder content: () -> Content
    ) -> some View {
        let open = isOpen(title, defaultOpen)
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                if expanded.contains(title) { expanded.remove(title) } else { expanded.insert(title) }
            } label: {
                HStack {
                    Image(systemName: open ? "chevron.down" : "chevron.right").font(.caption).frame(width: 12)
                    Text(title).font(.subheadline).bold()
                    Spacer()
                }
                .padding(.horizontal, 8).padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focused($focus, equals: "g:\(title)")
            .accessibilityLabel("\(title), \(open ? "expanded" : "collapsed")")
            .accessibilityHint("Toggles this group")
            .accessibilityAddTraits(.isHeader)
            if open { content() }
        }
    }

    private func row(
        id: String, title: String, shortcut: String? = nil, symbol: String? = nil, action: @escaping () -> Void
    ) -> some View {
        MenuRow(title: title, shortcut: shortcut, symbol: symbol, isFocused: focus == id, action: action)
            .focused($focus, equals: id)
    }

    private func shortcut(_ action: SnapAction) -> String? {
        model.settings.get(.shortcuts).combo(for: action)?.displayString
    }

    /// Closes the popover first so focus returns to the previous app, then runs. Window actions target the
    /// last non-Snapr frontmost app (see `ExternalAppTracker`), not the popover.
    private func runAfterClose(_ work: @escaping () -> Void) {
        close()
        DispatchQueue.main.async(execute: work)
    }

    // MARK: keyboard

    /// Focusable ids in display order: group headers plus the rows of open groups.
    private var firstRowID: String? { model.trusted ? "g:\(ActionRegistry.grouped().first?.category.rawValue ?? "")" : "grant" }

    private func move(_ direction: MoveCommandDirection) {
        let order = focusOrder()
        guard !order.isEmpty else { return }
        let index = focus.flatMap { order.firstIndex(of: $0) }
        switch direction {
        case .down: focus = order[min((index ?? -1) + 1, order.count - 1)]
        case .up: focus = order[max((index ?? order.count) - 1, 0)]
        default: break
        }
    }

    private func focusOrder() -> [String] {
        var ids: [String] = []
        if !model.trusted { ids.append("grant") }
        for group in ActionRegistry.grouped() {
            let key = group.category.rawValue
            ids.append("g:\(key)")
            if isOpen(key, group.actions.count <= 8) { ids += group.actions.map { "a:\($0.name)" } }
        }
        let zones = model.customZones
        if !zones.isEmpty {
            ids.append("g:Custom Zones")
            if isOpen("Custom Zones", false) { ids += zones.map { "z:\($0.id)" } }
        }
        let layouts = model.savedLayouts
        if !layouts.isEmpty {
            ids.append("g:Saved Layouts")
            if isOpen("Saved Layouts", false) { ids += layouts.map { "l:\($0.id)" } }
        }
        if model.spaceActionsActive {
            ids.append("g:Move to Space")
            if isOpen("Move to Space", false) { ids += ["s:next", "s:prev"] + (1...9).map { "s:\($0)" } }
        }
        if model.targetApp != nil { ids.append("ignore") }
        ids += ["settings", "updates", "quit"]
        return ids
    }
}

/// One selectable line: title left, shortcut right-aligned. The focused row also answers Return.
private struct MenuRow: View {
    let title: String
    let shortcut: String?
    let symbol: String?
    let isFocused: Bool
    let action: () -> Void
    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack {
                if let symbol { Image(systemName: symbol).frame(width: 18).accessibilityHidden(true) }
                Text(title)
                Spacer(minLength: 12)
                if let shortcut { Text(shortcut).foregroundColor(.secondary).monospacedDigit() }
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .padding(.leading, symbol == nil ? 12 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.accentColor.opacity(isFocused ? 0.30 : (hovering && isEnabled ? 0.15 : 0)))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .accessibilityLabel(shortcut.map { "\(title), shortcut \($0)" } ?? title)
        .background(
            // Return runs the focused row (no onKeyPress before macOS 14).
            Group { if isFocused { Button("", action: action).keyboardShortcut(.return, modifiers: []).opacity(0) } }
        )
    }
}

/// Exposes the hosting `NSWindow` (the popover panel) to SwiftUI.
private struct WindowReader: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onWindow(view.window) }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { onWindow(view.window) }
    }
}
