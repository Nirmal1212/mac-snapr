import SwiftUI
import ApplicationServices

@main
struct SnaprApp: App {
    @State private var trusted = AXIsProcessTrusted()

    var body: some Scene {
        MenuBarExtra("Snapr", systemImage: "rectangle.split.2x2") {
            Text(trusted ? "Accessibility: enabled" : "Accessibility: not granted")
            if !trusted {
                Button("Grant Accessibility Access…") {
                    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                    trusted = AXIsProcessTrustedWithOptions(opts)
                }
            }
            Divider()
            Button("Quit Snapr") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
