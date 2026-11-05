import AppKit
import SnaprCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
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

    var body: some Scene {
        MenuBarExtra("Snapr", systemImage: "rectangle.split.2x2") {
            MenuContent(model: model)
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
            ForEach(group.actions, id: \.self) { action in
                Button(label(for: action)) { model.perform(action) }
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

    private func label(for action: SnapAction) -> String {
        guard let combo = model.settings.get(.shortcuts).combo(for: action) else { return action.title }
        return "\(action.title)    \(combo.displayString)"
    }
}
