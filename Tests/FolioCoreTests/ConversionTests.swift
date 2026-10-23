import XCTest
import CoreGraphics
import CoreText
import ImageIO
import PDFKit
import UniformTypeIdentifiers
@testable import FolioCore

final class ConversionTests: XCTestCase {
    private var directory: URL!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FolioConversionTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testGeometryUsesDPIAndMarginsWithoutChangingAspectRatio() throws {
        var settings = ConversionSettings()
        settings.useImageDPI = true
        settings.margins = PageMargins(top: 10, bottom: 10, left: 10, right: 10)
        let geometry = try PageGeometry.calculate(pixelWidth: 1200, pixelHeight: 600, imageDPI: 300, settings: settings)
        XCTAssertEqual(geometry.imageRect.width, 288, accuracy: 0.001)
        XCTAssertEqual(geometry.imageRect.height, 144, accuracy: 0.001)
        XCTAssertEqual(geometry.mediaBox.width, 288 + 20 * 72 / 25.4, accuracy: 0.001)
        settings.paperSize = .a4
        settings.enlargeSmallImages = false
        let a4 = try PageGeometry.calculate(pixelWidth: 1200, pixelHeight: 600, imageDPI: 300, settings: settings)
        XCTAssertEqual(a4.imageRect.width, 288, accuracy: 0.001)
        settings.enlargeSmallImages = true
        let enlarged = try PageGeometry.calculate(pixelWidth: 1200, pixelHeight: 600, imageDPI: 300, settings: settings)
        XCTAssertEqual(enlarged.imageRect.width, 190 * 72 / 25.4, accuracy: 0.001)
        XCTAssertEqual(enlarged.imageRect.width / enlarged.imageRect.height, 2, accuracy: 0.001)
    }

    func testGeometryRejectsInvalidMarginsAndDPI() {
        var settings = ConversionSettings()
        settings.dpi = 0
        XCTAssertThrowsError(try PageGeometry.calculate(pixelWidth: 100, pixelHeight: 100, imageDPI: nil, settings: settings))
        settings.dpi = 300
        settings.paperSize = .a4
        settings.margins.left = 300
        XCTAssertThrowsError(try PageGeometry.calculate(pixelWidth: 100, pixelHeight: 100, imageDPI: nil, settings: settings))
    }

    func testImageInspectionAndEXIFRotation() throws {
        let url = directory.appendingPathComponent("rotated.tiff")
        try save([try makeImage(width: 320, height: 180)], to: url, type: UTType.tiff.identifier,
                 properties: [kCGImagePropertyOrientation: 6, kCGImagePropertyDPIWidth: 150, kCGImagePropertyDPIHeight: 150])
        let asset = try ImagePipeline.inspect(url)
        XCTAssertEqual(asset.pixelWidth, 180)
        XCTAssertEqual(asset.pixelHeight, 320)
        XCTAssertEqual(asset.dpi, 150)
        let frame = try ImagePipeline.frame(at: 0, of: url)
        XCTAssertEqual(frame.image.width, 180)
        XCTAssertEqual(frame.image.height, 320)
        let thumbnail = try XCTUnwrap(ImagePipeline.thumbnail(url, maxPixelSize: 80))
        XCTAssertEqual(thumbnail.height, 80)
        XCTAssertTrue(ImagePipeline.supportedExtensions.contains("png"))
    }

    func testConversionCreatesMultipageTIFFAndGIFPagesBookmarksAndMetadata() async throws {
        let tiff = directory.appendingPathComponent("chapter.tiff")
        let gif = directory.appendingPathComponent("animation.gif")
        try save([try makeImage(), try makeImage(width: 300, height: 200)], to: tiff, type: UTType.tiff.identifier)
        try save([try makeImage(), try makeImage()], to: gif, type: UTType.gif.identifier)
        let assets = try [tiff, gif].map(ImagePipeline.inspect)
        XCTAssertEqual(assets.map(\.frameCount), [2, 2])
        var settings = ConversionSettings()
        settings.useInterfaceFile = false
        settings.title = "Test Book"
        settings.author = "Folio Tests"
        let output = directory.appendingPathComponent("book.pdf")
        let result = try await PDFConverter.convert(assets: assets, settings: settings, destination: output) { _ in }
        XCTAssertEqual(result.pageCount, 4)
        XCTAssertEqual(result.outputs, [output])
        let document = try XCTUnwrap(PDFDocument(url: output))
        XCTAssertEqual(document.pageCount, 4)
        XCTAssertEqual(document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String, "Test Book")
        XCTAssertEqual(document.outlineRoot?.numberOfChildren, 2)
        XCTAssertEqual(document.outlineRoot?.child(at: 1)?.label, "animation")
        XCTAssertEqual(document.index(for: try XCTUnwrap(document.outlineRoot?.child(at: 1)?.destination?.page)), 2)
        let cgDocument = try XCTUnwrap(CGPDFDocument(output as CFURL))
        let catalog = try XCTUnwrap(cgDocument.catalog)
        var layout: UnsafePointer<CChar>?
        XCTAssertTrue(CGPDFDictionaryGetName(catalog, "PageLayout", &layout))
        XCTAssertEqual(layout.map(String.init(cString:)), "OneColumn")
    }

    func testOutputDoesNotOverwriteAndPerFolderGroupsOnlyDirectParents() async throws {
        let firstFolder = directory.appendingPathComponent("A")
        let secondFolder = directory.appendingPathComponent("B")
        try FileManager.default.createDirectory(at: firstFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secondFolder, withIntermediateDirectories: true)
        let a = firstFolder.appendingPathComponent("one.png"), b = secondFolder.appendingPathComponent("two.png")
        try save([try makeImage()], to: a)
        try save([try makeImage()], to: b)
        var settings = ConversionSettings()
        settings.useInterfaceFile = false
        let proposed = directory.appendingPathComponent("existing.pdf")
        let original = Data("keep this file".utf8)
        try original.write(to: proposed)
        let assets = try [a, b].map(ImagePipeline.inspect)
        let combined = try await PDFConverter.convert(assets: assets, settings: settings, destination: proposed) { _ in }
        XCTAssertEqual(try Data(contentsOf: proposed), original)
        XCTAssertEqual(combined.outputs.first?.lastPathComponent, "existing (2).pdf")
        settings.outputMode = .perFolder
        let grouped = try await PDFConverter.convert(assets: assets, settings: settings, destination: directory.appendingPathComponent("outputs")) { _ in }
        XCTAssertEqual(grouped.outputs.map(\.lastPathComponent), ["A.pdf", "B.pdf"])
        XCTAssertEqual(grouped.pageCount, 2)
        XCTAssertTrue(grouped.outputs.allSatisfy { PDFDocument(url: $0)?.pageCount == 1 })
    }

    func testBatchFailureReturnsAlreadyPublishedOutputs() async throws {
        let a = directory.appendingPathComponent("First")
        let b = directory.appendingPathComponent("Second")
        try FileManager.default.createDirectory(at: a, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: b, withIntermediateDirectories: true)
        let first = a.appendingPathComponent("one.png"), second = b.appendingPathComponent("two.png")
        try save([try makeImage()], to: first)
        try save([try makeImage()], to: second)
        try Data("[Bkmk]\nBasePage=invalid\n".utf8).write(to: b.appendingPathComponent("FreePic2Pdf.itf"))
        var settings = ConversionSettings()
        settings.outputMode = .perFolder
        let outputs = directory.appendingPathComponent("outputs")
        do {
            _ = try await PDFConverter.convert(assets: try [first, second].map(ImagePipeline.inspect), settings: settings,
                                                destination: outputs) { _ in }
            XCTFail("Invalid second interface should stop the batch")
        } catch let interrupted as ConversionInterrupted {
            XCTAssertFalse(interrupted.isCancelled)
            XCTAssertEqual(interrupted.partialResult.pageCount, 1)
            XCTAssertEqual(interrupted.partialResult.outputs.map(\.lastPathComponent), ["First.pdf"])
            XCTAssertEqual(PDFDocument(url: interrupted.partialResult.outputs[0])?.pageCount, 1)
            XCTAssertTrue(interrupted.underlying is InterfaceError)
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: outputs.path), ["First.pdf"])
    }

    func testJPEGCompressionReallyEmbedsJPEGStream() async throws {
        let input = directory.appendingPathComponent("image.png")
        try save([try makeImage()], to: input)
        var settings = ConversionSettings()
        settings.compression = .jpeg
        settings.preserveTransparency = false
        settings.useInterfaceFile = false
        let result = try await PDFConverter.convert(assets: [try ImagePipeline.inspect(input)], settings: settings,
                                                    destination: directory.appendingPathComponent("jpeg.pdf")) { _ in }
        let bytes = try Data(contentsOf: XCTUnwrap(result.outputs.first))
        XCTAssertTrue(String(decoding: bytes, as: UTF8.self).contains("DCTDecode"))
    }

    func testLosslessUprightJPEGPreservesOriginalDCTStream() async throws {
        let input = directory.appendingPathComponent("original.jpg")
        try save([try makeImage(width: 640, height: 480)], to: input, type: UTType.jpeg.identifier,
                 properties: [kCGImageDestinationLossyCompressionQuality: 0.93])
        let original = try Data(contentsOf: input)
        var settings = ConversionSettings()
        settings.compression = .lossless
        settings.useInterfaceFile = false
        let result = try await PDFConverter.convert(assets: [try ImagePipeline.inspect(input)], settings: settings,
                                                    destination: directory.appendingPathComponent("preserved.pdf")) { _ in }
        let pdf = try Data(contentsOf: result.outputs[0])
        XCTAssertTrue(String(decoding: pdf, as: UTF8.self).contains("DCTDecode"))
        XCTAssertNotNil(pdf.range(of: original), "Lossless mode should retain the original upright JPEG bytes")
    }

    func testVisionOCRCreatesSearchableInvisibleText() async throws {
        let input = directory.appendingPathComponent("ocr.png")
        try save([try makeImage(width: 1500, height: 400, text: "FOLIO SEARCHABLE 2026")], to: input)
        var settings = ConversionSettings()
        settings.ocrEnabled = true
        settings.ocrLanguages = ["en-US"]
        settings.useInterfaceFile = false
        let asset = try ImagePipeline.inspect(input)
        let result = try await PDFConverter.convert(assets: [asset], settings: settings,
                                                    destination: directory.appendingPathComponent("search.pdf")) { _ in }
        XCTAssertTrue(result.warnings.isEmpty, result.warnings.joined(separator: "\n"))
        let searchable = try XCTUnwrap(PDFDocument(url: XCTUnwrap(result.outputs.first)))
        XCTAssertTrue((searchable.string ?? "").contains("SEARCHABLE"), searchable.string ?? "No PDF text")
        settings.ocrEnabled = false
        let plain = try await PDFConverter.convert(assets: [asset], settings: settings,
                                                   destination: directory.appendingPathComponent("plain.pdf")) { _ in }
        XCTAssertEqual(try rasterize(result.outputs[0]), try rasterize(plain.outputs[0]), "OCR must not change visible page pixels")
    }

    func testCancellationLeavesNoTemporaryPDF() async throws {
        let input = directory.appendingPathComponent("image.png")
        try save([try makeImage()], to: input)
        let asset = try ImagePipeline.inspect(input)
        var settings = ConversionSettings()
        settings.useInterfaceFile = false
        let output = directory.appendingPathComponent("cancelled.pdf")
        let task = Task {
            try await PDFConverter.convert(assets: Array(repeating: asset, count: 50), settings: settings, destination: output) { _ in }
        }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Cancelled conversion unexpectedly succeeded")
        } catch is CancellationError { }
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertFalse(files.contains(where: { $0.hasPrefix(".folio-") }))
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
    }

    private func makeImage(width: Int = 240, height: Int = 160, text: String? = nil) throws -> CGImage {
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                             space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        if let text {
            let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 95, nil)
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0, alpha: 1)
            ]))
            context.textPosition = CGPoint(x: 50, y: 160)
            CTLineDraw(line, context)
        } else {
            context.setFillColor(CGColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
        }
        return try XCTUnwrap(context.makeImage())
    }

    private func save(_ images: [CGImage], to url: URL, type: String = UTType.png.identifier,
                      properties: [CFString: Any] = [:]) throws {
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, type as CFString, images.count, nil))
        for image in images { CGImageDestinationAddImage(destination, image, properties as CFDictionary) }
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }

    private func rasterize(_ url: URL) throws -> Data {
        let doc = try XCTUnwrap(CGPDFDocument(url as CFURL))
        let page = try XCTUnwrap(doc.page(at: 1))
        let width = 750, height = 200
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                             space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.concatenate(page.getDrawingTransform(.mediaBox, rect: CGRect(x: 0, y: 0, width: width, height: height), rotate: 0, preserveAspectRatio: true))
        context.drawPDFPage(page)
        return Data(bytes: try XCTUnwrap(context.data), count: width * height * 4)
    }
}
