import AppKit
import SnaprCore

/// Brief click-through "Minimum size reached" message shown over a window that could not shrink or fit.
final class MinimumSizeHUD {
    private var hideTask: DispatchWorkItem?

    private lazy var label: NSTextField = {
        let label = NSTextField(labelWithString: "Minimum size reached")
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.alignment = .center
        return label
    }()

    private lazy var window: NSWindow = {
        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.ignoresMouseEvents = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.75).cgColor
        view.layer?.cornerRadius = 10
        window.contentView = view
        view.addSubview(label)
        return window
    }()

    /// - Parameter frame: the window's frame in the global top-left/y-down space; the HUD is centered on it.
    func show(near frame: CGRect) {
        let size = CGSize(width: 190, height: 38)
        label.frame = CGRect(x: 0, y: (size.height - 18) / 2, width: size.width, height: 18)
        let cocoa = CoordinateSpace.flip(frame, primaryHeight: SystemScreenProvider.primaryHeight)
        let origin = CGPoint(x: cocoa.midX - size.width / 2, y: cocoa.midY - size.height / 2)
        window.setFrame(CGRect(origin: origin, size: size), display: true)
        window.orderFrontRegardless()
        hideTask?.cancel()
        let task = DispatchWorkItem { [weak self] in self?.window.orderOut(nil) }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: task)
    }
}
