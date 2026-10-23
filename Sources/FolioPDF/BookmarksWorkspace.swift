import SwiftUI
import AppKit
import PDFKit
import UniformTypeIdentifiers
import FolioCore

struct BookmarksWorkspace: View {
    @EnvironmentObject private var language: LanguageStore
    @EnvironmentObject private var appModel: AppModel
    @State private var source: URL?
    @State private var document: PDFDocument?
    @State private var entries: [BookmarkEntry] = []
    @State private var selection: UUID?
    @State private var previewPage = 0
    @State private var basePage = 1
    @State private var title = ""
    @State private var author = ""
    @State private var subject = ""
    @State private var keywords = ""
    @State private var interfaceConfiguration: InterfaceConfiguration?
    @State private var warnings: [String] = []
    @State private var error: String?
    @State private var savedURL: URL?
    @State private var textEditor = false
    @State private var draftText = ""
    @State private var showMetadata = false
    @State private var interfaceRevision: UUID?
    @State private var cleanSnapshot = BookmarkDraftSnapshot()

    private var selectedIndex: Int? { entries.firstIndex { $0.id == selection } }
    private var metadata: PDFMetadata { .init(title: title, author: author, subject: subject, keywords: keywords) }
    private var draftSnapshot: BookmarkDraftSnapshot { .init(entries: entries, title: title, author: author, subject: subject, keywords: keywords, interfaceRevision: interfaceRevision) }
    private var hasUnsavedChanges: Bool {
        source != nil && (draftSnapshot != cleanSnapshot || (textEditor && draftText != BookmarkService.serialize(entries: entries, basePage: basePage)))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if let document {
                HSplitView {
                    editor.frame(minWidth: 310, idealWidth: 365, maxWidth: 450)
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "doc.richtext").foregroundStyle(.secondary)
                            Text(source?.lastPathComponent ?? "PDF").font(.callout).lineLimit(1)
                            Spacer()
                            Text("\(document.pageCount) " + L("pages")).font(.caption).foregroundStyle(.secondary)
                        }.padding(14)
                        Divider()
                        BookmarkPDFPreview(document: document, pageIndex: $previewPage)
                    }.frame(minWidth: 400)
                }
            } else {
                VStack(spacing: 18) {
                    Image(systemName: "bookmark.square.fill").font(.system(size: 68, weight: .light)).foregroundStyle(Color.accentColor.gradient)
                    Text(L("Give every chapter a place")).font(.system(size: 26, weight: .semibold, design: .rounded))
                    Text(L("Open a PDF to create a clear, navigable table of contents.")).foregroundStyle(.secondary)
                    Button(action: openPDF) { Label(L("Open PDF"), systemImage: "folder") }.buttonStyle(.borderedProminent).controlSize(.large)
                    Text(L("Your original PDF stays untouched. Save your changes as a new copy.")).font(.callout).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(30)
            }
            if let savedURL {
                Divider()
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(L("Saved") + ": " + savedURL.lastPathComponent).lineLimit(1)
                    Spacer()
                    Button(L("Show in Finder")) { NSWorkspace.shared.activateFileViewerSelecting([savedURL]) }
                    Button(L("Open")) { NSWorkspace.shared.open(savedURL) }
                }.font(.callout).padding(12).background(.green.opacity(0.05))
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert(L("Unable to complete"), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button(L("OK"), role: .cancel) {} } message: { Text(error ?? "") }
        .sheet(isPresented: $textEditor) { textSheet }
        .sheet(isPresented: $showMetadata) { metadataSheet }
        .onChange(of: hasUnsavedChanges) { _, dirty in appModel.bookmarkHasUnsavedChanges = dirty }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Bookmarks")).font(.system(size: 24, weight: .bold, design: .rounded))
                Text(L("Structure your documents, chapter by chapter.")).font(.callout).foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Button(action: openPDF) { Label(L("Open PDF"), systemImage: "folder") }
            if document != nil {
                Menu {
                    Button(L("Import text or JSON…"), action: importBookmarks)
                    Button(L("Import interface file…"), action: importInterface)
                    Divider()
                    Button(L("Export JSON…")) { exportBookmarks(json: true) }
                    Button(L("Export text…")) { exportBookmarks(json: false) }
                    Button(L("Export interface folder…"), action: exportInterface)
                } label: { Image(systemName: "square.and.arrow.up.on.square"); Text(L("Import / Export")) }
                Button(action: saveCopy) { Label(L("Save a copy"), systemImage: "square.and.arrow.down") }.buttonStyle(.borderedProminent)
            }
        }.padding(22)
    }

    private var editor: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L("Table of contents")).font(.headline)
                Text("\(entries.count)").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 7).padding(.vertical, 3).background(.quaternary, in: Capsule())
                Spacer()
                Button { draftText = BookmarkService.serialize(entries: entries, basePage: basePage); textEditor = true } label: { Image(systemName: "text.alignleft") }.help(L("Edit as text"))
                Button { showMetadata = true } label: { Image(systemName: "info.circle") }.help(L("Document information"))
            }.buttonStyle(.borderless).padding(14)
            Divider()
            if entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.indent").font(.largeTitle).foregroundStyle(.tertiary)
                    Text(L("No bookmarks yet")).font(.headline)
                    Text(L("Add a chapter or import an existing outline.")).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button(L("Add bookmark"), action: addBookmark)
                }.frame(maxWidth: .infinity, maxHeight: .infinity).padding()
            } else {
                List(selection: $selection) {
                    ForEach(entries) { entry in
                        HStack(spacing: 7) {
                            Image(systemName: entry.targetKind == .page ? "bookmark" : "link").foregroundStyle(Color.accentColor).font(.caption)
                            Text(entry.title).lineLimit(2)
                            Spacer(minLength: 4)
                            Text(entry.targetKind == .page ? String(entry.pageIndex + 1) : "↗").monospacedDigit().font(.caption).foregroundStyle(.secondary)
                        }.padding(.leading, CGFloat(min(entry.depth, 8)) * 14).padding(.vertical, 4).tag(entry.id)
                    }
                }.listStyle(.inset).onChange(of: selection) { _, _ in
                    if let index = selectedIndex, entries[index].targetKind == .page { previewPage = entries[index].pageIndex }
                }
            }
            Divider()
            HStack(spacing: 15) {
                Button(action: addBookmark) { Image(systemName: "plus") }.help(L("Add bookmark"))
                Button(action: deleteBookmark) { Image(systemName: "minus") }.disabled(selection == nil).help(L("Delete bookmark and children"))
                Spacer()
                Button { shiftBookmark(-1) } label: { Image(systemName: "arrow.up") }.disabled(!canMove(-1)).help(L("Move up"))
                Button { shiftBookmark(1) } label: { Image(systemName: "arrow.down") }.disabled(!canMove(1)).help(L("Move down"))
                Button { adjustDepth(-1) } label: { Image(systemName: "decrease.indent") }.disabled(selectedIndex.map { entries[$0].depth == 0 } ?? true).help(L("Outdent"))
                Button { adjustDepth(1) } label: { Image(systemName: "increase.indent") }.disabled(!canIndent).help(L("Indent"))
            }.buttonStyle(.borderless).padding(14)
            if let index = selectedIndex {
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Selected bookmark")).font(.caption).foregroundStyle(.secondary)
                    TextField(L("Title"), text: $entries[index].title).textFieldStyle(.roundedBorder)
                    if entries[index].targetKind == .page {
                        HStack {
                            Text(L("PDF page"))
                            Spacer()
                            TextField("", value: Binding(get: { entries.indices.contains(index) ? entries[index].pageIndex + 1 : 1 }, set: { if entries.indices.contains(index) { let page = min(max(1, $0), max(1, document?.pageCount ?? 1)); entries[index].pageIndex = page - 1; previewPage = page - 1 } }), format: .number).textFieldStyle(.roundedBorder).frame(width: 70)
                            Stepper("", value: Binding(get: { entries.indices.contains(index) ? entries[index].pageIndex : 0 }, set: { if entries.indices.contains(index) { entries[index].pageIndex = $0; previewPage = $0 } }), in: 0...max(0, (document?.pageCount ?? 1) - 1)).labelsHidden()
                        }
                    } else {
                        Text(entries[index].targetValue ?? L("Unsupported destination")).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                        Button(L("Change to page destination")) { entries[index].targetKind = .page; entries[index].pageIndex = max(0, previewPage); entries[index].targetValue = nil }
                    }
                }.padding(14)
            }
            if !warnings.isEmpty {
                Divider()
                DisclosureGroup {
                    ScrollView { Text(warnings.map { localizedWarning($0) }.joined(separator: "\n\n")).font(.caption).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }.frame(maxHeight: 100)
                } label: { Label(L("Review import notes"), systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange) }.padding(12)
            }
        }
    }

    private var canIndent: Bool { guard let index = selectedIndex, index > 0 else { return false }; return entries[index].depth <= entries[index - 1].depth }
    private func subtreeEnd(_ index: Int) -> Int { var end = index + 1; while end < entries.count && entries[end].depth > entries[index].depth { end += 1 }; return end }
    private func canMove(_ direction: Int) -> Bool {
        guard let index = selectedIndex else { return false }
        if direction > 0 { let end = subtreeEnd(index); return end < entries.count && entries[end].depth == entries[index].depth }
        return index > 0 && entries[..<index].contains { $0.depth == entries[index].depth }
    }
    private func addBookmark() {
        let entry = BookmarkEntry(title: L("New bookmark"), pageIndex: min(max(0, previewPage), max(0, (document?.pageCount ?? 1) - 1)), depth: selectedIndex.map { entries[$0].depth } ?? 0)
        let insertion = selectedIndex.map(subtreeEnd) ?? entries.count
        entries.insert(entry, at: insertion); selection = entry.id; savedURL = nil
    }
    private func deleteBookmark() {
        guard let index = selectedIndex else { return }; let end = subtreeEnd(index)
        entries.removeSubrange(index..<end); selection = entries.isEmpty ? nil : entries[min(index, entries.count - 1)].id; savedURL = nil
    }
    private func adjustDepth(_ delta: Int) {
        guard let index = selectedIndex else { return }; let end = subtreeEnd(index)
        for item in index..<end { entries[item].depth += delta }; savedURL = nil
    }
    private func shiftBookmark(_ direction: Int) {
        guard let index = selectedIndex, canMove(direction) else { return }
        let end = subtreeEnd(index), branch = Array(entries[index..<end])
        if direction < 0 {
            var previous = index - 1
            while previous > 0 && entries[previous].depth > entries[index].depth { previous -= 1 }
            guard entries[previous].depth == entries[index].depth else { return }
            entries.removeSubrange(index..<end); entries.insert(contentsOf: branch, at: previous)
        } else {
            let nextEnd = subtreeEnd(end)
            entries.removeSubrange(index..<end); entries.insert(contentsOf: branch, at: nextEnd - branch.count)
        }
        savedURL = nil
    }

    private var textSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("Edit as text")).font(.title2.bold())
            Text(L("One bookmark per line: title, TAB, page number. Leading TABs create child levels. Negative pages are before the base page; zero is invalid.")).font(.callout).foregroundStyle(.secondary)
            HStack { Text(L("Base page")); Stepper(value: $basePage, in: 1...max(1, document?.pageCount ?? 1)) { Text("\(basePage)").monospacedDigit() }.frame(width: 110); Spacer(); Button(L("Insert TAB")) { NSApp.sendAction(NSSelectorFromString("insertTabIgnoringFieldEditor:"), to: nil, from: nil) } }
            TextEditor(text: $draftText).font(.system(.body, design: .monospaced)).scrollContentBackground(.hidden).padding(10).background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 9)).frame(minHeight: 300).environment(\.layoutDirection, .leftToRight)
            Text(L("Text keeps page targets and supported actions. Use JSON to retain destination coordinates and zoom. Named destinations resolved by PDFKit become page targets.")).font(.caption).foregroundStyle(.secondary)
            HStack { Button(L("Cancel")) { textEditor = false }.keyboardShortcut(.cancelAction); Spacer(); Button(L("Apply changes")) { do { let parsed = try BookmarkService.parse(text: draftText, basePage: basePage); try BookmarkService.validate(entries: parsed, pageCount: document?.pageCount ?? 0); entries = parsed; selection = entries.first?.id; textEditor = false; savedURL = nil } catch { self.error = localizedError(error) } }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction) }
        }.padding(24).frame(width: 680)
    }

    private var metadataSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L("Document information")).font(.title2.bold())
            Form { TextField(L("Title"), text: $title); TextField(L("Author"), text: $author); TextField(L("Subject"), text: $subject); TextField(L("Keywords"), text: $keywords) }.textFieldStyle(.roundedBorder)
            Text(L("These details are written to the saved copy.")).font(.caption).foregroundStyle(.secondary)
            HStack { Spacer(); Button(L("Done")) { showMetadata = false }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction) }
        }.padding(24).frame(width: 480)
    }

    private func openPDF() {
        if hasUnsavedChanges {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = L("Discard unsaved bookmark changes?")
            alert.informativeText = L("Your bookmark and document information changes have not been saved.")
            alert.addButton(withTitle: L("Keep Editing"))
            alert.addButton(withTitle: L("Discard Changes and Open"))
            guard alert.runModal() == .alertSecondButtonReturn else { return }
        }
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.pdf]; panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let pdf = PDFDocument(url: url) else { error = localizedError(BookmarkError.unreadablePDF); return }
        guard !pdf.isEncrypted else { error = localizedError(BookmarkError.encryptedPDF); return }
        let read = BookmarkService.inspect(from: pdf)
        source = url; document = pdf; entries = read.entries; warnings = read.warnings
        selection = entries.first?.id; previewPage = 0; basePage = 1; interfaceConfiguration = nil; interfaceRevision = nil; savedURL = nil
        let attributes = pdf.documentAttributes ?? [:]
        title = attributes[PDFDocumentAttribute.titleAttribute] as? String ?? ""
        author = attributes[PDFDocumentAttribute.authorAttribute] as? String ?? ""
        subject = attributes[PDFDocumentAttribute.subjectAttribute] as? String ?? ""
        keywords = (attributes[PDFDocumentAttribute.keywordsAttribute] as? [String])?.joined(separator: ", ") ?? (attributes[PDFDocumentAttribute.keywordsAttribute] as? String ?? "")
        cleanSnapshot = draftSnapshot
        appModel.bookmarkHasUnsavedChanges = false
    }

    private func importBookmarks() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.json, .plainText]; panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            if url.pathExtension.lowercased() != "json" {
                draftText = try InterfaceFile.readText(from: url); textEditor = true; return
            }
            let imported = try BookmarkService.readJSON(from: url)
            // Unresolved names stay visible in the editor and block saving until explicitly assigned.
            entries = imported; selection = entries.first?.id; savedURL = nil
            warnings = imported.filter { $0.targetKind == .unresolved }.map { L("Unsupported destination") + ": " + ($0.targetValue ?? $0.title) }
        } catch { self.error = localizedError(error) }
    }
    private func importInterface() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false
        panel.message = L("Choose a folder containing FreePic2Pdf.itf.")
        guard panel.runModal() == .OK, let folder = panel.url, let source else { return }
        do {
            guard let configuration = try InterfaceFile.load(from: folder) else { throw InterfaceError.missingFile("FreePic2Pdf.itf") }
            guard let pdf = PDFDocument(url: source) else { throw BookmarkError.unreadablePDF }
            let notes = try InterfaceFile.apply(configuration: configuration, to: pdf)
            interfaceConfiguration = configuration; interfaceRevision = UUID(); document = pdf; warnings = notes
            if let imported = configuration.bookmarks { entries = imported; selection = entries.first?.id }
            if let value = configuration.metadata.title { title = value }; if let value = configuration.metadata.author { author = value }
            if let value = configuration.metadata.subject { subject = value }; if let value = configuration.metadata.keywords { keywords = value }
            savedURL = nil
        } catch { self.error = localizedError(error) }
    }
    private func exportBookmarks(json: Bool) {
        let panel = NSSavePanel(); panel.allowedContentTypes = json ? [.json] : [.plainText]
        panel.nameFieldStringValue = "Bookmarks." + (json ? "json" : "txt")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = json ? try BookmarkService.jsonData(entries: entries) : Data(BookmarkService.serialize(entries: entries, basePage: basePage).utf8)
            try data.write(to: url, options: .withoutOverwriting); savedURL = url
        } catch { self.error = localizedError(error) }
    }
    private func exportInterface() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.canCreateDirectories = true
        panel.message = L("Choose an empty folder for the interface files.")
        guard panel.runModal() == .OK, let folder = panel.url else { return }
        do { try InterfaceFile.export(entries: entries, metadata: metadata, basePage: basePage, to: folder); savedURL = folder } catch { self.error = localizedError(error) }
    }
    private func saveCopy() {
        guard let source else { return }
        let panel = NSSavePanel(); panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = source.deletingPathExtension().lastPathComponent + " – " + L("Bookmarks") + ".pdf"
        panel.message = L("Save a new copy. Existing files are never replaced.")
        guard panel.runModal() == .OK, let destination = panel.url else { return }
        do {
            guard source.standardizedFileURL.resolvingSymlinksInPath() != destination.standardizedFileURL.resolvingSymlinksInPath() else { throw BookmarkError.sameFile }
            guard let pdf = PDFDocument(url: source) else { throw BookmarkError.unreadablePDF }
            if let configuration = interfaceConfiguration { _ = try InterfaceFile.apply(configuration: configuration, to: pdf) }
            try BookmarkService.apply(entries: entries, to: pdf); BookmarkService.apply(metadata: metadata, to: pdf)
            try InterfaceFile.write(document: pdf, to: destination, configuration: interfaceConfiguration, preservingPageLabelsFrom: source)
            savedURL = destination
            cleanSnapshot = draftSnapshot
            appModel.bookmarkHasUnsavedChanges = false
        } catch { self.error = localizedError(error) }
    }
}

private struct BookmarkDraftSnapshot: Equatable {
    var entries: [BookmarkEntry] = []
    var title: String = ""
    var author: String = ""
    var subject: String = ""
    var keywords: String = ""
    var interfaceRevision: UUID?
}

private struct BookmarkPDFPreview: NSViewRepresentable {
    let document: PDFDocument
    @Binding var pageIndex: Int
    func makeNSView(context: Context) -> PDFView {
        let view = PDFView(); view.autoScales = true; view.displayMode = .singlePageContinuous
        view.backgroundColor = NSColor.controlBackgroundColor; view.document = document
        let coordinator = context.coordinator
        coordinator.observer = NotificationCenter.default.addObserver(forName: .PDFViewPageChanged, object: view, queue: .main) { [weak view, weak coordinator] _ in
            guard let view, let coordinator, !coordinator.isUpdating, let page = view.currentPage, let document = view.document else { return }
            let index = document.index(for: page)
            guard index != NSNotFound else { return }
            coordinator.lastPage = index
            if coordinator.page.wrappedValue != index { coordinator.page.wrappedValue = index }
        }
        return view
    }
    func updateNSView(_ view: PDFView, context: Context) {
        context.coordinator.isUpdating = true
        defer { context.coordinator.isUpdating = false }
        context.coordinator.page = $pageIndex
        if view.document !== document { view.document = document; context.coordinator.lastPage = nil }
        if context.coordinator.lastPage != pageIndex, let page = document.page(at: pageIndex) { context.coordinator.lastPage = pageIndex; view.go(to: page) }
    }
    func makeCoordinator() -> Coordinator { Coordinator(page: $pageIndex) }
    static func dismantleNSView(_ view: PDFView, coordinator: Coordinator) { if let observer = coordinator.observer { NotificationCenter.default.removeObserver(observer) } }
    final class Coordinator {
        var lastPage: Int?
        var isUpdating = false
        var page: Binding<Int>
        var observer: NSObjectProtocol?
        init(page: Binding<Int>) { self.page = page }
    }
}
