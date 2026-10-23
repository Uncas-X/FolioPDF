import XCTest
import CoreGraphics
import ImageIO
import PDFKit
import UniformTypeIdentifiers
@testable import FolioCore

/// Real, independently encoded JPEG XL files exercise Apple's decoder. Fixtures
/// are synthetic and bundled with the tests: no encoder or network is needed.
final class JPEGXLTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FolioJPEGXLTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testJPEGXLTypeFilteringAndRecursiveDiscovery() throws {
        XCTAssertTrue((CGImageSourceCopyTypeIdentifiers() as! [String]).contains("public.jpeg-xl"))
        XCTAssertTrue(ImagePipeline.supportedExtensions.contains("jxl"))
        let filter = try XCTUnwrap(ImagePipeline.importContentTypes.first {
            $0.tags[.filenameExtension, default: []].contains("jxl")
        })
        XCTAssertTrue(filter.conforms(to: .image))
        XCTAssertEqual(filter.preferredFilenameExtension, "jxl")
        XCTAssertTrue(ImagePipeline.importContentTypes.contains(.image))

        let nested = directory.appendingPathComponent("Chapter")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let cover = directory.appendingPathComponent("cover.JXL")
        let page = nested.appendingPathComponent("page.jxl")
        try FileManager.default.copyItem(at: fixture("rgb-lossless"), to: cover)
        try FileManager.default.copyItem(at: fixture("rgba-lossless"), to: page)
        try Data("notes".utf8).write(to: nested.appendingPathComponent("notes.txt"))
        // Directory enumeration may spell the system temp directory as /private/var
        // rather than /var; filenames and count test discovery without that alias.
        XCTAssertEqual(try AssetLibrary.discover(in: [directory], recursive: false).map(\.lastPathComponent), ["cover.JXL"])
        XCTAssertEqual(try AssetLibrary.discover(in: [directory], recursive: true, includeRoot: false).map(\.lastPathComponent), ["page.jxl"])
        let all = try AssetLibrary.discover(in: [directory, page], recursive: true)
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(Set(all.map(\.lastPathComponent)), Set(["cover.JXL", "page.jxl"]))
        XCTAssertEqual(try AssetLibrary.discover(in: [cover], recursive: false), [cover])
    }

    func testLossyAndLosslessRGBInspectionThumbnailsAndFullSizePreview() throws {
        for name in ["rgb-lossless", "rgb-lossy"] {
            let url = try fixture(name)
            let bytes = try Data(contentsOf: url)
            // Both the raw codestream and standard container are genuine JXL data.
            XCTAssertTrue(bytes.starts(with: [0xFF, 0x0A]) || bytes.starts(with: [0, 0, 0, 12, 0x4A, 0x58, 0x4C, 0x20]))
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
            XCTAssertEqual(CGImageSourceGetType(source) as String?, "public.jpeg-xl")
            let asset = try ImagePipeline.inspect(url)
            XCTAssertEqual(asset.pixelWidth, 80)
            XCTAssertEqual(asset.pixelHeight, 48)
            XCTAssertEqual(asset.frameCount, 1)
            XCTAssertEqual(asset.fileSize, Int64(bytes.count))
            let small = try XCTUnwrap(ImagePipeline.thumbnail(url, maxPixelSize: 40))
            XCTAssertEqual(small.width, 40)
            XCTAssertEqual(small.height, 24)
            let preview = try XCTUnwrap(ImagePipeline.thumbnail(url, maxPixelSize: 1800))
            XCTAssertEqual(preview.width, 80)
            XCTAssertEqual(preview.height, 48)
            let frame = try ImagePipeline.frame(at: 0, of: url).image
            XCTAssertEqual(frame.width, 80)
            XCTAssertEqual(frame.height, 48)
            let pixels = try rasterize(frame)
            assertPixel(pixels, x: 20, y: 12, equals: [255, 0, 0, 255], tolerance: 12)
            assertPixel(pixels, x: 60, y: 12, equals: [0, 255, 0, 255], tolerance: 12)
            assertPixel(pixels, x: 20, y: 36, equals: [0, 0, 255, 255], tolerance: 12)
            assertPixel(pixels, x: 60, y: 36, equals: [255, 255, 0, 255], tolerance: 12)
        }
    }

    func testTransparentJPEGXLPreservesAlphaDuringDecodeAndPreview() throws {
        let url = try fixture("rgba-lossless")
        let frame = try ImagePipeline.frame(at: 0, of: url).image
        XCTAssertTrue([CGImageAlphaInfo.first, .last, .premultipliedFirst, .premultipliedLast].contains(frame.alphaInfo))
        for image in [frame, try XCTUnwrap(ImagePipeline.thumbnail(url, maxPixelSize: 1800))] {
            let pixels = try rasterize(image)
            assertPixel(pixels, x: 20, y: 12, equals: [255, 0, 0, 255], tolerance: 1)
            assertPixel(pixels, x: 60, y: 12, equals: [0, 128, 0, 128], tolerance: 1)
            assertPixel(pixels, x: 20, y: 36, equals: [0, 0, 64, 64], tolerance: 1)
            assertPixel(pixels, x: 60, y: 36, equals: [0, 0, 0, 0], tolerance: 1)
        }
    }

    func testSixteenBitGrayscaleJPEGXLDecodesWithoutDroppingPixelDimensions() throws {
        let url = try fixture("gray16")
        let asset = try ImagePipeline.inspect(url)
        let frame = try ImagePipeline.frame(at: 0, of: url).image
        XCTAssertEqual(asset.pixelWidth, 80)
        XCTAssertEqual(asset.pixelHeight, 48)
        XCTAssertEqual(frame.bitsPerComponent, 16)
        XCTAssertEqual(frame.colorSpace?.model, .monochrome)
        let pixels = try rasterize(frame)
        assertPixel(pixels, x: 0, y: 24, equals: [0, 0, 0, 255], tolerance: 1)
        assertPixel(pixels, x: 79, y: 24, equals: [255, 255, 255, 255], tolerance: 1)
        let small = try XCTUnwrap(ImagePipeline.thumbnail(url, maxPixelSize: 40))
        XCTAssertEqual(small.width, 40)
        XCTAssertEqual(small.height, 24)
    }

    func testJPEGXLConversionPreservesPageSizesAndDecodedContent() async throws {
        let urls = try ["rgb-lossless", "rgb-lossy", "gray16"].map(fixture)
        let assets = try urls.map(ImagePipeline.inspect)
        let destination = directory.appendingPathComponent("jxl-book.pdf")
        let result = try await PDFConverter.convert(assets: assets, settings: settings(), destination: destination) { _ in }
        XCTAssertEqual(result.outputs, [destination])
        XCTAssertEqual(result.pageCount, 3)
        XCTAssertTrue(result.warnings.isEmpty)
        let pdf = try XCTUnwrap(CGPDFDocument(destination as CFURL))
        let document = try XCTUnwrap(PDFDocument(url: destination))
        XCTAssertEqual(pdf.numberOfPages, 3)
        XCTAssertEqual(document.outlineRoot?.numberOfChildren, 3)
        for (index, url) in urls.enumerated() {
            let page = try XCTUnwrap(pdf.page(at: index + 1))
            XCTAssertEqual(page.getBoxRect(.mediaBox), CGRect(x: 0, y: 0, width: 80, height: 48))
            let rendered = try rasterize(page)
            let original = try rasterize(ImagePipeline.frame(at: 0, of: url).image)
            for (x, y) in [(20, 12), (60, 12), (20, 36), (60, 36)] {
                assertPixel(rendered, x: x, y: y, equals: pixel(original, x: x, y: y), tolerance: 3)
            }
        }
    }

    func testJPEGXLTransparencyInPDFAndJPEGFallback() async throws {
        let asset = try ImagePipeline.inspect(fixture("rgba-lossless"))
        for (name, preserve, compression) in [("transparent", true, ImageCompression.lossless),
                                                ("white", false, .lossless), ("jpeg-alpha", true, .jpeg)] {
            var options = settings()
            options.preserveTransparency = preserve
            options.compression = compression
            let destination = directory.appendingPathComponent("\(name).pdf")
            let result = try await PDFConverter.convert(assets: [asset], settings: options, destination: destination) { _ in }
            XCTAssertEqual(result.pageCount, 1)
            XCTAssertEqual(result.warnings.count, compression == .jpeg ? 1 : 0)
            if compression == .jpeg { XCTAssertTrue(result.warnings[0].contains("preserve transparency")) }
            let pdf = try XCTUnwrap(CGPDFDocument(destination as CFURL))
            let page = try XCTUnwrap(pdf.page(at: 1))
            let pixels = try rasterize(page)
            assertPixel(pixels, x: 20, y: 12, equals: [255, 0, 0, 255], tolerance: 2)
            assertPixel(pixels, x: 60, y: 12, equals: preserve ? [0, 128, 0, 128] : [127, 255, 127, 255], tolerance: 2)
            assertPixel(pixels, x: 60, y: 36, equals: preserve ? [0, 0, 0, 0] : [255, 255, 255, 255], tolerance: 1)
        }
    }

    func testAnimatedJPEGXLExportsOnlyFramesExposedByImageIO() async throws {
        // This fixture contains two independently verified libjxl frames. macOS
        // 15.7.9 exposes only the first; no third-party animation decoder is used.
        let url = try fixture("animation")
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        let nativeCount = CGImageSourceGetCount(source)
        XCTAssertTrue((1...2).contains(nativeCount))
        let asset = try ImagePipeline.inspect(url)
        XCTAssertEqual(asset.frameCount, nativeCount)
        let first = try rasterize(ImagePipeline.frame(at: 0, of: url).image)
        assertPixel(first, x: 20, y: 12, equals: [255, 0, 0, 255], tolerance: 1)
        let destination = directory.appendingPathComponent("animation.pdf")
        let result = try await PDFConverter.convert(assets: [asset], settings: settings(), destination: destination) { _ in }
        XCTAssertEqual(result.pageCount, nativeCount)
        let pdf = try XCTUnwrap(CGPDFDocument(destination as CFURL))
        XCTAssertEqual(pdf.numberOfPages, nativeCount)
        let page = try XCTUnwrap(pdf.page(at: 1))
        assertPixel(try rasterize(page), x: 20, y: 12, equals: [255, 0, 0, 255], tolerance: 2)
        XCTAssertThrowsError(try ImagePipeline.frame(at: nativeCount, of: url))
        XCTAssertThrowsError(try ImagePipeline.frame(at: -1, of: url))
    }

    func testDamagedOrMissingJPEGXLIsRejectedWithoutPublishingPDF() async throws {
        let invalid = directory.appendingPathComponent("invalid.jxl")
        let truncated = directory.appendingPathComponent("truncated.jxl")
        let missing = directory.appendingPathComponent("missing.jxl")
        try Data("This is not JPEG XL.".utf8).write(to: invalid)
        try Data(contentsOf: fixture("rgb-lossless")).prefix(10).write(to: truncated)
        for url in [invalid, truncated, missing] {
            XCTAssertNil(ImagePipeline.thumbnail(url))
            let proposed = directory.appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".pdf")
            // Conversion validates the source again even if a stale asset exists.
            let stale = ImageAsset(url: url, pixelWidth: 80, pixelHeight: 48)
            do {
                _ = try await PDFConverter.convert(assets: [stale], settings: settings(), destination: proposed) { _ in }
                XCTFail("A damaged or missing JPEG XL file must not be exported")
            } catch {
                XCTAssertTrue(error is ConversionError)
                XCTAssertTrue(error.localizedDescription.contains(url.lastPathComponent))
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: proposed.path))
        }
        let remaining = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertFalse(remaining.contains { $0.pathExtension == "pdf" || $0.lastPathComponent.hasPrefix(".folio-") })
    }

    private func fixture(_ name: String) throws -> URL {
        try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "jxl", subdirectory: "Fixtures/JPEGXL"))
    }

    private func settings() -> ConversionSettings {
        var result = ConversionSettings()
        result.dpi = 72
        result.useImageDPI = false
        result.useInterfaceFile = false
        result.paperSize = .image
        result.compression = .lossless
        return result
    }

    private func rasterize(_ image: CGImage) throws -> [UInt8] {
        try rasterize(width: image.width, height: image.height) { context in
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
    }

    private func rasterize(_ page: CGPDFPage) throws -> [UInt8] {
        let size = page.getBoxRect(.mediaBox).size
        return try rasterize(width: Int(size.width), height: Int(size.height)) { $0.drawPDFPage(page) }
    }

    private func rasterize(width: Int, height: Int, draw: (CGContext) -> Void) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let colorSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: width, height: height,
                                                  bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace,
                                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
            context.interpolationQuality = .none
            draw(context)
        }
        return bytes
    }

    private func pixel(_ pixels: [UInt8], x: Int, y: Int) -> [UInt8] {
        let offset = (y * 80 + x) * 4
        return Array(pixels[offset..<(offset + 4)])
    }

    private func assertPixel(_ pixels: [UInt8], x: Int, y: Int, equals expected: [UInt8], tolerance: Int,
                             file: StaticString = #filePath, line: UInt = #line) {
        let actual = pixel(pixels, x: x, y: y)
        for (value, target) in zip(actual, expected) {
            XCTAssertLessThanOrEqual(abs(Int(value) - Int(target)), tolerance,
                                     "Pixel (\(x), \(y)): \(actual), expected \(expected)", file: file, line: line)
        }
    }
}
