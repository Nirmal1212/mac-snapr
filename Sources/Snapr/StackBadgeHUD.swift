import AppKit
import SnaprCore

/// Brief click-through "2/5" badge shown on the front window after cycling a stack.
final class StackBadgeHUD {
    private var hideTask: DispatchWorkItem?

    private lazy var label: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        label.alignment = .center
        return label
    }()

    private lazy var window: NSWindow = {
        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
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

    /// - Parameter frame: the front window's frame in the global top-left/y-down space; the badge sits at its top-right.
    func show(index: Int, count: Int, over frame: CGRect) {
        label.stringValue = "\(index)/\(count)"
        let size = CGSize(width: 64, height: 32)
        label.frame = CGRect(x: 0, y: (size.height - 20) / 2, width: size.width, height: 20)
        let cocoa = CoordinateSpace.flip(frame, primaryHeight: SystemScreenProvider.primaryHeight)
        let origin = CGPoint(x: cocoa.maxX - size.width - 12, y: cocoa.maxY - size.height - 12)
        window.setFrame(CGRect(origin: origin, size: size), display: true)
        window.orderFrontRegardless()
        hideTask?.cancel()
        let task = DispatchWorkItem { [weak self] in self?.window.orderOut(nil) }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: task)
    }
}
