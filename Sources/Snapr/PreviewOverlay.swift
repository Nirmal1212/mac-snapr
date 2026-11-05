import AppKit
import SnaprCore

/// Translucent, click-through window showing where a dragged window will land.
final class PreviewOverlay {
    private lazy var window: NSWindow = {
        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor
        view.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.8).cgColor
        view.layer?.borderWidth = 2
        view.layer?.cornerRadius = 10
        window.contentView = view
        return window
    }()

    var isVisible: Bool { window.isVisible }

    /// - Parameter frame: target frame in the global top-left/y-down space.
    func show(frame: CGRect) {
        let cocoa = CoordinateSpace.flip(frame, primaryHeight: SystemScreenProvider.primaryHeight)
        window.setFrame(cocoa.insetBy(dx: 4, dy: 4), display: true)
        window.orderFrontRegardless()
    }

    func hide() { window.orderOut(nil) }
}
