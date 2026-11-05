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
            MenuPopoverView(model: model)
        } label: {
            if let glyph = Self.menuBarGlyph {
                Image(nsImage: glyph)
            } else {
                Image(systemName: "rectangle.split.2x2")  // e.g. `swift run`: no bundle resources
            }
        }
        .menuBarExtraStyle(.window)
    }
}
