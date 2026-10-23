import AppKit
import Foundation

let destination = URL(fileURLWithPath: CommandLine.arguments[1])
if FileManager.default.fileExists(atPath: destination.path) { try FileManager.default.removeItem(at: destination) }
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
for size in [16, 32, 64, 128, 256, 512, 1024] {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let context = NSGraphicsContext.current!.cgContext
    context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    let background = NSBezierPath(roundedRect: CGRect(x: 76, y: 76, width: 872, height: 872), xRadius: 196, yRadius: 196)
    NSGradient(starting: NSColor(red: 0.39, green: 0.36, blue: 0.91, alpha: 1), ending: NSColor(red: 0.23, green: 0.19, blue: 0.59, alpha: 1))!.draw(in: background, angle: -50)
    context.saveGState()
    context.translateBy(x: 435, y: 486); context.rotate(by: 0.19)
    NSColor.white.withAlphaComponent(0.30).setFill()
    NSBezierPath(roundedRect: CGRect(x: -200, y: -270, width: 400, height: 540), xRadius: 36, yRadius: 36).fill()
    context.restoreGState()
    context.saveGState()
    context.translateBy(x: 565, y: 535); context.rotate(by: -0.12)
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 32, color: NSColor.black.withAlphaComponent(0.18).cgColor)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: CGRect(x: -200, y: -270, width: 400, height: 540), xRadius: 36, yRadius: 36).fill()
    context.setShadow(offset: .zero, blur: 0)
    NSColor(red: 0.37, green: 0.34, blue: 0.85, alpha: 1).setFill()
    let star = NSBezierPath(); star.move(to: CGPoint(x: 0, y: 115)); star.curve(to: CGPoint(x: 90, y: 25), controlPoint1: CGPoint(x: 15, y: 42), controlPoint2: CGPoint(x: 20, y: 40)); star.curve(to: CGPoint(x: 0, y: -65), controlPoint1: CGPoint(x: 20, y: 10), controlPoint2: CGPoint(x: 15, y: 5)); star.curve(to: CGPoint(x: -90, y: 25), controlPoint1: CGPoint(x: -15, y: 5), controlPoint2: CGPoint(x: -20, y: 10)); star.curve(to: CGPoint(x: 0, y: 115), controlPoint1: CGPoint(x: -20, y: 40), controlPoint2: CGPoint(x: -15, y: 42)); star.fill()
    NSColor(red: 0.78, green: 0.77, blue: 0.91, alpha: 1).setFill()
    NSBezierPath(roundedRect: CGRect(x: -105, y: -150, width: 210, height: 17), xRadius: 8, yRadius: 8).fill()
    NSBezierPath(roundedRect: CGRect(x: -105, y: -193, width: 145, height: 17), xRadius: 8, yRadius: 8).fill()
    context.restoreGState()
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    if [16, 32, 128, 256, 512].contains(size) { try data.write(to: destination.appendingPathComponent("icon_\(size)x\(size).png")) }
    if [32, 64, 256, 512, 1024].contains(size) { try data.write(to: destination.appendingPathComponent("icon_\(size/2)x\(size/2)@2x.png")) }
}
