import XCTest
import Foundation
import CoreGraphics
import CoreText
import PDFKit
@testable import FolioCore

final class PDFEncryptionTests: XCTestCase {
    private func directory() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("FolioEncryptionTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
        return folder
    }

    private func source(in folder: URL, pages: Int = 8, configuration: InterfaceConfiguration? = nil, layout: PDFLayout? = nil) throws -> URL {
        let data = NSMutableData()
        let consumer = try XCTUnwrap(CGDataConsumer(data: data as CFMutableData))
        var media = CGRect(x: 0, y: 0, width: 300, height: 400)
        let context = try XCTUnwrap(CGContext(consumer: consumer, mediaBox: &media, nil))
        let font = CTFontCreateWithName("Helvetica" as CFString, 14, nil)
        for index in 1...pages {
            context.beginPDFPage(nil)
            context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(media)
            context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1))
            context.fill(CGRect(x: 20, y: 20, width: 260, height: 60))
            context.setTextDrawingMode(.invisible)
            context.textPosition = CGPoint(x: 20, y: 300)
            let text = NSAttributedString(string: "Searchable private page \(index)", attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
            CTLineDraw(CTLineCreateWithAttributedString(text), context)
            context.endPDFPage()
        }
        context.closePDF()
        let document = try XCTUnwrap(PDFDocument(data: data as Data))
        try BookmarkService.apply(entries: [
            .init(title: "Chapter 秘密", pageIndex: 0),
            .init(title: "Child", pageIndex: min(pages - 1, 1), depth: 1)
        ], to: document)
        BookmarkService.apply(metadata: .init(title: "Private 私密文档", author: "FolioPDF"), to: document)
        let url = folder.appendingPathComponent("source.pdf")
        try InterfaceFile.write(document: document, to: url, configuration: configuration, layout: layout)
        return url
    }

    private func unlock(_ url: URL, password: String, pages: Int) throws -> PDFDocument {
        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertTrue(document.isEncrypted)
        XCTAssertTrue(document.isLocked)
        XCTAssertFalse(document.unlock(withPassword: ""))
        XCTAssertTrue(document.isLocked)
        XCTAssertFalse(document.unlock(withPassword: "Definitely-wrong-password"))
        XCTAssertTrue(document.isLocked)
        XCTAssertTrue(document.unlock(withPassword: password))
        XCTAssertFalse(document.isLocked)
        XCTAssertEqual(document.pageCount, pages)
        XCTAssertTrue(document.allowsPrinting)
        XCTAssertTrue(document.allowsCopying)
        assertPermissions(document, restricted: false, status: .user)
        return document
    }

    private func assertPermissions(_ document: PDFDocument, restricted: Bool, status: PDFDocumentPermissions,
                                   file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(document.isLocked, file: file, line: line)
        XCTAssertEqual(document.permissionsStatus, status, file: file, line: line)
        XCTAssertEqual(document.accessPermissions.rawValue, restricted ? 51 : 255, file: file, line: line)
        XCTAssertTrue(document.allowsPrinting, file: file, line: line)
        XCTAssertTrue(document.allowsCopying, file: file, line: line)
        XCTAssertTrue(document.allowsContentAccessibility, file: file, line: line)
        XCTAssertEqual(document.allowsDocumentChanges, !restricted, file: file, line: line)
        XCTAssertEqual(document.allowsDocumentAssembly, !restricted, file: file, line: line)
        XCTAssertEqual(document.allowsCommenting, !restricted, file: file, line: line)
        XCTAssertEqual(document.allowsFormFieldEntry, !restricted, file: file, line: line)
    }

    private func raster(_ url: URL, password: String? = nil) throws -> Data {
        let document = try XCTUnwrap(CGPDFDocument(url as CFURL))
        if let password { XCTAssertTrue(document.unlockWithPassword(password)) }
        let page = try XCTUnwrap(document.page(at: 1))
        let context = try XCTUnwrap(CGContext(data: nil, width: 300, height: 400, bitsPerComponent: 8,
                                             bytesPerRow: 1_200, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
        context.drawPDFPage(page)
        return Data(bytes: try XCTUnwrap(context.data), count: 1_200 * 400)
    }

    private func capture(_ pattern: String, in text: String, last: Bool = false) throws -> String {
        let expression = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
        let matches = expression.matches(in: text, range: NSRange(location: 0, length: (text as NSString).length))
        let match = try XCTUnwrap(last ? matches.last : matches.first)
        return (text as NSString).substring(with: match.range(at: 1))
    }

    private func encryptionDictionary(_ url: URL) throws -> String {
        let text = try XCTUnwrap(String(data: Data(contentsOf: url), encoding: .isoLatin1))
        let number = try capture("/Encrypt\\s+(\\d+)\\s+0\\s+R", in: text, last: true)
        return try capture("\\n" + number + " 0 obj\\s*(<<.*?>>)\\s*endobj", in: text)
    }

    func testPasswordValidationRejectsTruncationUnicodeAndControls() throws {
        for password in ["", String(repeating: "x", count: 33), "秘密", "passé", "line\nbreak", "tab\there", "nul\u{0}tail", "delete\u{7F}"] {
            XCTAssertThrowsError(try PDFEncryption.validate(options: .init(password: password))) {
                XCTAssertEqual($0 as? PDFEncryptionError, .invalidPassword)
            }
        }
        for password in ["a", String(repeating: "x", count: 32), " leading and trailing ", "!#$%&()*+,-./:;<=>?@[]^_{|}~", " "] {
            XCTAssertNoThrow(try PDFEncryption.validate(options: .init(password: password)))
        }
    }

    func testOpeningAndEditingPasswordsValidateIndependently() throws {
        XCTAssertEqual(PDFEncryptionOptions(password: "Legacy-password"), PDFEncryptionOptions(openPassword: "Legacy-password"))
        XCTAssertThrowsError(try PDFEncryption.validate(options: .init())) {
            XCTAssertEqual($0 as? PDFEncryptionError, .missingPassword)
        }
        XCTAssertThrowsError(try PDFEncryption.validate(options: .init(openPassword: "Same-password", editingPassword: "Same-password"))) {
            XCTAssertEqual($0 as? PDFEncryptionError, .identicalPasswords)
        }
        for invalid in ["", String(repeating: "x", count: 33), "编辑密码", "line\nbreak", "nul\u{0}"] {
            for options in [PDFEncryptionOptions(editingPassword: invalid),
                            PDFEncryptionOptions(openPassword: "Valid-opening", editingPassword: invalid),
                            PDFEncryptionOptions(openPassword: invalid, editingPassword: "Valid-editing")] {
                XCTAssertThrowsError(try PDFEncryption.validate(options: options)) {
                    XCTAssertEqual($0 as? PDFEncryptionError, .invalidPassword)
                }
            }
        }
        XCTAssertNoThrow(try PDFEncryption.validate(options: .init(editingPassword: "Editing-only")))
        XCTAssertNoThrow(try PDFEncryption.validate(options: .init(openPassword: "Read-password", editingPassword: "Edit-password")))
    }

    func testEditingPasswordOnlyIsReadableButWrongPasswordCannotGrantEditing() throws {
        let folder = try directory()
        var configuration = InterfaceConfiguration(directory: folder, contentsPage: 3, textPage: 6)
        configuration.showBookmarks = true
        let source = try source(in: folder, configuration: configuration, layout: .twoPages)
        let destination = folder.appendingPathComponent("editing-only.pdf")
        let password = "Owner-editing-2026!"
        try PDFEncryption.encrypt(source: source, destination: destination, options: .init(editingPassword: password))
        let reader = try XCTUnwrap(PDFDocument(url: destination))
        XCTAssertTrue(reader.isEncrypted)
        assertPermissions(reader, restricted: true, status: .user)
        XCTAssertEqual(reader.pageCount, 8)
        XCTAssertTrue(reader.page(at: 7)?.string?.contains("Searchable private page 8") == true)
        XCTAssertEqual((0..<8).map { reader.page(at: $0)?.label }, ["A", "B", "i", "ii", "iii", "1", "2", "3"])
        XCTAssertEqual(BookmarkService.read(from: reader).map(\.title), ["Chapter 秘密", "Child"])
        XCTAssertEqual(reader.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String, "Private 私密文档")
        XCTAssertEqual(try raster(source), try raster(destination))
        // PDFKit returns true because the PDF is already readable; this does not authenticate an owner.
        XCTAssertTrue(reader.unlock(withPassword: "Wrong-owner-password"))
        assertPermissions(reader, restricted: true, status: .user)
        XCTAssertTrue(reader.unlock(withPassword: ""))
        assertPermissions(reader, restricted: true, status: .user)
        XCTAssertTrue(reader.unlock(withPassword: password))
        assertPermissions(reader, restricted: false, status: .owner)
        let freshOwner = try XCTUnwrap(PDFDocument(url: destination))
        XCTAssertTrue(freshOwner.unlock(withPassword: password))
        assertPermissions(freshOwner, restricted: false, status: .owner)
        let cipher = try encryptionDictionary(destination)
        XCTAssertEqual(try capture("/CFM\\s*/([A-Za-z0-9]+)", in: cipher), "AESV2")
        XCTAssertEqual(try capture("/Length\\s+(\\d+)", in: cipher), "128")
        let bytes = try Data(contentsOf: destination)
        XCTAssertNil(bytes.range(of: Data(password.utf8)))
        XCTAssertNil(bytes.range(of: Data("Searchable private page".utf8)))
    }

    func testDualPasswordsGiveReaderAndOwnerDifferentPermissions() throws {
        let folder = try directory(), source = try source(in: folder, pages: 2)
        let destination = folder.appendingPathComponent("dual-password.pdf")
        let open = "Reading-password", editing = "Editing-password"
        try PDFEncryption.encrypt(source: source, destination: destination, options: .init(openPassword: open, editingPassword: editing))
        let reader = try XCTUnwrap(PDFDocument(url: destination))
        XCTAssertTrue(reader.isEncrypted)
        XCTAssertTrue(reader.isLocked)
        XCTAssertEqual(reader.permissionsStatus, .none)
        XCTAssertEqual(reader.accessPermissions.rawValue, 0)
        XCTAssertFalse(reader.unlock(withPassword: ""))
        XCTAssertFalse(reader.unlock(withPassword: "Wrong-password"))
        XCTAssertTrue(reader.isLocked)
        XCTAssertTrue(reader.unlock(withPassword: open))
        assertPermissions(reader, restricted: true, status: .user)
        XCTAssertTrue(reader.page(at: 1)?.string?.contains("Searchable private page 2") == true)
        XCTAssertTrue(reader.unlock(withPassword: "Wrong-editing-password"))
        assertPermissions(reader, restricted: true, status: .user)
        XCTAssertTrue(reader.unlock(withPassword: editing))
        assertPermissions(reader, restricted: false, status: .owner)
        let owner = try XCTUnwrap(PDFDocument(url: destination))
        XCTAssertTrue(owner.isLocked)
        XCTAssertTrue(owner.unlock(withPassword: editing))
        assertPermissions(owner, restricted: false, status: .owner)
        XCTAssertEqual(owner.pageCount, 2)
        XCTAssertEqual(try raster(source), try raster(destination, password: open))
        XCTAssertEqual(try raster(source), try raster(destination, password: editing))
    }

    func testDualPasswordOpeningLimitIsCheckedBeforeAnyOutputIsWritten() throws {
        let folder = try directory(), source = try source(in: folder, pages: 1)
        let original = try Data(contentsOf: source)
        let editing = String(repeating: "e", count: 32)
        let opening = String(repeating: "o", count: 16)
        let destination = folder.appendingPathComponent("joint-16.pdf")
        try PDFEncryption.encrypt(source: source, destination: destination,
                                  options: .init(openPassword: opening, editingPassword: editing))
        let reader = try XCTUnwrap(PDFDocument(url: destination))
        XCTAssertTrue(reader.unlock(withPassword: opening))
        assertPermissions(reader, restricted: true, status: .user)
        let owner = try XCTUnwrap(PDFDocument(url: destination))
        XCTAssertTrue(owner.unlock(withPassword: editing))
        assertPermissions(owner, restricted: false, status: .owner)
        for length in [17, 31, 32] {
            let options = PDFEncryptionOptions(openPassword: String(repeating: "o", count: length), editingPassword: editing)
            XCTAssertThrowsError(try PDFEncryption.validate(options: options)) {
                XCTAssertEqual($0 as? PDFEncryptionError, .openingPasswordTooLongForEditing)
            }
            let rejected = folder.appendingPathComponent("joint-\(length).pdf")
            XCTAssertThrowsError(try PDFEncryption.encrypt(source: source, destination: rejected, options: options)) {
                XCTAssertEqual($0 as? PDFEncryptionError, .openingPasswordTooLongForEditing)
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: rejected.path))
        }
        XCTAssertEqual(try Data(contentsOf: source), original)
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: folder.path)), ["source.pdf", "joint-16.pdf"])
    }

    func testEditingPasswordBoundariesAreNotTruncatedOrTrimmed() throws {
        let folder = try directory(), source = try source(in: folder, pages: 1)
        for (index, password) in ["a", String(repeating: "x", count: 32), " spaces matter "].enumerated() {
            let destination = folder.appendingPathComponent("editing-\(index).pdf")
            try PDFEncryption.encrypt(source: source, destination: destination, options: .init(editingPassword: password))
            let reader = try XCTUnwrap(PDFDocument(url: destination))
            assertPermissions(reader, restricted: true, status: .user)
            let nearMiss = index == 2 ? password.trimmingCharacters(in: .whitespaces) : String(password.dropLast())
            _ = reader.unlock(withPassword: nearMiss)
            assertPermissions(reader, restricted: true, status: .user)
            XCTAssertTrue(reader.unlock(withPassword: password))
            assertPermissions(reader, restricted: false, status: .owner)
        }
    }

    func testNativeAES128RequiresPasswordAndPreservesSearchableContent() throws {
        let folder = try directory(), source = try source(in: folder)
        let original = try Data(contentsOf: source), destination = folder.appendingPathComponent("protected.pdf")
        let password = "Folio-Test-2026!"
        try PDFEncryption.encrypt(source: source, destination: destination, options: .init(password: password))
        let document = try unlock(destination, password: password, pages: 8)
        XCTAssertEqual(try Data(contentsOf: source), original)
        XCTAssertEqual(try raster(source), try raster(destination, password: password))
        XCTAssertEqual(document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String, "Private 私密文档")
        XCTAssertEqual(document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String, "FolioPDF")
        XCTAssertEqual(BookmarkService.read(from: document).map(\.title), ["Chapter 秘密", "Child"])
        XCTAssertEqual(BookmarkService.read(from: document).map(\.depth), [0, 1])
        XCTAssertEqual(BookmarkService.read(from: document).map(\.pageIndex), [0, 1])
        for page in 0..<8 {
            XCTAssertTrue(document.page(at: page)?.string?.contains("Searchable private page \(page + 1)") == true)
            XCTAssertEqual(document.page(at: page)?.bounds(for: .mediaBox), CGRect(x: 0, y: 0, width: 300, height: 400))
        }
        let cipher = try encryptionDictionary(destination)
        XCTAssertEqual(try capture("/V\\s+(\\d+)", in: cipher), "4")
        XCTAssertEqual(try capture("/R\\s+(\\d+)", in: cipher), "4")
        XCTAssertEqual(try capture("/Length\\s+(\\d+)", in: cipher), "128")
        XCTAssertEqual(try capture("/CFM\\s*/([A-Za-z0-9]+)", in: cipher), "AESV2")
        XCTAssertTrue(cipher.contains("/EncryptMetadata true"))
        XCTAssertTrue(cipher.contains("/P -4"))
        let bytes = try Data(contentsOf: destination)
        XCTAssertNil(bytes.range(of: Data(password.utf8)))
        XCTAssertNil(bytes.range(of: Data("Searchable private page".utf8)))
    }

    func testPageLabelsLayoutAndBookmarkPaneSurviveEncryption() throws {
        let folder = try directory()
        var configuration = InterfaceConfiguration(directory: folder, contentsPage: 3, textPage: 6)
        configuration.showBookmarks = true
        let source = try source(in: folder, configuration: configuration, layout: .twoPages)
        let destination = folder.appendingPathComponent("protected-labels.pdf"), password = "Labels-2026!"
        try PDFEncryption.encrypt(source: source, destination: destination, options: .init(password: password))
        let document = try unlock(destination, password: password, pages: 8)
        XCTAssertEqual((0..<8).map { document.page(at: $0)?.label }, ["A", "B", "i", "ii", "iii", "1", "2", "3"])
        let cg = try XCTUnwrap(CGPDFDocument(destination as CFURL))
        XCTAssertTrue(cg.unlockWithPassword(password))
        let catalog = try XCTUnwrap(cg.catalog)
        for (key, expected) in [("PageLayout", "TwoPageRight"), ("PageMode", "UseOutlines")] {
            var name: UnsafePointer<CChar>?
            XCTAssertTrue(CGPDFDictionaryGetName(catalog, key, &name))
            XCTAssertEqual(try XCTUnwrap(name).withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }, expected)
        }
        XCTAssertTrue(document.page(at: 7)?.string?.contains("Searchable private page 8") == true)
        XCTAssertEqual(BookmarkService.read(from: document).count, 2)
        // The incremental trailer must retain the encryption reference and both file IDs.
        let text = try XCTUnwrap(String(data: Data(contentsOf: destination), encoding: .isoLatin1))
        let trailer = try capture("trailer\\s*(<<[^>]*?/ID\\s*\\[.*?\\]\\s*>>)\\s*startxref\\s+\\d+\\s+%%EOF\\s*$", in: text)
        XCTAssertTrue(trailer.contains("/Encrypt "))
        XCTAssertTrue(trailer.contains("/Prev "))
    }

    func testCustomTextPageLabelPrefixFailsWithoutPublishingAnyFile() throws {
        let folder = try directory()
        var configuration = InterfaceConfiguration(directory: folder, contentsPage: 3, textPage: 6)
        configuration.prefix1 = "封面-"
        let source = try source(in: folder, configuration: configuration)
        let original = try Data(contentsOf: source), destination = folder.appendingPathComponent("must-not-exist.pdf")
        XCTAssertThrowsError(try PDFEncryption.encrypt(source: source, destination: destination, options: .init(password: "Test-123"))) {
            XCTAssertEqual($0 as? PDFEncryptionError, .unsupportedPageLabels)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try Data(contentsOf: source), original)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), ["source.pdf"])
    }

    func testBoundaryPasswordsAreUsedExactlyWithoutTrimming() throws {
        let folder = try directory(), source = try source(in: folder, pages: 1)
        for (index, password) in ["a", String(repeating: "x", count: 32), " spaces are significant "].enumerated() {
            let destination = folder.appendingPathComponent("protected-\(index).pdf")
            try PDFEncryption.encrypt(source: source, destination: destination, options: .init(password: password))
            _ = try unlock(destination, password: password, pages: 1)
            if index == 2 {
                let alternate = try XCTUnwrap(PDFDocument(url: destination))
                XCTAssertFalse(alternate.unlock(withPassword: password.trimmingCharacters(in: .whitespaces)))
            }
        }
    }

    func testFreshOwnerPasswordsProduceDifferentOwnerEntries() throws {
        let folder = try directory(), source = try source(in: folder, pages: 1)
        let first = folder.appendingPathComponent("first.pdf"), second = folder.appendingPathComponent("second.pdf")
        for destination in [first, second] {
            try PDFEncryption.encrypt(source: source, destination: destination, options: .init(password: "Same-user-password"))
            _ = try unlock(destination, password: "Same-user-password", pages: 1)
        }
        let firstOwner = try capture("/O\\s*<([0-9a-fA-F]+)>", in: encryptionDictionary(first))
        let secondOwner = try capture("/O\\s*<([0-9a-fA-F]+)>", in: encryptionDictionary(second))
        XCTAssertNotEqual(firstOwner, secondOwner)
    }

    func testExistingDestinationAndOriginalAreNeverOverwritten() throws {
        let folder = try directory(), source = try source(in: folder, pages: 1)
        let original = try Data(contentsOf: source), destination = folder.appendingPathComponent("existing.pdf")
        let sentinel = Data("Existing user content".utf8); try sentinel.write(to: destination)
        XCTAssertThrowsError(try PDFEncryption.encrypt(source: source, destination: source, options: .init(password: "Password"))) {
            XCTAssertEqual($0 as? PDFEncryptionError, .sourceEqualsDestination)
        }
        XCTAssertThrowsError(try PDFEncryption.encrypt(source: source, destination: destination, options: .init(password: "Password"))) {
            XCTAssertEqual($0 as? PDFEncryptionError, .destinationExists)
        }
        XCTAssertEqual(try Data(contentsOf: destination), sentinel)
        XCTAssertEqual(try Data(contentsOf: source), original)
    }

    func testAlreadyEncryptedSourceIsExplicitlyRejected() throws {
        let folder = try directory(), source = try source(in: folder, pages: 1)
        let encrypted = folder.appendingPathComponent("encrypted.pdf"), destination = folder.appendingPathComponent("second.pdf")
        try PDFEncryption.encrypt(source: source, destination: encrypted, options: .init(password: "First-password"))
        XCTAssertThrowsError(try PDFEncryption.encrypt(source: encrypted, destination: destination, options: .init(password: "Second-password"))) {
            XCTAssertEqual($0 as? PDFEncryptionError, .sourceAlreadyEncrypted)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testInvalidSourceAndWriteFailureLeaveNoPartialOrPlaintextOutput() throws {
        let folder = try directory(), source = try source(in: folder, pages: 1)
        let invalid = folder.appendingPathComponent("bad.pdf"); try Data("not a PDF".utf8).write(to: invalid)
        let destination = folder.appendingPathComponent("result.pdf")
        XCTAssertThrowsError(try PDFEncryption.encrypt(source: invalid, destination: destination, options: .init(password: "Password"))) {
            XCTAssertEqual($0 as? PDFEncryptionError, .invalidSource)
        }
        XCTAssertThrowsError(try PDFEncryption.encrypt(source: source, destination: folder.appendingPathComponent("missing/result.pdf"), options: .init(password: "Password"))) {
            XCTAssertEqual($0 as? PDFEncryptionError, .writeFailed)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: folder.path)), ["source.pdf", "bad.pdf"])
    }
}
