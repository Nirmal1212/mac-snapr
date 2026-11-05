import AppKit
import CoreServices
import SnaprCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Registered before launch completes so a URL that launched the app is not lost.
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let string = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
            let url = URL(string: string)
        else { return }
        AppModel.shared.handle(url: url)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar only, also when run via `swift run` (the packaged app sets LSUIElement).
        NSApp.setActivationPolicy(.accessory)
        AppModel.shared.start()
    }
}

@main
struct SnaprApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel.shared

    /// Template glyph from Contents/Resources (picks up @2x automatically); nil outside the packaged app.
    private static let menuBarGlyph: NSImage? = {
        let image = NSImage(named: "MenuBarIconTemplate")
        image?.isTemplate = true
        return image
    }()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            if let glyph = Self.menuBarGlyph {
                Image(nsImage: glyph)
            } else {
                Image(systemName: "rectangle.split.2x2")  // e.g. `swift run`: no bundle resources
            }
        }
    }
}

struct MenuContent: View {
    @ObservedObject var model: AppModel

    var body: some View {
        if !model.trusted {
            Button("Grant Accessibility Access…") { model.showOnboarding() }
            Divider()
        }
        ForEach(ActionRegistry.grouped(), id: \.category) { group in
            if group.actions.count > 8 {
                Menu(group.category.rawValue) { actionButtons(group.actions) }
            } else {
                actionButtons(group.actions)
                Divider()
            }
        }
        customLayoutMenus
        if let app = model.targetApp {
            Button(model.targetAppIgnored ? "Stop Ignoring \(app.name)" : "Ignore \(app.name)") {
                model.toggleIgnoreTargetApp()
            }
            Divider()
        }
        Button("Settings…") { model.showSettings() }
            .keyboardShortcut(",")
        Button("Check for Updates…") { model.updater.checkForUpdates() }
            .disabled(!model.updater.isAvailable)
        Button("Quit Snapr") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }

    // MARK: add-custom-layouts-and-spaces

    @ViewBuilder
    private var customLayoutMenus: some View {
        let zones = model.customZones
        let layouts = model.savedLayouts
        if !zones.isEmpty {
            Menu("Custom Zones") {
                ForEach(zones) { zone in
                    Button(runtimeLabel(zone.name, zone.shortcut)) { model.perform(zone.action) }
                }
            }
        }
        if !layouts.isEmpty {
            Menu("Saved Layouts") {
                ForEach(layouts) { layout in
                    Button(runtimeLabel(layout.name, layout.shortcut)) { model.perform(layout.action) }
                }
            }
        }
        if model.spaceActionsActive {
            Menu("Move to Space") {
                Button("Next Space") { model.perform(.space(.next)) }
                Button("Previous Space") { model.perform(.space(.previous)) }
                ForEach(1...9, id: \.self) { n in
                    Button("Space \(n)") { model.perform(.space(.index(n))) }
                }
            }
        }
        if !zones.isEmpty || !layouts.isEmpty || model.spaceActionsActive { Divider() }
    }

    private func runtimeLabel(_ title: String, _ combo: KeyCombo?) -> String {
        combo.map { "\(title)    \($0.displayString)" } ?? title
    }

    @ViewBuilder
    private func actionButtons(_ actions: [SnapAction]) -> some View {
        ForEach(actions, id: \.self) { action in
            Button(label(for: action)) { model.perform(action) }
        }
    }

    private func label(for action: SnapAction) -> String {
        guard let combo = model.settings.get(.shortcuts).combo(for: action) else { return action.title }
        return "\(action.title)    \(combo.displayString)"
    }
}
