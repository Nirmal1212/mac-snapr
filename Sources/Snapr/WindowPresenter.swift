import AppKit
import SwiftUI

/// Hosts a SwiftUI view in a reusable titled window (menu bar apps have no scene windows to lean on).
final class WindowPresenter {
    private var window: NSWindow?

    func show<Content: View>(
        title: String, size: CGSize, minSize: CGSize? = nil, @ViewBuilder content: () -> Content
    ) {
        if window == nil {
            let created = NSWindow(
                contentRect: CGRect(origin: .zero, size: size),
                styleMask: minSize == nil ? [.titled, .closable] : [.titled, .closable, .resizable],
                backing: .buffered, defer: false)
            if let minSize { created.contentMinSize = minSize }
            created.title = title
            created.isReleasedWhenClosed = false
            created.contentView = NSHostingView(rootView: content())
            created.center()
            window = created
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
        window = nil
    }
}
