import XCTest
import Foundation
import CoreGraphics
import CoreText
import ImageIO
import PDFKit
import UniformTypeIdentifiers
@testable import FolioCore

/// End-to-end coverage for encryption at the converter's publication boundary.
/// Fixtures and passwords are synthetic; tests never read or modify user documents.
final class EncryptedConversionTests: XCTestCase {
    private var directory: URL!
    private let password = "Folio-test-open-2026!"

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FolioEncryptedConversionTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory, FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
    }

    func testCombinedPDFRequiresPasswordAndPreservesMetadataAndBookmarks() async throws {
        let first = directory.appendingPathComponent("Chapter One.png")
        let second = directory.appendingPathComponent("Chapter Two.png")
        try saveImage(makeImage(), to: first)
        try saveImage(makeImage(width: 320, height: 240), to: second)
        let originalBytes = try [first, second].map { try Data(contentsOf: $0) }
        var settings = ConversionSettings()
        settings.useInterfaceFile = false
        settings.addFileBookmarks = true
        settings.title = "Encrypted book 扫描册"
        settings.author = "Folio Integration Tests"
        settings.subject = "Encrypted metadata survives conversion"
        settings.keywords = "archive, encrypted"
        let output = directory.appendingPathComponent("protected.pdf")
        let result = try await PDFConverter.convert(assets: try [first, second].map(ImagePipeline.inspect), settings: settings,
                                                    destination: output, encryption: PDFEncryptionOptions(password: password)) { _ in }
        XCTAssertEqual(result.outputs, [output])
        XCTAssertEqual(result.pageCount, 2)
        XCTAssertTrue(result.warnings.isEmpty, result.warnings.joined(separator: "\n"))
        let document = try assertPasswordRequired(output)
        XCTAssertEqual(document.pageCount, 2)
        XCTAssertEqual(document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String, settings.title)
        XCTAssertEqual(document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String, settings.author)
        XCTAssertEqual(document.documentAttributes?[PDFDocumentAttribute.subjectAttribute] as? String, settings.subject)
        let keywordValue = document.documentAttributes?[PDFDocumentAttribute.keywordsAttribute]
        let keywords = (keywordValue as? [String])?.joined(separator: ",") ?? (keywordValue as? String ?? "")
        XCTAssertTrue(keywords.contains("archive"), "PDF keywords were lost during encryption")
        XCTAssertTrue(keywords.contains("encrypted"), "PDF keywords were lost during encryption")
        let bookmarks = BookmarkService.read(from: document)
        XCTAssertEqual(bookmarks.map(\.title), ["Chapter One", "Chapter Two"])
        XCTAssertEqual(bookmarks.map(\.pageIndex), [0, 1])
        XCTAssertEqual(try [first, second].map { try Data(contentsOf: $0) }, originalBytes)
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: directory.path)),
                       Set([first.lastPathComponent, second.lastPathComponent, output.lastPathComponent]))
    }

    func testPerFileEncryptsEveryOutputWithoutReplacingSameNamedFile() async throws {
        let firstFolder = directory.appendingPathComponent("A")
        let secondFolder = directory.appendingPathComponent("B")
        let outputs = directory.appendingPathComponent("outputs")
        for folder in [firstFolder, secondFolder, outputs] {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let first = firstFolder.appendingPathComponent("chapter.png")
        let second = secondFolder.appendingPathComponent("chapter.png")
        try saveImage(makeImage(), to: first)
        try saveImage(makeImage(width: 300, height: 200), to: second)
        let existing = outputs.appendingPathComponent("chapter.pdf")
        let original = Data("Existing file must never be replaced by encryption".utf8)
        try original.write(to: existing)
        var settings = ConversionSettings()
        settings.outputMode = .perFile
        settings.useInterfaceFile = false
        let result = try await PDFConverter.convert(assets: try [first, second].map(ImagePipeline.inspect), settings: settings,
                                                    destination: outputs, encryption: PDFEncryptionOptions(password: password)) { _ in }
        XCTAssertEqual(result.outputs.count, 2)
        XCTAssertEqual(result.pageCount, 2)
        XCTAssertEqual(Set(result.outputs.map(\.lastPathComponent)), Set(["chapter (2).pdf", "chapter (3).pdf"]))
        XCTAssertEqual(try Data(contentsOf: existing), original)
        for output in result.outputs {
            let document = try assertPasswordRequired(output)
            XCTAssertEqual(document.pageCount, 1)
            XCTAssertEqual(BookmarkService.read(from: document).map(\.title), ["chapter"])
        }
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: outputs.path)),
                       Set(["chapter.pdf", "chapter (2).pdf", "chapter (3).pdf"]))
    }

    func testInvalidPasswordNeverPublishesPlaintextOrLeavesTemporaryFiles() async throws {
        let input = directory.appendingPathComponent("image.png")
        try saveImage(makeImage(), to: input)
        let asset = try ImagePipeline.inspect(input)
        var settings = ConversionSettings()
        settings.useInterfaceFile = false
        let invalidPasswords = ["", "密码", "line\nbreak", String(repeating: "x", count: 33)]
        for (index, invalidPassword) in invalidPasswords.enumerated() {
            let output = directory.appendingPathComponent("invalid-\(index).pdf")
            do {
                _ = try await PDFConverter.convert(assets: [asset], settings: settings, destination: output,
                                                   encryption: PDFEncryptionOptions(password: invalidPassword)) { _ in }
                XCTFail("Invalid password unexpectedly produced an output for case \(index)")
            } catch PDFEncryptionError.invalidPassword {
                // Validation must reject unsupported passwords rather than truncate or disable encryption.
            } catch {
                XCTFail("Expected invalid-password rejection, received: \(error)")
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["image.png"],
                           "Rejected encryption must leave neither a plaintext PDF nor a temporary file")
        }
    }

    func testPerFolderEditingPasswordAllowsReadingAndRequiresOwnerForChanges() async throws {
        let firstFolder = directory.appendingPathComponent("Book A")
        let secondFolder = directory.appendingPathComponent("Book B")
        let outputs = directory.appendingPathComponent("outputs")
        for folder in [firstFolder, secondFolder, outputs] {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let inputs = [firstFolder.appendingPathComponent("page-1.png"),
                      firstFolder.appendingPathComponent("page-2.png"),
                      secondFolder.appendingPathComponent("page-1.png")]
        for (index, input) in inputs.enumerated() {
            try saveImage(makeImage(width: 240 + index * 40, height: 160), to: input)
        }
        let originalBytes = try inputs.map { try Data(contentsOf: $0) }
        let editingPassword = "Folio-editing-only-2026!"
        var settings = ConversionSettings()
        settings.outputMode = .perFolder
        settings.useInterfaceFile = false
        let result = try await PDFConverter.convert(assets: try inputs.map(ImagePipeline.inspect), settings: settings,
                                                    destination: outputs,
                                                    encryption: PDFEncryptionOptions(editingPassword: editingPassword)) { _ in }
        XCTAssertEqual(result.outputs.count, 2)
        XCTAssertEqual(result.pageCount, 3)
        XCTAssertTrue(result.warnings.isEmpty, result.warnings.joined(separator: "\n"))
        XCTAssertEqual(Set(result.outputs.map(\.lastPathComponent)), Set(["Book A.pdf", "Book B.pdf"]))
        for output in result.outputs {
            let document = try XCTUnwrap(PDFDocument(url: output))
            XCTAssertTrue(document.isEncrypted)
            XCTAssertFalse(document.isLocked, "An editing-only password must not prevent reading the PDF")
            XCTAssertEqual(document.pageCount, output.lastPathComponent == "Book A.pdf" ? 2 : 1)
            assertPermissions(document, owner: false)
            // PDFKit reports true for an already open document even when owner
            // authentication fails. The status and permission bits are decisive.
            XCTAssertTrue(document.unlock(withPassword: ""))
            assertPermissions(document, owner: false)
            XCTAssertTrue(document.unlock(withPassword: "incorrect-editing-password"))
            assertPermissions(document, owner: false)
            XCTAssertTrue(document.unlock(withPassword: editingPassword))
            assertPermissions(document, owner: true)
        }
        XCTAssertEqual(try inputs.map { try Data(contentsOf: $0) }, originalBytes)
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: outputs.path)), Set(["Book A.pdf", "Book B.pdf"]))
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: firstFolder.path)), Set(["page-1.png", "page-2.png"]))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: secondFolder.path), ["page-1.png"])
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: directory.path)), Set(["Book A", "Book B", "outputs"]))
    }

    func testDualPasswordsSeparateReaderAndOwnerWhilePreservingDocumentDetails() async throws {
        let inputs = [directory.appendingPathComponent("Chapter One.png"), directory.appendingPathComponent("Chapter Two.png")]
        for input in inputs { try saveImage(makeImage(), to: input) }
        let editingPassword = "Folio-owner-separate-2026!"
        let openingPassword = "Folio-reader!"
        var settings = ConversionSettings()
        settings.useInterfaceFile = false
        settings.addFileBookmarks = true
        settings.title = "Two-password book 扫描册"
        settings.author = "Folio Password Integration Tests"
        let output = directory.appendingPathComponent("dual-password.pdf")
        let result = try await PDFConverter.convert(assets: try inputs.map(ImagePipeline.inspect), settings: settings,
                                                    destination: output,
                                                    encryption: PDFEncryptionOptions(openPassword: openingPassword, editingPassword: editingPassword)) { _ in }
        XCTAssertEqual(result.outputs, [output])
        XCTAssertEqual(result.pageCount, 2)
        XCTAssertTrue(result.warnings.isEmpty, result.warnings.joined(separator: "\n"))
        // This helper verifies that fresh, empty and incorrect passwords leave
        // the document locked before the requested opening password succeeds.
        let reader = try assertPasswordRequired(output, openingPassword: openingPassword)
        assertPermissions(reader, owner: false)
        XCTAssertTrue(reader.unlock(withPassword: "incorrect-owner-password"))
        assertPermissions(reader, owner: false)

        let owner = try XCTUnwrap(PDFDocument(url: output))
        XCTAssertTrue(owner.isLocked)
        XCTAssertTrue(owner.unlock(withPassword: editingPassword), "The owner password must also open the PDF directly")
        assertPermissions(owner, owner: true)
        for document in [reader, owner] {
            XCTAssertEqual(document.pageCount, 2)
            XCTAssertEqual(document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String, settings.title)
            XCTAssertEqual(document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String, settings.author)
            let bookmarks = BookmarkService.read(from: document)
            XCTAssertEqual(bookmarks.map(\.title), ["Chapter One", "Chapter Two"])
            XCTAssertEqual(bookmarks.map(\.pageIndex), [0, 1])
        }
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: directory.path)),
                       Set(["Chapter One.png", "Chapter Two.png", "dual-password.pdf"]))
    }

    func testEncryptedVisionOCRRemainsSearchableAndInvisibleAfterUnlocking() async throws {
        let input = directory.appendingPathComponent("ocr.png")
        try saveImage(makeImage(width: 1500, height: 400, text: "FOLIO SEARCHABLE 2026"), to: input)
        let asset = try ImagePipeline.inspect(input)
        var settings = ConversionSettings()
        settings.useInterfaceFile = false
        settings.ocrEnabled = true
        settings.ocrLanguages = ["en-US"]
        let protected = directory.appendingPathComponent("searchable-protected.pdf")
        let result = try await PDFConverter.convert(assets: [asset], settings: settings, destination: protected,
                                                    encryption: PDFEncryptionOptions(password: password)) { _ in }
        XCTAssertTrue(result.warnings.isEmpty, result.warnings.joined(separator: "\n"))
        let document = try assertPasswordRequired(protected)
        XCTAssertTrue((document.string ?? "").contains("SEARCHABLE"), document.string ?? "No OCR text after unlocking")
        XCTAssertFalse(document.findString("SEARCHABLE", withOptions: .caseInsensitive).isEmpty,
                       "Recognized text must remain searchable after encryption")
        settings.ocrEnabled = false
        let unencrypted = directory.appendingPathComponent("image-only-reference.pdf")
        _ = try await PDFConverter.convert(assets: [asset], settings: settings, destination: unencrypted) { _ in }
        XCTAssertEqual(try rasterize(protected, password: password), try rasterize(unencrypted),
                       "Encryption and the hidden OCR layer must not change visible page pixels")
    }

    func testCancellationDuringEncryptedConversionCleansUnpublishedFiles() async throws {
        let input = directory.appendingPathComponent("image.png")
        try saveImage(makeImage(width: 640, height: 480), to: input)
        let asset = try ImagePipeline.inspect(input)
        var settings = ConversionSettings()
        settings.useInterfaceFile = false
        let output = directory.appendingPathComponent("cancelled.pdf")
        let started = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let pause = ConversionPause()
        let encryption = PDFEncryptionOptions(password: password)
        // The worker pauses after it has rendered a real page. Cancellation therefore
        // exercises cleanup of an in-progress file, not only the preflight check.
        let task = Task {
            defer { started.continuation.finish() }
            return try await PDFConverter.convert(assets: Array(repeating: asset, count: 3), settings: settings,
                                                   destination: output, encryption: encryption) { progress in
                if progress.completedPages == 1 && pause.claim() {
                    started.continuation.yield(())
                    _ = pause.resume.wait(timeout: .now() + 15)
                }
            }
        }
        defer { pause.resume.signal() }
        var iterator = started.stream.makeAsyncIterator()
        guard await iterator.next() != nil else {
            _ = try await task.value
            XCTFail("Conversion finished without reaching the cancellation checkpoint")
            return
        }
        task.cancel()
        pause.resume.signal()
        do {
            _ = try await task.value
            XCTFail("Cancelled conversion unexpectedly published a PDF")
        } catch is CancellationError {
        } catch let interrupted as ConversionInterrupted {
            XCTAssertTrue(interrupted.isCancelled)
            XCTAssertTrue(interrupted.partialResult.outputs.isEmpty, "A combined PDF must never be partially published")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["image.png"],
                       "Cancellation must clean up plaintext, encrypted and partial temporary outputs")
    }

    private func assertPermissions(_ document: PDFDocument, owner: Bool, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(document.isLocked, file: file, line: line)
        XCTAssertEqual(document.permissionsStatus, owner ? .owner : .user, file: file, line: line)
        XCTAssertEqual(document.accessPermissions.rawValue, owner ? 255 : 51, file: file, line: line)
        XCTAssertTrue(document.allowsPrinting, file: file, line: line)
        XCTAssertTrue(document.allowsCopying, file: file, line: line)
        XCTAssertTrue(document.allowsContentAccessibility, file: file, line: line)
        XCTAssertEqual(document.allowsDocumentChanges, owner, file: file, line: line)
        XCTAssertEqual(document.allowsDocumentAssembly, owner, file: file, line: line)
        XCTAssertEqual(document.allowsCommenting, owner, file: file, line: line)
        XCTAssertEqual(document.allowsFormFieldEntry, owner, file: file, line: line)
    }

    private func assertPasswordRequired(_ url: URL, openingPassword: String? = nil, file: StaticString = #filePath, line: UInt = #line) throws -> PDFDocument {
        let document = try XCTUnwrap(PDFDocument(url: url), file: file, line: line)
        XCTAssertTrue(document.isEncrypted, "An encryption request must never fall back to plaintext", file: file, line: line)
        XCTAssertTrue(document.isLocked, "Opening the file must require a password", file: file, line: line)
        XCTAssertFalse(document.unlock(withPassword: ""), "An empty password must not unlock the output", file: file, line: line)
        XCTAssertTrue(document.isLocked, file: file, line: line)
        XCTAssertFalse(document.unlock(withPassword: "incorrect-password"), "A wrong password must not unlock the output", file: file, line: line)
        XCTAssertTrue(document.isLocked, file: file, line: line)
        XCTAssertTrue(document.unlock(withPassword: openingPassword ?? password), "The requested password must unlock the output", file: file, line: line)
        XCTAssertFalse(document.isLocked, file: file, line: line)
        return document
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

    private func saveImage(_ image: CGImage, to url: URL) throws {
        let writer = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(writer, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(writer))
    }

    private func rasterize(_ url: URL, password: String? = nil) throws -> Data {
        let document = try XCTUnwrap(CGPDFDocument(url as CFURL))
        if let password { XCTAssertTrue(document.unlockWithPassword(password)) }
        let page = try XCTUnwrap(document.page(at: 1))
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

private final class ConversionPause: @unchecked Sendable {
    let resume = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var claimed = false
    func claim() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !claimed else { return false }
        claimed = true
        return true
    }
}
