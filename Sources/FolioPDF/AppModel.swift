import AppKit
import SwiftUI
import PDFKit
import FolioCore
import UniformTypeIdentifiers

struct ExportRecord: Identifiable, Codable {
    var id = UUID()
    var path: String
    var date: Date
    var pageCount: Int
    var url: URL { URL(fileURLWithPath: path) }
}

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()
    @Published var assets: [ImageAsset] = []
    @Published var selection: Set<UUID> = []
    @Published var settings: ConversionSettings { didSet { saveSettings() } }
    // Both passwords are session state, never part of persisted settings or history.
    @Published var openingPasswordEnabled = false {
        didSet { if !openingPasswordEnabled { openingPassword = ""; openingPasswordConfirmation = "" } }
    }
    @Published var openingPassword = ""
    @Published var openingPasswordConfirmation = ""
    @Published var editingPasswordEnabled = false {
        didSet { if !editingPasswordEnabled { editingPassword = ""; editingPasswordConfirmation = "" } }
    }
    @Published var editingPassword = ""
    @Published var editingPasswordConfirmation = ""
    var encryptionEnabled: Bool { openingPasswordEnabled || editingPasswordEnabled }
    @Published var sortOrder: FolioCore.SortOrder = .name
    @Published var recursive = false
    @Published var includeRoot = true
    @Published var importing = false
    @Published var running = false
    @Published var progress: ConversionProgress?
    @Published var logs: [String] = []
    @Published var errorMessage: String?
    @Published var exports: [ExportRecord] = []
    @Published var showResults = false
    @Published var lastResults: [URL] = []
    @Published var previewURL: URL?
    @Published var importWarnings: [String] = []
    @Published var lastExportWarnings: [String] = []
    @Published var bookmarkHasUnsavedChanges = false
    private var conversionTask: Task<Void, Never>?
    private var importTask: Task<Void, Never>?
    private let defaults: UserDefaults
    var totalPages: Int { assets.reduce(0) { $0 + $1.frameCount } }
    var totalBytes: Int64 { assets.reduce(0) { $0 + $1.fileSize } }
    var selectedAsset: ImageAsset? { assets.first(where: { selection.contains($0.id) }) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: "conversionSettings"), let value = try? JSONDecoder().decode(ConversionSettings.self, from: data) { settings = value }
        else { settings = ConversionSettings() }
        if let data = defaults.data(forKey: "recentExports"), let value = try? JSONDecoder().decode([ExportRecord].self, from: data) { exports = value }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: "conversionSettings") }
    }

    func resetSettings() {
        settings = ConversionSettings()
        openingPasswordEnabled = false
        editingPasswordEnabled = false
    }

    func encryptionOptions() throws -> PDFEncryptionOptions? {
        guard encryptionEnabled else { return nil }
        let options = PDFEncryptionOptions(openPassword: openingPasswordEnabled ? openingPassword : nil,
                                           editingPassword: editingPasswordEnabled ? editingPassword : nil)
        try PDFEncryption.validate(options: options)
        if openingPasswordEnabled && openingPassword != openingPasswordConfirmation {
            throw ConversionError.invalidSettings("The opening passwords do not match.")
        }
        if editingPasswordEnabled && editingPassword != editingPasswordConfirmation {
            throw ConversionError.invalidSettings("The editing passwords do not match.")
        }
        return options
    }

    func chooseImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        panel.prompt = L("Add images")
        if panel.runModal() == .OK { importURLs(panel.urls) }
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = L("Add folder")
        if panel.runModal() == .OK { importURLs(panel.urls) }
    }

    func importURLs(_ urls: [URL]) {
        guard !running, !importing else { return }
        importing = true
        let recursive = recursive, includeRoot = includeRoot
        importTask = Task {
            let result = await Task.detached(priority: .userInitiated) { () -> ([ImageAsset], [String]) in
                var loaded: [ImageAsset] = [], warnings: [String] = []
                for url in urls {
                    do {
                        for file in try AssetLibrary.discover(in: [url], recursive: recursive, includeRoot: includeRoot) {
                            do { loaded.append(try ImagePipeline.inspect(file)) }
                            catch { warnings.append("\(file.lastPathComponent): \(error.localizedDescription)") }
                        }
                    } catch { warnings.append("\(url.lastPathComponent): \(error.localizedDescription)") }
                }
                return (loaded, warnings)
            }.value
            var existing = Set(assets.map { $0.url.standardizedFileURL })
            let newAssets = result.0.filter { existing.insert($0.url.standardizedFileURL).inserted }
            assets = AssetLibrary.sorted(assets + newAssets, by: sortOrder)
            if selection.isEmpty, let first = assets.first { selection = [first.id] }
            importing = false
            importWarnings = result.1
            logs.append(contentsOf: result.1)
            if result.0.isEmpty && result.1.isEmpty { errorMessage = L("No supported images were found.") }
            else if !result.1.isEmpty { errorMessage = String(format: L("%d files could not be imported."), result.1.count) + "\n" + result.1.prefix(4).joined(separator: "\n") }
        }
    }

    func changeSort(_ order: FolioCore.SortOrder) {
        sortOrder = order
        assets = AssetLibrary.sorted(assets, by: order)
    }

    func removeSelection() {
        guard !running else { return }
        assets.removeAll { selection.contains($0.id) }
        selection.removeAll()
    }

    func clear() { guard !running else { return }; assets.removeAll(); selection.removeAll() }

    func moveSelection(_ offset: Int) {
        guard !running else { return }
        sortOrder = .manual
        if offset < 0 {
            for index in assets.indices where index > 0 && selection.contains(assets[index].id) && !selection.contains(assets[index - 1].id) { assets.swapAt(index, index - 1) }
        } else {
            for index in assets.indices.reversed() where index < assets.count - 1 && selection.contains(assets[index].id) && !selection.contains(assets[index + 1].id) { assets.swapAt(index, index + 1) }
        }
    }

    func reorder(_ sourceID: UUID, before targetID: UUID) {
        guard !running, sourceID != targetID, let from = assets.firstIndex(where: { $0.id == sourceID }) else { return }
        let item = assets.remove(at: from)
        if let to = assets.firstIndex(where: { $0.id == targetID }) { assets.insert(item, at: to) } else { assets.append(item) }
        sortOrder = .manual
    }

    func chooseDestination() {
        guard !assets.isEmpty, !running, !importing else { return }
        do { _ = try encryptionOptions() }
        catch { errorMessage = localizedError(error); return }
        if settings.outputMode == .combined {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.canCreateDirectories = true
            panel.nameFieldStringValue = settings.title.isEmpty ? "\(assets.first?.folder.lastPathComponent ?? "Document").pdf" : "\(settings.title).pdf"
            panel.prompt = L("Create PDF")
            if panel.runModal() == .OK, let url = panel.url { startConversion(to: url) }
        } else {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.canCreateDirectories = true
            panel.prompt = L("Export here")
            if panel.runModal() == .OK, let url = panel.url { startConversion(to: url) }
        }
    }

    func startConversion(to destination: URL) {
        guard !running, !importing else { return }
        let encryption: PDFEncryptionOptions?
        do { encryption = try encryptionOptions() }
        catch { errorMessage = localizedError(error); return }
        let input = assets, options = settings
        running = true; progress = nil; lastResults = []; lastExportWarnings = []
        logs.append("\(Date().formatted()): \(L("Creating PDF…"))")
        conversionTask = Task {
            do {
                let result = try await PDFConverter.convert(assets: input, settings: options, destination: destination, encryption: encryption) { [weak self] value in
                    Task { @MainActor in self?.progress = value }
                }
                record(result, password: encryption?.openPassword)
            } catch let interruption as ConversionInterrupted {
                var partial = interruption.partialResult
                partial.warnings.append(interruption.isCancelled ? L("Conversion cancelled. Completed documents were kept.") : localizedError(interruption.underlying))
                record(partial, password: encryption?.openPassword)
            } catch is CancellationError { logs.append(L("Conversion cancelled.")) }
            catch { logs.append(error.localizedDescription); errorMessage = localizedError(error) }
            running = false
            conversionTask = nil
        }
    }

    private func record(_ result: ConversionResult, password: String? = nil) {
        lastResults = result.outputs
        lastExportWarnings = result.warnings
        logs.append(contentsOf: result.warnings)
        logs.append(String(format: L("Created %d PDF files."), result.outputs.count))
        for url in result.outputs {
            let document = PDFDocument(url: url)
            if document?.isLocked == true, let password { _ = document?.unlock(withPassword: password) }
            let pages = document?.pageCount ?? 0
            exports.insert(ExportRecord(path: url.path, date: Date(), pageCount: pages), at: 0)
        }
        exports = Array(exports.prefix(30))
        if let data = try? JSONEncoder().encode(exports) { defaults.set(data, forKey: "recentExports") }
        showResults = true
    }

    func cancel() { conversionTask?.cancel() }
    func saveLog() {
        let panel = NSSavePanel(); panel.allowedContentTypes = [.plainText]; panel.nameFieldStringValue = "FolioPDF-log.txt"
        if panel.runModal() == .OK, let url = panel.url {
            do { try logs.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8) } catch { errorMessage = localizedError(error) }
        }
    }
}
