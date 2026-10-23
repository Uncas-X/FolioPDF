import Foundation
import CoreGraphics

public enum SortOrder: String, Codable, CaseIterable, Sendable { case manual = "Manual", name = "Name", number = "Page number", pdg = "Book order" }
public enum OutputMode: String, Codable, CaseIterable, Sendable { case combined = "One PDF", perFile = "One PDF per image file", perFolder = "One PDF per folder" }
public enum PaperSize: String, Codable, CaseIterable, Sendable {
    case image = "Original size", fixedWidth = "Fixed width", a4 = "A4", a5 = "A5", a3 = "A3", b5 = "B5", letter = "US Letter", legal = "US Legal", custom = "Custom"
}
public enum ImageCompression: String, Codable, CaseIterable, Sendable { case lossless = "Lossless", jpeg = "Compact JPEG" }
public enum PDFLayout: String, Codable, CaseIterable, Sendable { case single = "Single page", continuous = "Continuous", twoPages = "Two pages" }
public struct PageMargins: Codable, Equatable, Sendable {
    public var top: Double = 0; public var bottom: Double = 0; public var left: Double = 0; public var right: Double = 0
    public init(top: Double = 0, bottom: Double = 0, left: Double = 0, right: Double = 0) { self.top = top; self.bottom = bottom; self.left = left; self.right = right }
}
public struct ConversionSettings: Codable, Equatable, Sendable {
    public var outputMode: OutputMode = .combined
    public var paperSize: PaperSize = .image
    public var landscape: Bool = false
    public var widthMM: Double = 210
    public var heightMM: Double = 297
    public var margins = PageMargins()
    public var dpi: Double = 300
    public var useImageDPI: Bool = true
    public var enlargeSmallImages: Bool = false
    public var preserveTransparency: Bool = true
    public var compression: ImageCompression = .lossless
    public var jpegQuality: Double = 0.82
    public var ocrEnabled: Bool = false
    public var ocrLanguages: [String] = []
    public var ocrLanguageCorrection: Bool = true
    public var title: String = ""
    public var author: String = ""
    public var subject: String = ""
    public var keywords: String = ""
    public var addFileBookmarks: Bool = true
    public var useInterfaceFile: Bool = true
    public var layout: PDFLayout = .continuous
    public init() {}
}
public struct ImageAsset: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let frameCount: Int
    public let fileSize: Int64
    public let dpi: Double?
    public var name: String { url.lastPathComponent }
    public var folder: URL { url.deletingLastPathComponent() }
    public init(id: UUID = UUID(), url: URL, pixelWidth: Int, pixelHeight: Int, frameCount: Int = 1, fileSize: Int64 = 0, dpi: Double? = nil) {
        self.id = id; self.url = url; self.pixelWidth = pixelWidth; self.pixelHeight = pixelHeight; self.frameCount = frameCount; self.fileSize = fileSize; self.dpi = dpi
    }
}
public struct ConversionProgress: Sendable {
    public let completedPages: Int
    public let totalPages: Int
    public let currentFile: String
    public init(completedPages: Int, totalPages: Int, currentFile: String) { self.completedPages = completedPages; self.totalPages = totalPages; self.currentFile = currentFile }
}
public struct ConversionResult: Sendable {
    public var outputs: [URL]
    public var warnings: [String]
    public var pageCount: Int
    public init(outputs: [URL] = [], warnings: [String] = [], pageCount: Int = 0) { self.outputs = outputs; self.warnings = warnings; self.pageCount = pageCount }
}
