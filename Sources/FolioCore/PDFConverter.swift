import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers
import Vision
import CoreML
import PDFKit

/// A batch can finish several independent PDFs before cancellation or an error.
/// Their atomic outputs remain valid and are returned here so the UI can reveal them.
public struct ConversionInterrupted: Error, LocalizedError {
    public let partialResult: ConversionResult
    public let underlying: Error
    public var isCancelled: Bool { underlying is CancellationError }
    public init(partialResult: ConversionResult, underlying: Error) {
        self.partialResult = partialResult
        self.underlying = underlying
    }
    public var errorDescription: String? {
        "\(partialResult.outputs.count) PDF(s) were saved before conversion stopped. \(underlying.localizedDescription)"
    }
}

public enum PDFConverter {
    /// Work is intentionally isolated from the main actor, including decoding and Vision requests.
    public static func convert(assets: [ImageAsset], settings: ConversionSettings, destination: URL,
                               encryption: PDFEncryptionOptions? = nil,
                               progress: @escaping @Sendable (ConversionProgress) -> Void) async throws -> ConversionResult {
        let cancellation = ConversionCancellation()
        let worker = Task.detached(priority: .userInitiated) {
            try perform(assets: assets, settings: settings, destination: destination, encryption: encryption, cancellation: cancellation, progress: progress)
        }
        return try await withTaskCancellationHandler(operation: {
            try await worker.value
        }, onCancel: {
            cancellation.cancel()
            worker.cancel()
        })
    }

    private struct Group {
        var assets: [ImageAsset]
        var proposedURL: URL
    }

    private static func perform(assets: [ImageAsset], settings: ConversionSettings, destination: URL,
                                encryption: PDFEncryptionOptions?,
                                cancellation: ConversionCancellation,
                                progress: @escaping @Sendable (ConversionProgress) -> Void) throws -> ConversionResult {
        guard !assets.isEmpty else { throw ConversionError.noImages }
        try cancellation.check()
        if let encryption { try PDFEncryption.validate(options: encryption) }
        guard settings.jpegQuality.isFinite, (0...1).contains(settings.jpegQuality) else {
            throw ConversionError.invalidSettings("JPEG quality must be between 0 and 1.")
        }
        let checkedAssets = try assets.map { try ImagePipeline.inspect($0.url) }
        if settings.ocrEnabled { try validateOCRLanguages(settings.ocrLanguages) }
        let groups = makeGroups(checkedAssets, settings: settings, destination: destination)
        let total = checkedAssets.reduce(0) { $0 + $1.frameCount }
        var completed = 0
        var result = ConversionResult()
        for group in groups {
            do {
                try cancellation.check()
                let directory = group.proposedURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                // Unencrypted intermediates for protected exports live in an owner-only directory.
                // Keeping it on the destination volume allows atomic publication of the encrypted file.
                let workDirectory = encryption == nil ? directory : directory.appendingPathComponent(".folio-\(UUID().uuidString)", isDirectory: true)
                if encryption != nil {
                    try FileManager.default.createDirectory(at: workDirectory, withIntermediateDirectories: false,
                                                            attributes: [.posixPermissions: 0o700])
                }
                let temporary = workDirectory.appendingPathComponent(".folio-\(UUID().uuidString).pdf")
                let styled = workDirectory.appendingPathComponent(".folio-\(UUID().uuidString)-final.pdf")
                let encrypted = workDirectory.appendingPathComponent(".folio-\(UUID().uuidString)-encrypted.pdf")
                defer {
                    try? FileManager.default.removeItem(at: temporary)
                    try? FileManager.default.removeItem(at: styled)
                    try? FileManager.default.removeItem(at: encrypted)
                    if encryption != nil { try? FileManager.default.removeItem(at: workDirectory) }
                }
                var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
                let metadata: [String: Any] = [
                    kCGPDFContextTitle as String: settings.title.isEmpty ? group.proposedURL.deletingPathExtension().lastPathComponent : settings.title,
                    kCGPDFContextAuthor as String: settings.author,
                    kCGPDFContextSubject as String: settings.subject,
                    kCGPDFContextKeywords as String: settings.keywords,
                    kCGPDFContextCreator as String: "FolioPDF · macOS"
                ]
                guard let context = CGContext(temporary as CFURL, mediaBox: &mediaBox, metadata as CFDictionary) else {
                    throw ConversionError.outputFailure(directory.path)
                }
                var closed = false
                defer { if !closed { context.closePDF() } }
                var outlines = [[String: Any]]()
                var groupPages = 0
                for asset in group.assets {
                    try cancellation.check()
                    if settings.addFileBookmarks {
                        outlines.append([kCGPDFOutlineTitle as String: asset.url.deletingPathExtension().lastPathComponent,
                                         kCGPDFOutlineDestination as String: groupPages + 1])
                    }
                    var transparencyWarning = false
                    for frameIndex in 0..<asset.frameCount {
                        try cancellation.check()
                        progress(ConversionProgress(completedPages: completed, totalPages: total, currentFile: asset.name))
                        try autoreleasepool {
                            let frame = try ImagePipeline.frame(at: frameIndex, of: asset.url)
                            let geometry = try PageGeometry.calculate(pixelWidth: frame.image.width, pixelHeight: frame.image.height,
                                                                      imageDPI: frame.dpi, settings: settings)
                            var box = geometry.mediaBox
                            let boxData = Data(bytes: &box, count: MemoryLayout<CGRect>.size)
                            context.beginPDFPage([kCGPDFContextMediaBox as String: boxData] as CFDictionary)
                            defer { context.endPDFPage() }
                            if !settings.preserveTransparency {
                                context.setFillColor(CGColor(gray: 1, alpha: 1))
                                context.fill(box)
                            }
                            let needsAlpha = settings.preserveTransparency && hasAlpha(frame.image)
                            let rendered: CGImage
                            if settings.compression == .jpeg && !needsAlpha {
                                rendered = try jpegImage(frame.image, quality: settings.jpegQuality)
                            } else if !settings.preserveTransparency && hasAlpha(frame.image) {
                                rendered = try flattened(frame.image)
                            } else {
                                rendered = frame.image
                                if settings.compression == .jpeg && needsAlpha { transparencyWarning = true }
                            }
                            context.interpolationQuality = .high
                            context.draw(rendered, in: geometry.imageRect)
                            if settings.ocrEnabled {
                                do {
                                    let recognized = try recognize(frame.image, settings: settings, cancellation: cancellation)
                                    try cancellation.check()
                                    drawInvisibleText(recognized, in: geometry.imageRect, context: context)
                                } catch is CancellationError {
                                    throw CancellationError()
                                } catch {
                                    try cancellation.check()
                                    result.warnings.append("OCR failed for \(asset.name), page \(frameIndex + 1): \(error.localizedDescription). The page was included without searchable text.")
                                }
                            }
                        }
                        completed += 1
                        groupPages += 1
                        progress(ConversionProgress(completedPages: completed, totalPages: total, currentFile: asset.name))
                    }
                    if transparencyWarning {
                        result.warnings.append("\(asset.name): lossless compression was used to preserve transparency; JPEG cannot store an alpha channel.")
                    }
                }
                if !outlines.isEmpty {
                    CGPDFContextSetOutline(context, [kCGPDFOutlineChildren as String: outlines] as CFDictionary)
                }
                context.closePDF()
                closed = true
                try cancellation.check()
                guard let document = PDFDocument(url: temporary), document.pageCount == groupPages else {
                    throw ConversionError.outputFailure("The generated document failed page-count validation.")
                }
                var configuration: InterfaceConfiguration?
                if settings.useInterfaceFile {
                    let folders = Set(group.assets.map { $0.folder.standardizedFileURL })
                    if folders.count == 1, let folder = folders.first {
                        configuration = try InterfaceFile.load(from: folder)
                        if let configuration {
                            result.warnings += try InterfaceFile.apply(configuration: configuration, to: document)
                        }
                    } else {
                        result.warnings.append("Interface files were skipped because this output combines images from multiple folders. Use one PDF per folder to keep page references aligned.")
                    }
                }
                let finalPageCount = document.pageCount
                try InterfaceFile.write(document: document, to: styled, configuration: configuration, layout: settings.layout)
                try cancellation.check()
                guard let validated = CGPDFDocument(styled as CFURL), validated.numberOfPages == finalPageCount else {
                    throw ConversionError.outputFailure("The final PDF could not be validated.")
                }
                let publishable: URL
                if let encryption {
                    try PDFEncryption.encrypt(source: styled, destination: encrypted, options: encryption)
                    publishable = encrypted
                } else { publishable = styled }
                try cancellation.check()
                let output = try publishWithoutReplacing(publishable, proposedURL: group.proposedURL)
                result.outputs.append(output)
                result.pageCount += finalPageCount
            } catch {
                if !result.outputs.isEmpty {
                    throw ConversionInterrupted(partialResult: result, underlying: error)
                }
                throw error
            }
        }
        return result
    }

    private static func makeGroups(_ assets: [ImageAsset], settings: ConversionSettings, destination: URL) -> [Group] {
        switch settings.outputMode {
        case .combined:
            let output = destination.pathExtension.lowercased() == "pdf" ? destination : destination.appendingPathExtension("pdf")
            return [Group(assets: assets, proposedURL: output)]
        case .perFile:
            return assets.map { Group(assets: [$0], proposedURL: destination.appendingPathComponent($0.url.deletingPathExtension().lastPathComponent).appendingPathExtension("pdf")) }
        case .perFolder:
            var order = [URL]()
            var grouped = [URL: [ImageAsset]]()
            for asset in assets {
                let folder = asset.folder.standardizedFileURL
                if grouped[folder] == nil { order.append(folder) }
                grouped[folder, default: []].append(asset)
            }
            return order.map { folder in
                Group(assets: grouped[folder] ?? [], proposedURL: destination.appendingPathComponent(folder.lastPathComponent.isEmpty ? "Images" : folder.lastPathComponent).appendingPathExtension("pdf"))
            }
        }
    }

    private static func publishWithoutReplacing(_ temporary: URL, proposedURL: URL) throws -> URL {
        let fm = FileManager.default
        var suffix = 1
        while suffix < 100_000 {
            let candidate = suffix == 1 ? proposedURL : proposedURL.deletingPathExtension()
                .deletingLastPathComponent().appendingPathComponent("\(proposedURL.deletingPathExtension().lastPathComponent) (\(suffix))").appendingPathExtension("pdf")
            if !fm.fileExists(atPath: candidate.path) {
                do {
                    // Same-directory move is atomic. FileManager refuses an existing destination, including a racing writer.
                    try fm.moveItem(at: temporary, to: candidate)
                    return candidate
                } catch {
                    if !fm.fileExists(atPath: candidate.path) { throw error }
                }
            }
            suffix += 1
        }
        throw ConversionError.outputFailure("Too many files use the output name.")
    }

    private static func hasAlpha(_ image: CGImage) -> Bool {
        [.first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly].contains(image.alphaInfo)
    }

    private static func flattened(_ image: CGImage) throws -> CGImage {
        guard let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw ConversionError.outputFailure("Not enough memory to decode the image.")
        }
        let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(rect)
        context.draw(image, in: rect)
        guard let output = context.makeImage() else { throw ConversionError.outputFailure("Could not flatten the image.") }
        return output
    }

    private static func jpegImage(_ image: CGImage, quality: Double) throws -> CGImage {
        let data = NSMutableData()
        let opaque = hasAlpha(image) ? try flattened(image) : image
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw ConversionError.outputFailure("Could not create JPEG data.")
        }
        CGImageDestinationAddImage(destination, opaque, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(destination), let provider = CGDataProvider(data: data),
              let result = CGImage(jpegDataProviderSource: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            throw ConversionError.outputFailure("Could not compress the image as JPEG.")
        }
        return result
    }

    private static func validateOCRLanguages(_ languages: [String]) throws {
        guard !languages.isEmpty else { return }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        let supported = try request.supportedRecognitionLanguages()
        let unsupported = languages.filter { !supported.contains($0) }
        guard unsupported.isEmpty else {
            throw ConversionError.invalidSettings("This macOS version cannot recognize: \(unsupported.joined(separator: ", ")).")
        }
    }

    private struct RecognizedLine {
        var text: String
        var bounds: CGRect
    }

    private static func recognize(_ image: CGImage, settings: ConversionSettings,
                                  cancellation: ConversionCancellation) throws -> [RecognizedLine] {
        func makeRequest() -> VNRecognizeTextRequest {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = settings.ocrLanguageCorrection
            request.automaticallyDetectsLanguage = settings.ocrLanguages.isEmpty
            if !settings.ocrLanguages.isEmpty { request.recognitionLanguages = settings.ocrLanguages }
            return request
        }
        do {
            return try performRecognition(makeRequest(), image: image, cancellation: cancellation)
        } catch {
            try cancellation.check()
            // Hardware acceleration can be unavailable in a remote session or on a busy GPU.
            // Retry once using the public macOS 14 compute-device API; never suppress OCR failure.
            let fallback = makeRequest()
            let devices = try fallback.supportedComputeStageDevices
            var assignedCPU = false
            for (stage, available) in devices {
                if let cpu = available.first(where: { if case .cpu = $0 { return true }; return false }) {
                    fallback.setComputeDevice(cpu, for: stage)
                    assignedCPU = true
                }
            }
            guard assignedCPU else { throw error }
            return try performRecognition(fallback, image: image, cancellation: cancellation)
        }
    }

    private static func performRecognition(_ request: VNRecognizeTextRequest, image: CGImage,
                                           cancellation: ConversionCancellation) throws -> [RecognizedLine] {
        cancellation.setRequest(request)
        defer { cancellation.setRequest(nil) }
        try cancellation.check()
        try VNImageRequestHandler(cgImage: image, orientation: .up, options: [:]).perform([request])
        try cancellation.check()
        return (request.results ?? []).compactMap { observation in
            guard let candidate = observation.topCandidates(1).first, !candidate.string.isEmpty else { return nil }
            return RecognizedLine(text: candidate.string, bounds: observation.boundingBox)
        }
    }

    private static func drawInvisibleText(_ lines: [RecognizedLine], in imageRect: CGRect, context: CGContext) {
        let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        for recognized in lines {
            let box = recognized.bounds
            let target = CGRect(x: imageRect.minX + box.minX * imageRect.width,
                                y: imageRect.minY + box.minY * imageRect.height,
                                width: box.width * imageRect.width, height: box.height * imageRect.height)
            let string = NSAttributedString(string: recognized.text, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
            let line = CTLineCreateWithAttributedString(string)
            var ascent: CGFloat = 0, descent: CGFloat = 0
            let width = CTLineGetTypographicBounds(line, &ascent, &descent, nil)
            guard width > 0, ascent + descent > 0, target.width > 0, target.height > 0 else { continue }
            let scaleY = target.height / (ascent + descent)
            context.saveGState()
            context.translateBy(x: target.minX, y: target.minY + descent * scaleY)
            context.scaleBy(x: target.width / width, y: scaleY)
            context.textMatrix = .identity
            context.textPosition = .zero
            context.setTextDrawingMode(.invisible)
            CTLineDraw(line, context)
            context.restoreGState()
        }
    }
}

private final class ConversionCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    private var request: VNRequest?

    func cancel() {
        lock.lock()
        cancelled = true
        let current = request
        lock.unlock()
        current?.cancel()
    }

    func setRequest(_ request: VNRequest?) {
        lock.lock()
        self.request = request
        let shouldCancel = cancelled
        lock.unlock()
        if shouldCancel { request?.cancel() }
    }

    func check() throws {
        lock.lock()
        let isCancelled = cancelled
        lock.unlock()
        if isCancelled || Task.isCancelled { throw CancellationError() }
    }
}
