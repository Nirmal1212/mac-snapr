// Usage: swift scripts/render-svg.swift input.svg output.png pixelSize
// Renders an SVG to a square PNG (transparent background) using AppKit's SVG support (macOS 13+).
import AppKit

let a = CommandLine.arguments
guard a.count >= 4, let size = Int(a[3]), let img = NSImage(contentsOf: URL(fileURLWithPath: a[1])) else {
    FileHandle.standardError.write(Data("usage: render-svg in.svg out.png size\n".utf8))
    exit(1)
}
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: size, height: size)
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
ctx.imageInterpolation = .high
img.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[2]))
