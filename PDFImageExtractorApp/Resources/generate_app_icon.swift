import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("AppIcon.iconset", isDirectory: true)
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func savePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "FigraIcon", code: 1)
    }
    try png.write(to: url)
}

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    bounds.fill()

    let scale = size / 1024.0
    let outer = bounds.insetBy(dx: 84 * scale, dy: 84 * scale)
    let outerPath = NSBezierPath(roundedRect: outer, xRadius: 220 * scale, yRadius: 220 * scale)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.16, green: 0.50, blue: 0.96, alpha: 1),
        NSColor(calibratedRed: 0.08, green: 0.66, blue: 0.72, alpha: 1)
    ])!
    gradient.draw(in: outerPath, angle: 42)

    NSColor.white.withAlphaComponent(0.22).setStroke()
    outerPath.lineWidth = 8 * scale
    outerPath.stroke()

    let sheet = NSRect(x: 286 * scale, y: 258 * scale, width: 452 * scale, height: 516 * scale)
    let sheetPath = NSBezierPath(roundedRect: sheet, xRadius: 58 * scale, yRadius: 58 * scale)
    NSColor.white.withAlphaComponent(0.96).setFill()
    sheetPath.fill()

    NSColor(calibratedRed: 0.10, green: 0.36, blue: 0.78, alpha: 1).withAlphaComponent(0.18).setFill()
    NSBezierPath(roundedRect: NSRect(x: 336 * scale, y: 642 * scale, width: 250 * scale, height: 34 * scale), xRadius: 17 * scale, yRadius: 17 * scale).fill()
    NSBezierPath(roundedRect: NSRect(x: 336 * scale, y: 584 * scale, width: 310 * scale, height: 34 * scale), xRadius: 17 * scale, yRadius: 17 * scale).fill()

    let figureRect = NSRect(x: 336 * scale, y: 346 * scale, width: 352 * scale, height: 184 * scale)
    let figurePath = NSBezierPath(roundedRect: figureRect, xRadius: 34 * scale, yRadius: 34 * scale)
    NSColor(calibratedRed: 0.07, green: 0.57, blue: 0.62, alpha: 1).withAlphaComponent(0.18).setFill()
    figurePath.fill()

    NSColor(calibratedRed: 0.10, green: 0.36, blue: 0.78, alpha: 1).withAlphaComponent(0.80).setStroke()
    figurePath.lineWidth = 10 * scale
    figurePath.stroke()

    let mountain = NSBezierPath()
    mountain.move(to: NSPoint(x: 368 * scale, y: 386 * scale))
    mountain.line(to: NSPoint(x: 462 * scale, y: 480 * scale))
    mountain.line(to: NSPoint(x: 536 * scale, y: 418 * scale))
    mountain.line(to: NSPoint(x: 598 * scale, y: 474 * scale))
    mountain.line(to: NSPoint(x: 660 * scale, y: 386 * scale))
    mountain.close()
    NSColor(calibratedRed: 0.10, green: 0.36, blue: 0.78, alpha: 1).setFill()
    mountain.fill()

    NSColor(calibratedRed: 0.08, green: 0.66, blue: 0.72, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 382 * scale, y: 456 * scale, width: 44 * scale, height: 44 * scale)).fill()

    let mark = NSBezierPath()
    mark.lineWidth = 28 * scale
    mark.lineCapStyle = .round
    mark.lineJoinStyle = .round
    mark.move(to: NSPoint(x: 298 * scale, y: 786 * scale))
    mark.line(to: NSPoint(x: 228 * scale, y: 786 * scale))
    mark.line(to: NSPoint(x: 228 * scale, y: 716 * scale))
    mark.move(to: NSPoint(x: 726 * scale, y: 238 * scale))
    mark.line(to: NSPoint(x: 796 * scale, y: 238 * scale))
    mark.line(to: NSPoint(x: 796 * scale, y: 308 * scale))
    NSColor.white.setStroke()
    mark.stroke()

    image.unlockFocus()
    return image
}

let outputs: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in outputs {
    try savePNG(drawIcon(size: size), to: iconset.appendingPathComponent(name))
}
