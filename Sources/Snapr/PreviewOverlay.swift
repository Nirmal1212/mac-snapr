import AppKit
import SnaprCore

/// Translucent, click-through window showing where a dragged window will land.
final class PreviewOverlay {
    private(set) var style = FootprintStyle()

    private lazy var window: NSWindow = {
        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.contentView = makeContentView()
        return window
    }()

    var isVisible: Bool { window.isVisible }

    /// Applies a new footprint look (takes effect the next time the overlay is shown).
    func apply(_ style: FootprintStyle) {
        guard style != self.style else { return }
        self.style = style
        window.contentView = makeContentView()
    }

    /// - Parameter frame: target frame in the global top-left/y-down space.
    func show(frame: CGRect) {
        let cocoa = CoordinateSpace.flip(frame, primaryHeight: SystemScreenProvider.primaryHeight)
        window.setFrame(cocoa.insetBy(dx: 4, dy: 4), display: true)
        window.orderFrontRegardless()
    }

    func hide() { window.orderOut(nil) }

    private func makeContentView() -> NSView {
        let base: NSColor
        if let c = style.color, c.count >= 3 {
            base = NSColor(srgbRed: c[0], green: c[1], blue: c[2], alpha: 1)
        } else {
            base = .controlAccentColor
        }
        let view: NSView
        if style.blur {
            let effect = NSVisualEffectView()
            effect.material = .hudWindow
            effect.blendingMode = .behindWindow
            effect.state = .active
            effect.alphaValue = CGFloat(min(1, max(0.1, style.alpha * 3)))
            view = effect
        } else {
            view = NSView()
        }
        view.wantsLayer = true
        if !style.blur { view.layer?.backgroundColor = base.withAlphaComponent(CGFloat(style.alpha)).cgColor }
        view.layer?.borderColor = base.withAlphaComponent(0.8).cgColor
        view.layer?.borderWidth = CGFloat(style.borderWidth)
        view.layer?.cornerRadius = 10
        view.layer?.masksToBounds = true
        return view
    }
}
