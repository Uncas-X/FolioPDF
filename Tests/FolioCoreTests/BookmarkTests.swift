import XCTest
import PDFKit
import CoreGraphics
@testable import FolioCore

final class BookmarkTests: XCTestCase {
    private func document(pages: Int = 8) -> PDFDocument {
        let data = NSMutableData()
        let consumer = CGDataConsumer(data: data as CFMutableData)!
        var bounds = CGRect(x: 0, y: 0, width: 400, height: 600)
        let context = CGContext(consumer: consumer, mediaBox: &bounds, nil)!
        for _ in 0..<pages { context.beginPDFPage(nil); context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(bounds); context.endPDFPage() }
        context.closePDF(); return PDFDocument(data: data as Data)!
    }
    private func directory() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("FolioBookmarkTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }; return folder
    }
    func testBasePageAndHierarchyRoundTrip() throws {
        let text = "封面\t-5\n前言\t-1\n第一章\t1\n\t小节\t2"
        let entries = try BookmarkService.parse(text: text, basePage: 6)
        XCTAssertEqual(entries.map(\.pageIndex), [0, 4, 5, 6])
        XCTAssertEqual(entries.map(\.depth), [0, 0, 0, 1])
        XCTAssertEqual(BookmarkService.serialize(entries: entries, basePage: 6), text)
        let pdf = document()
        try BookmarkService.apply(entries: entries, to: pdf)
        let reopened = PDFDocument(data: pdf.dataRepresentation()!)!
        let roundTrip = BookmarkService.read(from: reopened)
        XCTAssertEqual(roundTrip.map(\.title), entries.map(\.title))
        XCTAssertEqual(roundTrip.map(\.pageIndex), entries.map(\.pageIndex))
        XCTAssertEqual(roundTrip.map(\.depth), entries.map(\.depth))
    }
    func testInvalidTargetsNeverSilentlyDisappear() throws {
        XCTAssertThrowsError(try BookmarkService.parse(text: "Bad\t0"))
        XCTAssertThrowsError(try BookmarkService.parse(text: "\tOrphan\t1"))
        XCTAssertThrowsError(try BookmarkService.parse(text: "A\t1\n\t\tB\t2"))
        XCTAssertThrowsError(try BookmarkService.parse(text: "Before start\t-6", basePage: 6))
        XCTAssertThrowsError(try BookmarkService.parse(text: "No separator 1"))
        let unresolved = try BookmarkService.parse(text: "Named\t/chapterOne")
        XCTAssertEqual(unresolved.first?.targetKind, .unresolved)
        XCTAssertEqual(BookmarkService.serialize(entries: unresolved), "Named\t/chapterOne")
        XCTAssertThrowsError(try BookmarkService.apply(entries: unresolved, to: document()))
        XCTAssertThrowsError(try BookmarkService.apply(entries: [.init(title: "Too far", pageIndex: 99)], to: document()))
    }
    func testSupportedActionsAndJSONRoundTrip() throws {
        let entries = try BookmarkService.parse(text: "Next\t!NextPage\nWebsite\thttps://example.com")
        let pdf = document(); try BookmarkService.apply(entries: entries, to: pdf)
        let loaded = BookmarkService.inspect(from: PDFDocument(data: pdf.dataRepresentation()!)!)
        XCTAssertEqual(loaded.entries.map(\.targetKind), [.namedAction, .url])
        XCTAssertEqual(loaded.entries.map(\.targetValue), ["NextPage", "https://example.com"])
        let data = try BookmarkService.jsonData(entries: loaded.entries)
        XCTAssertEqual(try JSONDecoder().decode([BookmarkEntry].self, from: data), loaded.entries)
    }
    func testRemoteTargetsArePreservedInTextAndExplicitlyRejectedForPDF() throws {
        let text = "External\t^/tmp/book.pdf\t3"
        let entries = try BookmarkService.parse(text: text)
        XCTAssertEqual(entries.first?.targetKind, .remotePDF)
        XCTAssertEqual(entries.first?.pageIndex, 2)
        XCTAssertEqual(BookmarkService.serialize(entries: entries), text)
        XCTAssertThrowsError(try BookmarkService.apply(entries: entries, to: document()))
        let pdf = document(), root = PDFOutline(), item = PDFOutline()
        item.label = "External"; item.action = PDFActionRemoteGoTo(pageIndex: 2, at: .zero, fileURL: URL(fileURLWithPath: "/tmp/book.pdf"))
        root.insertChild(item, at: 0); pdf.outlineRoot = root
        // PDFKit can return nil for a documented nonnull remote URL. Reading it must never trap.
        let loaded = BookmarkService.inspect(from: PDFDocument(data: pdf.dataRepresentation()!)!)
        XCTAssertEqual(loaded.entries.count, 1)
        XCTAssertFalse(loaded.warnings.isEmpty)
        XCTAssertThrowsError(try BookmarkService.apply(entries: loaded.entries, to: document()))
    }
    func testInterfaceUTF16MetadataAndSegmentedLabels() throws {
        let folder = try directory()
        let itf = "[Bkmk]\nFile=FreePic2Pdf_bkmk.txt\nBasePage=6\nShowBkmk=1\n[Info]\nTitle=中文测试\nAuthor=Folio\n[Main]\nContentsPage=3\nTextPage=6\n"
        var itfData = Data([0xFF, 0xFE]); itfData.append(itf.data(using: .utf16LittleEndian)!)
        try itfData.write(to: folder.appendingPathComponent("FreePic2Pdf.itf"))
        try Data("Cover\t-5\nChapter\t1".utf8).write(to: folder.appendingPathComponent("FreePic2Pdf_bkmk.txt"))
        let config = try XCTUnwrap(InterfaceFile.load(from: folder))
        let pdf = document()
        XCTAssertTrue(try InterfaceFile.apply(configuration: config, to: pdf).isEmpty)
        let url = folder.appendingPathComponent("labels.pdf")
        try InterfaceFile.write(document: pdf, to: url, configuration: config, layout: .continuous)
        let reopened = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertEqual(reopened.pageCount, 8)
        XCTAssertEqual((0..<8).map { reopened.page(at: $0)?.label ?? "" }, ["A", "B", "i", "ii", "iii", "1", "2", "3"])
        XCTAssertEqual(reopened.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String, "中文测试")
        XCTAssertEqual(BookmarkService.read(from: reopened).map(\.pageIndex), [0, 5])
        XCTAssertThrowsError(try InterfaceFile.write(document: pdf, to: url, configuration: nil))
    }
    func testExportLoadAndSaveDoNotOverwriteOriginal() throws {
        let folder = try directory(), source = folder.appendingPathComponent("original.pdf"), destination = folder.appendingPathComponent("copy.pdf")
        let pdf = document(); let original = pdf.dataRepresentation()!; try original.write(to: source)
        let entries: [BookmarkEntry] = [.init(title: "第 1 章", pageIndex: 2), .init(title: "Detail", pageIndex: 3, depth: 1)]
        try BookmarkService.saveCopy(source: source, destination: destination, entries: entries, metadata: .init(title: "Book"))
        XCTAssertEqual(try Data(contentsOf: source), original)
        XCTAssertThrowsError(try BookmarkService.saveCopy(source: source, destination: source, entries: entries))
        XCTAssertThrowsError(try BookmarkService.saveCopy(source: source, destination: destination, entries: entries))
        try InterfaceFile.export(entries: entries, metadata: .init(title: "Book"), basePage: 3, to: folder)
        let config = try XCTUnwrap(InterfaceFile.load(from: folder))
        XCTAssertEqual(config.bookmarks?.map(\.pageIndex), [2,3])
        XCTAssertEqual(config.metadata.title, "Book")
    }
    func testTextPagesAreSearchableAndInvalidSidecarsAreExplicit() throws {
        let folder = try directory()
        try Data("[TextPage]\nFiles=1\nF1=notes.txt\n[Font]\nFontSize=14\nMargin=0.75".utf8).write(to: folder.appendingPathComponent("FreePic2Pdf.itf"))
        XCTAssertThrowsError(try InterfaceFile.load(from: folder))
        try Data("This is searchable text. 可检索文字。".utf8).write(to: folder.appendingPathComponent("notes.txt"))
        let config = try XCTUnwrap(InterfaceFile.load(from: folder))
        let pdf = document(pages: 1); _ = try InterfaceFile.apply(configuration: config, to: pdf)
        XCTAssertEqual(pdf.pageCount, 2)
        XCTAssertTrue(pdf.page(at: 1)?.string?.contains("searchable text") == true)
    }
    func testExistingLabelsSurviveBookmarkEdit() throws {
        let folder = try directory(), source = folder.appendingPathComponent("labels.pdf"), result = folder.appendingPathComponent("edited.pdf")
        let config = InterfaceConfiguration(directory: folder, contentsPage: 3, textPage: 6)
        try InterfaceFile.write(document: document(), to: source, configuration: config)
        try BookmarkService.saveCopy(source: source, destination: result, entries: [.init(title: "Chapter", pageIndex: 5)])
        let reopened = try XCTUnwrap(PDFDocument(url: result))
        XCTAssertEqual(reopened.page(at: 2)?.label, "i")
        XCTAssertEqual(reopened.page(at: 5)?.label, "1")
    }
}
