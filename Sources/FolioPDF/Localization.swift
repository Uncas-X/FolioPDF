import Foundation
import SwiftUI
import FolioCore

struct InterfaceLanguage: Identifiable, Sendable {
    let id: String
    let nativeName: String
}

enum LocalizationCatalog {
    static let languages: [InterfaceLanguage] = [
        .init(id: "zh-Hans", nativeName: "简体中文"),
        .init(id: "en", nativeName: "English"),
        .init(id: "zh-Hant", nativeName: "繁體中文"),
        .init(id: "ja", nativeName: "日本語"),
        .init(id: "ko", nativeName: "한국어"),
        .init(id: "fr", nativeName: "Français"),
        .init(id: "de", nativeName: "Deutsch"),
        .init(id: "es", nativeName: "Español"),
        .init(id: "it", nativeName: "Italiano"),
        .init(id: "pt-BR", nativeName: "Português (Brasil)"),
        .init(id: "ru", nativeName: "Русский"),
        .init(id: "ar", nativeName: "العربية"),
        .init(id: "hi", nativeName: "हिन्दी"),
        .init(id: "tr", nativeName: "Türkçe"),
        .init(id: "nl", nativeName: "Nederlands"),
        .init(id: "pl", nativeName: "Polski")
    ]

    static let translations: [String: [String: String]] = {
        // SwiftPM's generated accessor embeds a build path; packaged apps must resolve
        // their own resource bundle first, without invoking that accessor.
        let packaged = Bundle.main.resourceURL?.appendingPathComponent("FolioPDF_FolioPDF.bundle/Localizations.json")
        let url: URL?
        if let packaged, FileManager.default.fileExists(atPath: packaged.path) {
            url = packaged
        } else if Bundle.main.bundleURL.pathExtension == "app" {
            url = Bundle.main.url(forResource: "Localizations", withExtension: "json")
        } else {
            url = Bundle.module.url(forResource: "Localizations", withExtension: "json")
        }
        guard let url,
              let data = try? Data(contentsOf: url),
              let values = try? JSONDecoder().decode([String: [String: String]].self, from: data)
        else { return [:] }
        return values
    }()

    /// Resolves regional language identifiers without forcing the operating system's locale.
    static func resolve(_ selection: String, preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        if selection != "system", languages.contains(where: { $0.id == selection }) { return selection }
        for preference in preferredLanguages {
            let parts = preference.replacingOccurrences(of: "_", with: "-").lowercased().split(separator: "-").map(String.init)
            guard let base = parts.first else { continue }
            if base == "zh" {
                if parts.contains("hant") { return "zh-Hant" }
                if parts.contains("hans") { return "zh-Hans" }
                return parts.contains(where: { ["tw", "hk", "mo"].contains($0) }) ? "zh-Hant" : "zh-Hans"
            }
            if base == "pt" { return "pt-BR" }
            if languages.contains(where: { $0.id == base }) { return base }
        }
        return "en"
    }

    static func string(_ key: String) -> String {
        let selection = UserDefaults.standard.string(forKey: "interfaceLanguage") ?? "system"
        let language = resolve(selection)
        return translations[language]?[key] ?? translations["en"]?[key] ?? key
    }

    static func layoutDirection(for language: String) -> LayoutDirection {
        language == "ar" ? .rightToLeft : .leftToRight
    }
}

/// English source phrases are stable translation keys. Missing phrases remain readable.
func L(_ key: String) -> String { LocalizationCatalog.string(key) }

/// Format core warnings in the selected UI language, leaving filenames and OS details intact.
func localizedWarning(_ message: String) -> String {
    let patterns: [(String, String)] = [
        (#"^OCR failed for (.*), page ([0-9]+): (.*)\. The page was included without searchable text\.$"#,
         L("OCR failed for %@ (page %@): %@. This page has no searchable text.")),
        (#"^(.*): lossless compression was used to preserve transparency; JPEG cannot store an alpha channel\.$"#,
         L("%@: lossless compression preserved transparency because JPEG does not support it.")),
        (#"^Unsupported bookmark destination: (.*)\. Assign a page or remove it before saving\.$"#,
         L("Unsupported bookmark destination: %@. Set a page or remove the bookmark before saving.")),
        (#"^Unknown interface section: (.*)$"#,
         L("Unknown interface section: %@"))
    ]
    for (pattern, template) in patterns {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
              let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)) else { continue }
        let arguments: [CVarArg] = (1..<match.numberOfRanges).compactMap { index in
            Range(match.range(at: index), in: message).map { String(message[$0]) }
        }
        return String(format: template, arguments: arguments)
    }
    return L(message)
}

/// Keep user-facing failures localized while preserving filenames and diagnostic details.
func localizedError(_ error: Error) -> String {
    if let error = error as? ConversionError {
        switch error {
        case .unreadableImage(let name): return String(format: L("Cannot read image: %@"), name)
        case .invalidImage(let name): return String(format: L("The image contains no readable pixels: %@"), name)
        case .invalidSettings(let reason): return String(format: L("Invalid conversion settings: %@"), L(reason))
        case .outputFailure(let reason): return String(format: L("Could not write PDF: %@"), L(reason))
        case .noImages: return L("Add at least one supported image before converting.")
        }
    }
    if let error = error as? BookmarkError {
        switch error {
        case .invalidBasePage: return L("The base page must be at least 1.")
        case .invalidLine(let line, let reason): return String(format: L("Bookmark line %d: %@"), line, L(reason))
        case .invalidHierarchy(let line): return String(format: L("Bookmark %d skips a hierarchy level. The first bookmark must be at level 1."), line)
        case .invalidPage(let line, let page): return String(format: L("Bookmark %d points to unavailable page %d."), line, page)
        case .unresolvedTarget(let target): return String(format: L("This destination cannot be resolved: %@. Set a page target before saving."), target)
        case .unreadablePDF: return L("The PDF could not be opened.")
        case .encryptedPDF: return L("Encrypted PDFs are not supported for bookmark editing.")
        case .sameFile: return L("Choose a new filename. The original PDF will not be overwritten.")
        case .destinationExists: return L("A file already exists at this destination. Choose a new filename.")
        case .writeFailed: return L("The PDF could not be saved.")
        }
    }
    if let error = error as? InterfaceError {
        switch error {
        case .malformed(let detail): return String(format: L("Invalid interface file: %@"), L(detail))
        case .unsupportedEncoding(let file): return String(format: L("The text encoding could not be read: %@"), file)
        case .missingFile(let file): return String(format: L("The interface file references a missing file: %@"), file)
        case .invalidPageLabels: return L("Page label boundaries must be ordered and inside the PDF.")
        case .serialization: return L("The PDF catalog could not be updated safely. No file was saved.")
        }
    }
    return L(error.localizedDescription)
}

@MainActor
final class LanguageStore: ObservableObject {
    static let shared = LanguageStore()

    @Published var selection: String {
        didSet { UserDefaults.standard.set(selection, forKey: "interfaceLanguage") }
    }

    var resolvedLanguage: String { LocalizationCatalog.resolve(selection) }
    var layoutDirection: LayoutDirection { LocalizationCatalog.layoutDirection(for: resolvedLanguage) }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "interfaceLanguage") ?? "system"
        selection = saved == "system" || LocalizationCatalog.languages.contains(where: { $0.id == saved }) ? saved : "system"
    }
}
