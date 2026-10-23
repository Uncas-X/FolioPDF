import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let directory = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
let titles = ["Field notes", "A slower morning", "The small details", "Places to return"]
for (index, title) in titles.enumerated() {
    let width = 900, height = 1200
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.setFillColor(CGColor(red: 0.98, green: 0.975, blue: 0.955, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    func text(_ string: String, x: Double, y: Double, size: Double, color: CGColor, font: String = "Helvetica") {
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName(font as CFString, size, nil), NSAttributedString.Key(kCTForegroundColorAttributeName as String): color]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes))
        context.textPosition = CGPoint(x: x, y: y); CTLineDraw(line, context)
    }
    let ink = CGColor(red: 0.17, green: 0.22, blue: 0.2, alpha: 1)
    let green = CGColor(red: 0.32, green: 0.47, blue: 0.4, alpha: 1)
    text("THE EVERYDAY ARCHIVE", x: 75, y: 1080, size: 17, color: green)
    text(title, x: 75, y: 960, size: index == 0 ? 85 : 54, color: ink, font: "Georgia")
    text("Observations from a quiet city", x: 78, y: 905, size: 22, color: green)
    context.setFillColor(CGColor(red: 0.83 - Double(index)*0.025, green: 0.87, blue: 0.8 + Double(index)*0.025, alpha: 1)); context.fill(CGRect(x: 75, y: 380, width: 750, height: 440))
    context.setStrokeColor(green); context.setLineWidth(3)
    for offset in 0..<9 {
        let y = Double(420 + offset * 38)
        context.move(to: CGPoint(x: 105, y: y)); context.addCurve(to: CGPoint(x: 795, y: y + 28), control1: CGPoint(x: 310, y: y + 80 + Double(index * 10)), control2: CGPoint(x: 570, y: y - 60)); context.strokePath()
    }
    text("There is a story in the things we notice.", x: 75, y: 300, size: 23, color: ink)
    text("Collect the pages. Keep the details. Find your way back.", x: 75, y: 256, size: 18, color: green)
    text("FOLIOPDF  /  SAMPLE COLLECTION", x: 75, y: 95, size: 13, color: green)
    text(String(format: "%02d", index + 1), x: 790, y: 95, size: 18, color: green)
    let url = directory.appendingPathComponent(String(format: "%02d-%@.png", index + 1, title.lowercased().replacingOccurrences(of: " ", with: "-")))
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, context.makeImage()!, [kCGImagePropertyDPIWidth:300, kCGImagePropertyDPIHeight:300] as CFDictionary)
    guard CGImageDestinationFinalize(dest) else { fatalError("Could not save fixture") }
}
