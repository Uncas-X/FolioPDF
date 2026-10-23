import Foundation
import PDFKit

public enum BookmarkTargetKind: String, Codable, Sendable {
    case page, namedAction, url, remotePDF, unresolved
}

/// Page indices are zero based; depths are zero based and contiguous.
public struct BookmarkEntry: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var pageIndex: Int
    public var depth: Int
    public var targetKind: BookmarkTargetKind
    public var targetValue: String?
    public var destinationX: Double?
    public var destinationY: Double?
    public var zoom: Double?
    public init(id: UUID = UUID(), title: String, pageIndex: Int, depth: Int = 0, targetKind: BookmarkTargetKind = .page, targetValue: String? = nil, destinationX: Double? = nil, destinationY: Double? = nil, zoom: Double? = nil) {
        self.id = id; self.title = title; self.pageIndex = pageIndex; self.depth = depth
        self.targetKind = targetKind; self.targetValue = targetValue
        self.destinationX = destinationX; self.destinationY = destinationY; self.zoom = zoom
    }
}

public struct BookmarkReadResult {
    public let entries: [BookmarkEntry]
    public let warnings: [String]
}

public struct PDFMetadata: Codable, Equatable, Sendable {
    public var title: String?
    public var author: String?
    public var subject: String?
    public var keywords: String?
    public init(title: String? = nil, author: String? = nil, subject: String? = nil, keywords: String? = nil) {
        self.title = title; self.author = author; self.subject = subject; self.keywords = keywords
    }
}

public enum BookmarkError: LocalizedError {
    case invalidBasePage, invalidLine(Int, String), invalidHierarchy(Int), invalidPage(Int, Int), unresolvedTarget(String), unreadablePDF, encryptedPDF, sameFile, destinationExists, writeFailed
    public var errorDescription: String? {
        switch self {
        case .invalidBasePage: return "The base page must be at least 1."
        case .invalidLine(let line, let reason): return "Bookmark line \(line): \(reason)"
        case .invalidHierarchy(let line): return "Bookmark \(line) skips a hierarchy level. The first bookmark must be at level 1."
        case .invalidPage(let line, let page): return "Bookmark \(line) points to unavailable page \(page)."
        case .unresolvedTarget(let target): return "This destination cannot be resolved: \(target). Set a page target before saving."
        case .unreadablePDF: return "The PDF could not be opened."
        case .encryptedPDF: return "Encrypted PDFs are not supported for bookmark editing."
        case .sameFile: return "Choose a new filename. The original PDF will not be overwritten."
        case .destinationExists: return "A file already exists at this destination. Choose a new filename."
        case .writeFailed: return "The PDF could not be saved."
        }
    }
}

public enum BookmarkService {
    private static let namedActions: [String: PDFActionNamedName] = [
        "NextPage": .nextPage, "PrevPage": .previousPage, "FirstPage": .firstPage, "LastPage": .lastPage,
        "GoBack": .goBack, "GoForward": .goForward, "GoToPage": .goToPage, "Find": .find, "Print": .print
    ]

    public static func read(from document: PDFDocument) -> [BookmarkEntry] { inspect(from: document).entries }

    public static func inspect(from document: PDFDocument) -> BookmarkReadResult {
        var entries: [BookmarkEntry] = [], warnings: [String] = []
        guard let root = document.outlineRoot else { return BookmarkReadResult(entries: [], warnings: []) }
        var visited = Set<ObjectIdentifier>()
        func visit(_ parent: PDFOutline, depth: Int) {
            guard depth < 128, visited.insert(ObjectIdentifier(parent)).inserted else {
                warnings.append("A cyclic or excessively deep bookmark branch was skipped."); return
            }
            for index in 0..<parent.numberOfChildren {
                guard let node = parent.child(at: index) else { continue }
                var entry = BookmarkEntry(title: node.label ?? "Untitled", pageIndex: 0, depth: depth)
                if let action = node.action as? PDFActionNamed {
                    entry.targetKind = .namedAction
                    entry.targetValue = namedActions.first { $0.value == action.name }?.key
                    if entry.targetValue == nil { entry.targetKind = .unresolved; entry.targetValue = "Named action \(action.name.rawValue)" }
                } else if let action = node.action as? PDFActionURL {
                    entry.targetKind = .url; entry.targetValue = action.url?.absoluteString
                } else if let action = node.action as? PDFActionRemoteGoTo {
                    entry.targetKind = .remotePDF; entry.pageIndex = action.pageIndex
                    // PDFKit's nonnull URL annotation is incorrect for unresolved remote files.
                    // KVC keeps a missing Objective-C URL optional instead of trapping in the Swift bridge.
                    if let url = action.value(forKey: "URL") as? URL { entry.targetValue = url.path }
                    else { entry.targetKind = .unresolved; entry.targetValue = "Unresolved external PDF destination" }
                    entry.destinationX = finite(action.point.x); entry.destinationY = finite(action.point.y)
                } else if let destination = (node.action as? PDFActionGoTo)?.destination ?? node.destination, let page = destination.page {
                    let pageIndex = document.index(for: page)
                    if pageIndex == NSNotFound { entry.targetKind = .unresolved; entry.targetValue = "Page not in document" }
                    else {
                        entry.pageIndex = pageIndex; entry.destinationX = finite(destination.point.x)
                        entry.destinationY = finite(destination.point.y); entry.zoom = finite(destination.zoom)
                    }
                } else {
                    entry.targetKind = .unresolved; entry.targetValue = node.action?.type ?? "No page destination"
                }
                if entry.targetKind == .unresolved { warnings.append("Unsupported bookmark destination: \(entry.title). Assign a page or remove it before saving.") }
                if entry.targetKind == .remotePDF { warnings.append("External PDF targets cannot be written reliably by PDFKit. Assign a local PDF page instead.") }
                entries.append(entry); visit(node, depth: depth + 1)
            }
        }
        visit(root, depth: 0)
        if entries.contains(where: { $0.targetKind == .page }) {
            warnings.append("PDFKit resolves named destinations to page targets. Saving keeps the resolved pages, coordinates and zoom, but does not preserve the original destination names. Text export omits coordinates and zoom; use JSON to retain them.")
        }
        return BookmarkReadResult(entries: entries, warnings: warnings)
    }

    private static func finite(_ value: CGFloat) -> Double? { value.isFinite && abs(value) < 1e20 ? Double(value) : nil }

    public static func parse(text: String, basePage: Int = 1) throws -> [BookmarkEntry] {
        guard basePage >= 1 else { throw BookmarkError.invalidBasePage }
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n").components(separatedBy: "\n")
        var entries: [BookmarkEntry] = []
        for (lineIndex, raw) in lines.enumerated() {
            if raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            let line = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF}"))
            let depth = line.prefix { $0 == "\t" }.count
            let pieces = String(line.dropFirst(depth)).components(separatedBy: "\t")
            guard pieces.count >= 2 else { throw BookmarkError.invalidLine(lineIndex + 1, "Use a TAB between title and destination.") }
            let title = pieces[0].trimmingCharacters(in: .whitespaces)
            let target = pieces[1].trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty, !target.isEmpty else { throw BookmarkError.invalidLine(lineIndex + 1, "Title and destination are required.") }
            guard depth <= (entries.last?.depth ?? -1) + 1 else { throw BookmarkError.invalidHierarchy(lineIndex + 1) }
            var entry = BookmarkEntry(title: title, pageIndex: 0, depth: depth)
            if let relative = Int(target) {
                guard relative != 0 else { throw BookmarkError.invalidLine(lineIndex + 1, "Page 0 is invalid.") }
                let (sum, overflow) = basePage.addingReportingOverflow(relative)
                guard !overflow else { throw BookmarkError.invalidLine(lineIndex + 1, "Page number is too large.") }
                let absolute = relative > 0 ? sum - 1 : sum
                guard absolute >= 1 else { throw BookmarkError.invalidLine(lineIndex + 1, "Target precedes the first PDF page.") }
                entry.pageIndex = absolute - 1
            } else if target.hasPrefix("!") {
                entry.targetKind = .namedAction; entry.targetValue = String(target.dropFirst())
                guard namedActions[entry.targetValue!] != nil else { throw BookmarkError.invalidLine(lineIndex + 1, "Unsupported named action: \(target)") }
            } else if target.hasPrefix("^") {
                entry.targetKind = .remotePDF; entry.targetValue = String(target.dropFirst())
                let page = pieces.count > 2 ? Int(pieces[2]) : 1
                guard let page, page >= 1 else { throw BookmarkError.invalidLine(lineIndex + 1, "External PDF page must be positive.") }
                entry.pageIndex = page - 1
            } else if target.hasPrefix("https://") || target.hasPrefix("http://") || target.hasPrefix("mailto:") {
                entry.targetKind = .url; entry.targetValue = target
            } else {
                // Preserve the spelling for JSON/text export, but never silently convert an unresolved destination.
                entry.targetKind = .unresolved; entry.targetValue = target
            }
            if pieces.count > 2 && entry.targetKind != .remotePDF { throw BookmarkError.invalidLine(lineIndex + 1, "Unexpected extra TAB-separated fields.") }
            entries.append(entry)
        }
        return entries
    }

    public static func serialize(entries: [BookmarkEntry], basePage: Int = 1) -> String {
        let base = max(1, basePage)
        return entries.map { entry in
            let target: String
            switch entry.targetKind {
            case .page:
                let absolute = entry.pageIndex + 1
                target = String(absolute >= base ? absolute - base + 1 : absolute - base)
            case .namedAction: target = "!" + (entry.targetValue ?? "")
            case .remotePDF: target = "^" + (entry.targetValue ?? "") + "\t" + String(entry.pageIndex + 1)
            case .url, .unresolved: target = entry.targetValue ?? ""
            }
            return String(repeating: "\t", count: max(0, entry.depth)) + entry.title + "\t" + target
        }.joined(separator: "\n")
    }

    public static func validate(entries: [BookmarkEntry], pageCount: Int) throws {
        for (index, entry) in entries.enumerated() {
            guard !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !entry.title.contains("\t"), !entry.title.contains("\n"), !entry.title.contains("\r") else {
                throw BookmarkError.invalidLine(index + 1, "Use a non-empty title without tabs or line breaks.")
            }
            guard entry.depth >= 0, entry.depth <= (index == 0 ? 0 : entries[index - 1].depth + 1) else { throw BookmarkError.invalidHierarchy(index + 1) }
            if entry.targetKind == .page && !(0..<pageCount).contains(entry.pageIndex) { throw BookmarkError.invalidPage(index + 1, entry.pageIndex + 1) }
            if entry.targetKind == .unresolved { throw BookmarkError.unresolvedTarget(entry.targetValue ?? entry.title) }
            if entry.targetKind == .namedAction && namedActions[entry.targetValue ?? ""] == nil { throw BookmarkError.unresolvedTarget(entry.targetValue ?? entry.title) }
            if entry.targetKind == .remotePDF { throw BookmarkError.invalidLine(index + 1, "External PDF targets cannot be written reliably by PDFKit. Assign a local PDF page instead.") }
            if entry.targetKind == .url && URL(string: entry.targetValue ?? "") == nil { throw BookmarkError.unresolvedTarget(entry.title) }
        }
    }

    public static func apply(entries: [BookmarkEntry], to document: PDFDocument) throws {
        try validate(entries: entries, pageCount: document.pageCount)
        let root = PDFOutline()
        var parents: [PDFOutline] = [root]
        for entry in entries {
            while parents.count > entry.depth + 1 { parents.removeLast() }
            let node = PDFOutline(); node.label = entry.title; node.isOpen = true
            switch entry.targetKind {
            case .page:
                guard let page = document.page(at: entry.pageIndex) else { throw BookmarkError.invalidPage(0, entry.pageIndex + 1) }
                let rect = page.bounds(for: .mediaBox)
                let destination = PDFDestination(page: page, at: CGPoint(x: entry.destinationX ?? rect.minX, y: entry.destinationY ?? rect.maxY))
                if let zoom = entry.zoom, zoom.isFinite, zoom > 0 { destination.zoom = zoom }
                node.destination = destination
            case .namedAction: node.action = PDFActionNamed(name: namedActions[entry.targetValue!]!)
            case .url: node.action = PDFActionURL(url: URL(string: entry.targetValue!)!)
            case .remotePDF:
                throw BookmarkError.unresolvedTarget(entry.targetValue ?? entry.title)
            case .unresolved: throw BookmarkError.unresolvedTarget(entry.targetValue ?? entry.title)
            }
            let parent = parents.last!; parent.insertChild(node, at: parent.numberOfChildren); parents.append(node)
        }
        document.outlineRoot = entries.isEmpty ? nil : root
    }

    public static func apply(metadata: PDFMetadata, to document: PDFDocument) {
        var attributes = document.documentAttributes ?? [:]
        if let value = metadata.title { attributes[PDFDocumentAttribute.titleAttribute] = value }
        if let value = metadata.author { attributes[PDFDocumentAttribute.authorAttribute] = value }
        if let value = metadata.subject { attributes[PDFDocumentAttribute.subjectAttribute] = value }
        if let value = metadata.keywords { attributes[PDFDocumentAttribute.keywordsAttribute] = value.components(separatedBy: CharacterSet(charactersIn: ",;，；")).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty } }
        document.documentAttributes = attributes
    }

    public static func saveCopy(source: URL, destination: URL, entries: [BookmarkEntry], metadata: PDFMetadata? = nil) throws {
        guard source.standardizedFileURL.resolvingSymlinksInPath() != destination.standardizedFileURL.resolvingSymlinksInPath() else { throw BookmarkError.sameFile }
        guard !FileManager.default.fileExists(atPath: destination.path) else { throw BookmarkError.destinationExists }
        guard let document = PDFDocument(url: source) else { throw BookmarkError.unreadablePDF }
        guard !document.isEncrypted else { throw BookmarkError.encryptedPDF }
        try apply(entries: entries, to: document)
        if let metadata { apply(metadata: metadata, to: document) }
        try InterfaceFile.write(document: document, to: destination, configuration: nil, preservingPageLabelsFrom: source)
    }

    public static func readJSON(from url: URL) throws -> [BookmarkEntry] { try JSONDecoder().decode([BookmarkEntry].self, from: Data(contentsOf: url)) }
    public static func jsonData(entries: [BookmarkEntry]) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; return try encoder.encode(entries)
    }
}
