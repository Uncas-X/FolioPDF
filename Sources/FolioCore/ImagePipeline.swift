import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum ConversionError: LocalizedError {
    case unreadableImage(String)
    case invalidImage(String)
    case invalidSettings(String)
    case outputFailure(String)
    case noImages

    public var errorDescription: String? {
        switch self {
        case .unreadableImage(let name): return "Cannot read image: \(name)"
        case .invalidImage(let name): return "The image contains no readable pixels: \(name)"
        case .invalidSettings(let reason): return "Invalid conversion settings: \(reason)"
        case .outputFailure(let reason): return "Could not write PDF: \(reason)"
        case .noImages: return "Add at least one supported image before converting."
        }
    }
}

public enum ImagePipeline {
    /// ImageIO's supported formats on this Mac, rather than a hard-coded promise about RAW codecs.
    public static var supportedExtensions: Set<String> {
        let identifiers = CGImageSourceCopyTypeIdentifiers() as! [String]
        // LaunchServices may not return filename tags in a headless process or a fresh user session.
        // These baseline ImageIO formats ship with the app's minimum supported macOS version.
        // RAW extensions remain dynamic because camera codec support varies by macOS version.
        let baseline: Set<String> = ["jpg", "jpeg", "png", "tif", "tiff", "gif", "bmp", "dib",
                                     "heic", "heif", "jp2", "j2k", "jpc", "jpf", "jpx", "j2c", "ico", "icns"]
        return identifiers.reduce(into: baseline) { extensions, identifier in
            if let type = UTType(identifier) {
                extensions.formUnion(type.tags[.filenameExtension, default: []].map { $0.lowercased() })
            }
        }
    }

    public static func inspect(_ url: URL) throws -> ImageAsset {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetCount(source) > 0 else {
            throw ConversionError.unreadableImage(url.lastPathComponent)
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
        let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue ?? 0
        let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue ?? 0
        guard width > 0, height > 0 else { throw ConversionError.invalidImage(url.lastPathComponent) }
        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
        let swapped = [5, 6, 7, 8].contains(orientation)
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        let dpi = imageDPI(properties)
        return ImageAsset(url: url, pixelWidth: swapped ? height : width, pixelHeight: swapped ? width : height,
                          frameCount: CGImageSourceGetCount(source), fileSize: Int64(values.fileSize ?? 0), dpi: dpi)
    }

    public static func thumbnail(_ url: URL, maxPixelSize: Int = 400) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, maxPixelSize),
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary)
    }

    static func frame(at index: Int, of url: URL) throws -> (image: CGImage, dpi: Double?) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              index < CGImageSourceGetCount(source) else { throw ConversionError.unreadableImage(url.lastPathComponent) }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] ?? [:]
        let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue ?? 0
        let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue ?? 0
        guard width > 0, height > 0 else { throw ConversionError.invalidImage(url.lastPathComponent) }
        // Keep an already encoded, upright JPEG intact when lossless output draws this CGImage.
        // CoreGraphics can embed its DCT stream directly instead of expanding a large scan to Flate.
        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
        if orientation == 1, CGImageSourceGetType(source) as String? == UTType.jpeg.identifier,
           let provider = CGDataProvider(url: url as CFURL),
           let jpeg = CGImage(jpegDataProviderSource: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
            return (jpeg, imageDPI(properties))
        }
        // A full-size thumbnail applies all eight EXIF orientations without changing the pixel dimensions.
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, index, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(width, height),
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary) else { throw ConversionError.invalidImage(url.lastPathComponent) }
        return (image, imageDPI(properties))
    }

    private static func imageDPI(_ properties: [CFString: Any]) -> Double? {
        guard let dpi = (properties[kCGImagePropertyDPIWidth] as? NSNumber)?.doubleValue,
              dpi.isFinite, dpi > 0 else { return nil }
        return dpi
    }
}

public struct PageGeometry: Equatable, Sendable {
    public let mediaBox: CGRect
    public let imageRect: CGRect
    private static let pointsPerMM = 72.0 / 25.4

    public static func calculate(pixelWidth: Int, pixelHeight: Int, imageDPI: Double?, settings: ConversionSettings) throws -> PageGeometry {
        guard pixelWidth > 0, pixelHeight > 0 else { throw ConversionError.invalidSettings("Image dimensions must be positive.") }
        let dpi = settings.useImageDPI ? (imageDPI ?? settings.dpi) : settings.dpi
        guard dpi.isFinite, dpi > 0 else { throw ConversionError.invalidSettings("DPI must be greater than zero.") }
        let margins = settings.margins
        guard [margins.top, margins.bottom, margins.left, margins.right].allSatisfy({ $0.isFinite && $0 >= 0 }) else {
            throw ConversionError.invalidSettings("Margins must be nonnegative numbers.")
        }
        let left = margins.left * pointsPerMM, right = margins.right * pointsPerMM
        let top = margins.top * pointsPerMM, bottom = margins.bottom * pointsPerMM
        let intrinsic = CGSize(width: Double(pixelWidth) * 72 / dpi, height: Double(pixelHeight) * 72 / dpi)
        var page: CGSize
        switch settings.paperSize {
        case .image:
            page = CGSize(width: intrinsic.width + left + right, height: intrinsic.height + top + bottom)
        case .fixedWidth:
            guard settings.widthMM.isFinite, settings.widthMM > 0 else { throw ConversionError.invalidSettings("Page width must be greater than zero.") }
            let width = settings.widthMM * pointsPerMM
            guard width > left + right else { throw ConversionError.invalidSettings("Margins leave no room for the image.") }
            let scale = (width - left - right) / intrinsic.width
            page = CGSize(width: width, height: intrinsic.height * (settings.enlargeSmallImages ? scale : min(scale, 1)) + top + bottom)
        case .a4: page = CGSize(width: 210 * pointsPerMM, height: 297 * pointsPerMM)
        case .a5: page = CGSize(width: 148 * pointsPerMM, height: 210 * pointsPerMM)
        case .a3: page = CGSize(width: 297 * pointsPerMM, height: 420 * pointsPerMM)
        case .b5: page = CGSize(width: 176 * pointsPerMM, height: 250 * pointsPerMM)
        case .letter: page = CGSize(width: 612, height: 792)
        case .legal: page = CGSize(width: 612, height: 1008)
        case .custom:
            guard settings.widthMM.isFinite, settings.heightMM.isFinite, settings.widthMM > 0, settings.heightMM > 0 else {
                throw ConversionError.invalidSettings("Page width and height must be greater than zero.")
            }
            page = CGSize(width: settings.widthMM * pointsPerMM, height: settings.heightMM * pointsPerMM)
        }
        if settings.landscape && ![PaperSize.image, .fixedWidth].contains(settings.paperSize) {
            page = CGSize(width: max(page.width, page.height), height: min(page.width, page.height))
        }
        let available = CGSize(width: page.width - left - right, height: page.height - top - bottom)
        guard available.width > 0, available.height > 0, page.width <= 14_400, page.height <= 14_400 else {
            throw ConversionError.invalidSettings("Margins leave no printable area, or the page exceeds the PDF limit of 200 inches.")
        }
        let fitScale = min(available.width / intrinsic.width, available.height / intrinsic.height)
        let scale = settings.enlargeSmallImages ? fitScale : min(1, fitScale)
        let imageSize = CGSize(width: intrinsic.width * scale, height: intrinsic.height * scale)
        let rect = CGRect(x: left + (available.width - imageSize.width) / 2,
                          y: bottom + (available.height - imageSize.height) / 2,
                          width: imageSize.width, height: imageSize.height)
        return PageGeometry(mediaBox: CGRect(origin: .zero, size: page), imageRect: rect)
    }
}
