import Foundation
import CoreFoundation
import AppKit
import CoreText
import PDFKit

public struct InterfaceConfiguration {
    public var directory: URL
    public var bookmarks: [BookmarkEntry]?
    public var metadata: PDFMetadata
    public var contentsPage: Int?
    public var textPage: Int?
    public var prefix1: String = ""
    public var prefix2: String = ""
    public var showBookmarks: Bool?
    public var showAll: Bool = true
    public var appendedTexts: [String]
    public var fontSize: Double = 12
    public var marginInches: Double = 0.75
    public var warnings: [String]
    public init(directory: URL, bookmarks: [BookmarkEntry]? = nil, metadata: PDFMetadata = .init(), contentsPage: Int? = nil, textPage: Int? = nil, appendedTexts: [String] = [], warnings: [String] = []) {
        self.directory = directory; self.bookmarks = bookmarks; self.metadata = metadata
        self.contentsPage = contentsPage; self.textPage = textPage; self.appendedTexts = appendedTexts; self.warnings = warnings
    }
}

public enum InterfaceError: LocalizedError {
    case malformed(String), unsupportedEncoding(String), missingFile(String), invalidPageLabels, serialization
    public var errorDescription: String? {
        switch self {
        case .malformed(let detail): return "Invalid interface file: \(detail)"
        case .unsupportedEncoding(let name): return "The text encoding could not be read: \(name)"
        case .missingFile(let name): return "The interface file references a missing file: \(name)"
        case .invalidPageLabels: return "Page label boundaries must be ordered and inside the PDF."
        case .serialization: return "The PDF catalog could not be updated safely. No file was saved."
        }
    }
}

public enum InterfaceFile {
    public static func readText(from url: URL, language: String? = nil) throws -> String {
        let data = try Data(contentsOf: url)
        if data.starts(with: [0xFF, 0xFE]), let text = String(data: data.dropFirst(2), encoding: .utf16LittleEndian) { return text }
        if data.starts(with: [0xFE, 0xFF]), let text = String(data: data.dropFirst(2), encoding: .utf16BigEndian) { return text }
        if let text = String(data: data, encoding: .utf8) { return text.trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF}")) }
        let encodings: [CFStringEncoding]
        switch language?.lowercased() {
        case "latin1": encodings = [CFStringBuiltInEncodings.windowsLatin1.rawValue]
        case "big5": encodings = [UInt32(CFStringEncodings.big5.rawValue)]
        case "jap": encodings = [UInt32(CFStringEncodings.shiftJIS.rawValue)]
        case "kor": encodings = [UInt32(CFStringEncodings.dosKorean.rawValue)]
        default: encodings = [UInt32(CFStringEncodings.GB_18030_2000.rawValue), CFStringBuiltInEncodings.windowsLatin1.rawValue]
        }
        for encoding in encodings {
            let nsEncoding = CFStringConvertEncodingToNSStringEncoding(encoding)
            if let text = String(data: data, encoding: String.Encoding(rawValue: nsEncoding)) { return text }
        }
        throw InterfaceError.unsupportedEncoding(url.lastPathComponent)
    }

    public static func load(from directory: URL) throws -> InterfaceConfiguration? {
        let url = directory.appendingPathComponent("FreePic2Pdf.itf")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let text = try readText(from: url)
        var sections: [String: [String: String]] = [:], section = ""
        for (index, rawLine) in text.components(separatedBy: .newlines).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix(";") || line.hasPrefix("#") { continue }
            if line.hasPrefix("[") && line.hasSuffix("]") { section = String(line.dropFirst().dropLast()).lowercased(); continue }
            guard !section.isEmpty, let separator = line.firstIndex(of: "=") else { throw InterfaceError.malformed("Line \(index + 1) must be a section or key=value.") }
            let key = line[..<separator].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { throw InterfaceError.malformed("Empty key at line \(index + 1).") }
            sections[section, default: [:]][key] = value
        }
        func value(_ section: String, _ key: String) -> String? { sections[section]?[key] }
        func integer(_ section: String, _ key: String, default defaultValue: Int? = nil) throws -> Int? {
            guard let text = value(section, key), !text.isEmpty else { return defaultValue }
            guard let result = Int(text) else { throw InterfaceError.malformed("\(section).\(key) must be an integer.") }; return result
        }
        func flag(_ section: String, _ key: String) throws -> Bool? {
            guard let number = try integer(section, key) else { return nil }
            guard number == 0 || number == 1 else { throw InterfaceError.malformed("\(section).\(key) must be 0 or 1.") }; return number == 1
        }
        var config = InterfaceConfiguration(directory: directory)
        config.metadata = PDFMetadata(title: value("info", "title"), author: value("info", "author"), subject: value("info", "subject"), keywords: value("info", "keywords"))
        config.contentsPage = try integer("main", "contentspage"); config.textPage = try integer("main", "textpage")
        config.showBookmarks = try flag("bkmk", "showbkmk"); config.showAll = try flag("bkmk", "showall") ?? true
        if let size = value("font", "fontsize"), !size.isEmpty {
            guard let number = Double(size), number.isFinite, (1...200).contains(number) else { throw InterfaceError.malformed("FontSize must be from 1 to 200 points.") }
            config.fontSize = number
        }
        if let margin = value("font", "margin"), !margin.isEmpty {
            guard let number = Double(margin), number.isFinite, (0...3).contains(number) else { throw InterfaceError.malformed("Margin must be from 0 to 3 inches.") }
            config.marginInches = number
        }
        let basePage = try integer("bkmk", "basepage", default: 1)!
        guard basePage >= 1 else { throw BookmarkError.invalidBasePage }
        let language = value("font", "language")
        func localFile(_ filename: String) throws -> URL {
            // Interface sidecars are deliberately restricted to the same directory.
            guard !filename.isEmpty, !filename.contains("/"), !filename.contains("\\"), filename != ".", filename != ".." else {
                throw InterfaceError.malformed("Referenced files must be in the same folder: \(filename)")
            }
            let file = directory.appendingPathComponent(filename)
            guard FileManager.default.fileExists(atPath: file.path) else { throw InterfaceError.missingFile(filename) }; return file
        }
        if let name = value("bkmk", "file"), !name.isEmpty {
            let bookmarkText = try readText(from: localFile(name), language: language)
            config.bookmarks = try BookmarkService.parse(text: bookmarkText, basePage: basePage)
            if try flag("bkmk", "addastext") == true { config.appendedTexts.append(bookmarkText) }
        }
        let textCount = try integer("textpage", "files", default: 0)!
        guard (0...1000).contains(textCount) else { throw InterfaceError.malformed("TextPage.Files is out of range.") }
        if textCount > 0 {
            for index in 1...textCount {
                guard let name = value("textpage", "f\(index)") else { throw InterfaceError.malformed("Missing TextPage.F\(index).") }
                config.appendedTexts.append(try readText(from: localFile(name), language: language))
            }
        }
        if !(sections["images"] ?? [:]).isEmpty { config.warnings.append("Interface image overlays are not supported; only source image pages were included.") }
        if let minWidth = value("main", "minwidth"), minWidth != "0", !minWidth.isEmpty { config.warnings.append("Interface MinWidth is not applied. The page size in the app is used.") }
        for section in sections.keys where !["images", "font", "textpage", "bkmk", "info", "main"].contains(section) { config.warnings.append("Unknown interface section: \(section)") }
        return config
    }

    @discardableResult public static func apply(configuration: InterfaceConfiguration, to document: PDFDocument) throws -> [String] {
        for text in configuration.appendedTexts {
            let extra = try textDocument(text: text, fontSize: configuration.fontSize, marginInches: configuration.marginInches)
            for index in 0..<extra.pageCount { if let page = extra.page(at: index) { document.insert(page, at: document.pageCount) } }
        }
        if let entries = configuration.bookmarks {
            try BookmarkService.apply(entries: entries, to: document)
            func setExpansion(_ parent: PDFOutline) {
                for index in 0..<parent.numberOfChildren { if let child = parent.child(at: index) { child.isOpen = configuration.showAll; setExpansion(child) } }
            }
            if let root = document.outlineRoot { setExpansion(root) }
        }
        BookmarkService.apply(metadata: configuration.metadata, to: document)
        _ = try pageLabels(configuration: configuration, pageCount: document.pageCount)
        return configuration.warnings
    }

    public static func write(document: PDFDocument, to destination: URL, configuration: InterfaceConfiguration?, layout: PDFLayout? = nil, preservingPageLabelsFrom source: URL? = nil) throws {
        guard !FileManager.default.fileExists(atPath: destination.path) else { throw BookmarkError.destinationExists }
        guard var data = document.dataRepresentation() else { throw BookmarkError.writeFailed }
        var values: [String: String] = [:]
        if let source, let original = CGPDFDocument(source as CFURL), let catalog = original.catalog {
            var labels: CGPDFDictionaryRef?
            if CGPDFDictionaryGetDictionary(catalog, "PageLabels", &labels), let labels {
                values["PageLabels"] = try PDFCatalogWriter.dictionary(labels)
            }
        }
        if let configuration {
            if let labels = try pageLabels(configuration: configuration, pageCount: document.pageCount) { values["PageLabels"] = labels }
            if let show = configuration.showBookmarks { values["PageMode"] = show ? "/UseOutlines" : "/UseNone" }
        }
        if let layout { values["PageLayout"] = layout == .single ? "/SinglePage" : layout == .continuous ? "/OneColumn" : "/TwoPageRight" }
        if !values.isEmpty { data = try PDFCatalogWriter.appending(values: values, to: data) }
        let temporary = destination.deletingLastPathComponent().appendingPathComponent(".foliopdf-\(UUID().uuidString).partial")
        defer { try? FileManager.default.removeItem(at: temporary) }
        try data.write(to: temporary, options: [.withoutOverwriting])
        // A completed file is published only after the full write succeeds.
        // FileManager refuses an existing destination; it never replaces a user file.
        try FileManager.default.moveItem(at: temporary, to: destination)
    }

    public static func export(entries: [BookmarkEntry], metadata: PDFMetadata = .init(), basePage: Int = 1, to directory: URL) throws {
        guard basePage >= 1 else { throw BookmarkError.invalidBasePage }
        let interfaceURL = directory.appendingPathComponent("FreePic2Pdf.itf"), bookmarksURL = directory.appendingPathComponent("FreePic2Pdf_bkmk.txt")
        guard !FileManager.default.fileExists(atPath: interfaceURL.path), !FileManager.default.fileExists(atPath: bookmarksURL.path) else { throw BookmarkError.destinationExists }
        var text = "[Bkmk]\nFile=FreePic2Pdf_bkmk.txt\nBasePage=\(basePage)\nShowBkmk=1\nShowAll=1\nAddAsText=0\n\n[Info]\n"
        for (name, value) in [("Title", metadata.title), ("Author", metadata.author), ("Subject", metadata.subject), ("Keywords", metadata.keywords)] {
            if let value { text += "\(name)=\(value.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\r", with: " "))\n" }
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(BookmarkService.serialize(entries: entries, basePage: basePage).utf8).write(to: bookmarksURL, options: .withoutOverwriting)
        do { try Data(text.utf8).write(to: interfaceURL, options: .withoutOverwriting) }
        catch { try? FileManager.default.removeItem(at: bookmarksURL); throw error }
    }

    private static func pageLabels(configuration: InterfaceConfiguration, pageCount: Int) throws -> String? {
        let contents = configuration.contentsPage, body = configuration.textPage
        guard contents != nil || body != nil else { return nil }
        for value in [contents, body].compactMap({ $0 }) { guard (1...pageCount).contains(value) else { throw InterfaceError.invalidPageLabels } }
        if let contents, let body, contents >= body { throw InterfaceError.invalidPageLabels }
        var segments: [(Int, String, String)] = []
        let firstBoundary = contents ?? body ?? 1
        if firstBoundary > 1 { segments.append((0, configuration.prefix1.isEmpty ? "A" : "D", configuration.prefix1)) }
        if let contents { segments.append((contents - 1, configuration.prefix2.isEmpty ? "r" : "D", configuration.prefix2)) }
        if let body { segments.append((body - 1, "D", "")) }
        if segments.isEmpty { segments.append((0, "D", "")) }
        let pairs = segments.map { index, style, prefix in
            "\(index) << /S /\(style) /St 1" + (prefix.isEmpty ? "" : " /P \(PDFCatalogWriter.pdfString(prefix))") + " >>"
        }.joined(separator: " ")
        return "<< /Nums [ \(pairs) ] >>"
    }

    private static func textDocument(text: String, fontSize: Double, marginInches: Double) throws -> PDFDocument {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else { throw BookmarkError.writeFailed }
        var media = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        guard let context = CGContext(consumer: consumer, mediaBox: &media, nil) else { throw BookmarkError.writeFailed }
        let font = CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
        let attributed = NSAttributedString(string: text.isEmpty ? " " : text, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font, .foregroundColor: NSColor.black])
        let setter = CTFramesetterCreateWithAttributedString(attributed)
        let inset = marginInches * 72
        let content = media.insetBy(dx: inset, dy: inset)
        guard content.width > fontSize * 2, content.height > fontSize * 2 else { throw InterfaceError.malformed("Text margins leave no space for text.") }
        var position = 0
        while position < attributed.length {
            context.beginPDFPage(nil)
            let path = CGPath(rect: content, transform: nil)
            let frame = CTFramesetterCreateFrame(setter, CFRange(location: position, length: 0), path, nil)
            CTFrameDraw(frame, context)
            let visible = CTFrameGetVisibleStringRange(frame)
            context.endPDFPage()
            guard visible.length > 0 else { throw InterfaceError.malformed("Text could not fit on a page.") }
            position += visible.length
        }
        context.closePDF()
        guard let document = PDFDocument(data: data as Data) else { throw BookmarkError.writeFailed }; return document
    }
}

/// Adds standard catalog entries to PDFKit's serialized PDF using an incremental xref update.
/// Original page streams, annotations, metadata and outline objects remain byte-for-byte unchanged.
enum PDFCatalogWriter {
    private final class DictionaryCollector {
        var entries: [(String, CGPDFObjectRef)] = []
    }
    static func dictionary(_ value: CGPDFDictionaryRef, depth: Int = 0) throws -> String {
        guard depth < 32 else { throw InterfaceError.serialization }
        let collected = DictionaryCollector()
        CGPDFDictionaryApplyFunction(value, { key, object, context in
            guard let context else { return }
            let collector = Unmanaged<DictionaryCollector>.fromOpaque(context).takeUnretainedValue()
            collector.entries.append((String(cString: key), object))
        }, Unmanaged.passUnretained(collected).toOpaque())
        let pairs = try collected.entries.map { key, value in
            "/" + name(key) + " " + (try object(value, depth: depth + 1))
        }
        return "<< " + pairs.joined(separator: " ") + " >>"
    }
    private static func name(_ value: String) -> String {
        value.utf8.map { byte in
            if byte >= 33 && byte <= 126 && ![35,37,40,41,47,60,62,91,93,123,125].contains(byte) { return String(UnicodeScalar(byte)) }
            return String(format: "#%02X", byte)
        }.joined()
    }
    private static func object(_ value: CGPDFObjectRef, depth: Int) throws -> String {
        guard depth < 32 else { throw InterfaceError.serialization }
        switch CGPDFObjectGetType(value) {
        case .null: return "null"
        case .boolean:
            var result: CGPDFBoolean = 0; guard CGPDFObjectGetValue(value, .boolean, &result) else { throw InterfaceError.serialization }; return result == 0 ? "false" : "true"
        case .integer:
            var result: CGPDFInteger = 0; guard CGPDFObjectGetValue(value, .integer, &result) else { throw InterfaceError.serialization }; return String(result)
        case .real:
            var result: CGPDFReal = 0; guard CGPDFObjectGetValue(value, .real, &result), result.isFinite else { throw InterfaceError.serialization }; return String(Double(result))
        case .name:
            var result: UnsafePointer<CChar>?
            guard CGPDFObjectGetValue(value, .name, &result), let result else { throw InterfaceError.serialization }; return "/" + name(String(cString: result))
        case .string:
            var result: CGPDFStringRef?
            guard CGPDFObjectGetValue(value, .string, &result), let result, let bytes = CGPDFStringGetBytePtr(result) else { throw InterfaceError.serialization }
            return "<" + (0..<CGPDFStringGetLength(result)).map { String(format: "%02X", bytes[$0]) }.joined() + ">"
        case .array:
            var result: CGPDFArrayRef?
            guard CGPDFObjectGetValue(value, .array, &result), let result else { throw InterfaceError.serialization }
            let values = try (0..<CGPDFArrayGetCount(result)).map { index -> String in
                var child: CGPDFObjectRef?; guard CGPDFArrayGetObject(result, index, &child), let child else { throw InterfaceError.serialization }; return try object(child, depth: depth + 1)
            }
            return "[ " + values.joined(separator: " ") + " ]"
        case .dictionary:
            var result: CGPDFDictionaryRef?
            guard CGPDFObjectGetValue(value, .dictionary, &result), let result else { throw InterfaceError.serialization }; return try dictionary(result, depth: depth + 1)
        default: throw InterfaceError.serialization
        }
    }
    static func pdfString(_ text: String) -> String {
        let data = text.data(using: .utf16BigEndian) ?? Data()
        return "<FEFF" + data.map { String(format: "%02X", $0) }.joined() + ">"
    }

    static func appending(values: [String: String], to data: Data) throws -> Data {
        let bytes = data
        // Only decode the trailer area. Scanned books can contain gigabytes of image streams.
        let trailerData = data.suffix(min(data.count, 1_048_576))
        guard let source = String(data: trailerData, encoding: .isoLatin1) else { throw InterfaceError.serialization }
        func captures(_ pattern: String, in text: String, last: Bool = false) -> [String]? {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return nil }
            let results = regex.matches(in: text, range: NSRange(location: 0, length: (text as NSString).length))
            guard let match = last ? results.last : results.first else { return nil }
            return (1..<match.numberOfRanges).map { (text as NSString).substring(with: match.range(at: $0)) }
        }
        guard let previousText = captures("startxref\\s+(\\d+)\\s+%%EOF", in: source, last: true)?.first,
              let previous = Int(previousText), previous < bytes.count,
              let trailerRange = source.range(of: "trailer", options: .backwards) else { throw InterfaceError.serialization }
        let trailer = String(source[trailerRange.lowerBound...])
        guard let root = captures("/Root\\s+(\\d+)\\s+(\\d+)\\s+R", in: trailer),
              let sizeText = captures("/Size\\s+(\\d+)", in: trailer)?.first,
              let size = Int(sizeText), let number = Int(root[0]), let generation = Int(root[1]) else { throw InterfaceError.serialization }
        let objectHeader = Data("\n\(number) \(generation) obj".utf8)
        let alternateHeader = Data("\r\(number) \(generation) obj".utf8)
        let objectRange = data.range(of: objectHeader, options: .backwards) ?? data.range(of: alternateHeader, options: .backwards)
        guard let objectRange else { throw InterfaceError.serialization }
        var parser = PDFValueReader(bytes: bytes, position: objectRange.upperBound)
        parser.skipSpace()
        let start = parser.position
        let end = try parser.valueEnd()
        guard start + 1 < bytes.count, bytes[start] == 60, bytes[start + 1] == 60 else { throw InterfaceError.serialization }
        var entries: [(String, Range<Int>)] = []
        parser.position = start + 2
        while parser.position < end - 2 {
            parser.skipSpace(); if parser.position >= end - 2 { break }
            let keyStart = parser.position
            guard bytes[keyStart] == 47 else { throw InterfaceError.serialization }
            let keyEnd = try parser.valueEnd()
            let key = String(bytes: bytes[(keyStart + 1)..<keyEnd], encoding: .ascii) ?? ""
            parser.skipSpace(); let valueEnd = try parser.valueEnd()
            entries.append((key, keyStart..<valueEnd))
        }
        var dictionary = Data("<<\n".utf8)
        for (key, range) in entries where values[key] == nil { dictionary.append(data.subdata(in: range)); dictionary.append(Data("\n".utf8)) }
        for key in values.keys.sorted() { dictionary.append(Data("/\(key) \(values[key]!)\n".utf8)) }
        dictionary.append(Data(">>".utf8))
        var result = data; result.append(Data("\n".utf8)); let offset = result.count
        result.append(Data("\(number) \(generation) obj\n".utf8)); result.append(dictionary); result.append(Data("\nendobj\n".utf8))
        let xref = result.count
        var trailerEntries = "/Size \(max(size, number + 1)) /Root \(number) \(generation) R /Prev \(previous)"
        if let info = captures("/Info\\s+(\\d+)\\s+(\\d+)\\s+R", in: trailer) { trailerEntries += " /Info \(info[0]) \(info[1]) R" }
        if let id = captures("/ID\\s*(\\[\\s*<[0-9A-Fa-f\\s]+>\\s*<[0-9A-Fa-f\\s]+>\\s*\\])", in: trailer)?.first { trailerEntries += " /ID \(id)" }
        result.append(Data("xref\n\(number) 1\n\(String(format: "%010d %05d n \n", offset, generation))trailer\n<< \(trailerEntries) >>\nstartxref\n\(xref)\n%%EOF\n".utf8))
        guard PDFDocument(data: result) != nil else { throw InterfaceError.serialization }; return result
    }
}

private struct PDFValueReader {
    let bytes: Data
    var position: Int
    mutating func skipSpace() {
        while position < bytes.count {
            if [0, 9, 10, 12, 13, 32].contains(bytes[position]) { position += 1 }
            else if bytes[position] == 37 { while position < bytes.count && bytes[position] != 10 && bytes[position] != 13 { position += 1 } }
            else { break }
        }
    }
    private func isDelimiter(_ byte: UInt8) -> Bool { [0,9,10,12,13,32,40,41,60,62,91,93,123,125,47,37].contains(byte) }
    mutating func valueEnd() throws -> Int {
        skipSpace(); guard position < bytes.count else { throw InterfaceError.serialization }
        let first = bytes[position]; position += 1
        if first == 40 {
            var nesting = 1
            while position < bytes.count && nesting > 0 {
                let char = bytes[position]; position += 1
                if char == 92 { if position < bytes.count { position += 1 } }
                else if char == 40 { nesting += 1 } else if char == 41 { nesting -= 1 }
            }
            guard nesting == 0 else { throw InterfaceError.serialization }
        } else if first == 60 && position < bytes.count && bytes[position] == 60 {
            position += 1
            while true {
                skipSpace(); guard position + 1 < bytes.count else { throw InterfaceError.serialization }
                if bytes[position] == 62 && bytes[position + 1] == 62 { position += 2; break }
                _ = try valueEnd()
            }
        } else if first == 60 {
            while position < bytes.count && bytes[position] != 62 { position += 1 }
            guard position < bytes.count else { throw InterfaceError.serialization }; position += 1
        } else if first == 91 {
            while true { skipSpace(); guard position < bytes.count else { throw InterfaceError.serialization }; if bytes[position] == 93 { position += 1; break }; _ = try valueEnd() }
        } else {
            while position < bytes.count && !isDelimiter(bytes[position]) { position += 1 }
            if first >= 48 && first <= 57 {
                let saved = position; skipSpace()
                let secondStart = position
                while position < bytes.count && bytes[position] >= 48 && bytes[position] <= 57 { position += 1 }
                if position > secondStart { skipSpace(); if position < bytes.count && bytes[position] == 82 { position += 1 } else { position = saved } }
                else { position = saved }
            }
        }
        return position
    }
}
