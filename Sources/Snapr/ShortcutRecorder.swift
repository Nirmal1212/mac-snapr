import AppKit
import SnaprCore
import SwiftUI

/// Click-to-record shortcut field. Global hotkeys are suspended while recording.
struct ShortcutRecorder: NSViewRepresentable {
    var combo: KeyCombo?
    var onRecord: (KeyCombo) -> Void

    func makeNSView(context: Context) -> RecorderView {
        let view = RecorderView()
        view.onRecord = onRecord
        return view
    }

    func updateNSView(_ view: RecorderView, context: Context) {
        view.combo = combo
        view.onRecord = onRecord
    }
}

final class RecorderView: NSView {
    var combo: KeyCombo? { didSet { needsDisplay = true } }
    var onRecord: ((KeyCombo) -> Void)?
    private var recording = false {
        didSet {
            needsDisplay = true
            recording ? AppModel.shared.hotkeys.suspend() : AppModel.shared.hotkeys.resume()
        }
    }

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 150, height: 24) }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        recording = true
    }

    override func resignFirstResponder() -> Bool {
        if recording { recording = false }
        return super.resignFirstResponder()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard recording else { return false }
        keyDown(with: event)
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard recording else { return super.keyDown(with: event) }
        if event.keyCode == 53 {  // Escape cancels
            recording = false
            return
        }
        var modifiers: KeyModifiers = []
        let flags = event.modifierFlags
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.command) { modifiers.insert(.command) }
        let candidate = KeyCombo(keyCode: UInt32(event.keyCode), modifiers: modifiers)
        guard candidate.isValidGlobalShortcut else {
            NSSound.beep()
            return
        }
        recording = false
        onRecord?(candidate)
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 5, yRadius: 5)
        (recording ? NSColor.controlAccentColor.withAlphaComponent(0.15) : NSColor.controlBackgroundColor).setFill()
        path.fill()
        (recording ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        path.stroke()
        let text = recording ? "Type shortcut…" : (combo?.displayString ?? "Not set")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: (combo == nil && !recording) ? NSColor.secondaryLabelColor : NSColor.labelColor
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: NSPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2), withAttributes: attributes)
    }
}
