import SwiftUI
import Vision
import FolioCore

struct ConversionInspector: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var language: LanguageStore
    @State private var showPageDetails = false
    @State private var showDocumentDetails = false
    @State private var showEncryption = false
    @State private var supportedLanguages: [String] = []
    var body: some View {
        ScrollViewReader { scroll in
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack { Text(L("EXPORT SETTINGS")).font(.system(size: 9, weight: .semibold)).tracking(1.4).foregroundStyle(.secondary); Spacer(); Menu { Button(L("Reset settings")) { model.resetSettings() } } label: { Image(systemName: "ellipsis").font(.system(size: 12)) }.menuStyle(.borderlessButton).fixedSize() }
                qualitySection
                inspectorSection(L("Document"), symbol: "doc") {
                    Picker(L("Output"), selection: $model.settings.outputMode) { ForEach(OutputMode.allCases, id: \.self) { Text(L($0.rawValue)).tag($0) } }.labelsHidden()
                    if model.settings.outputMode == .perFolder { note(L("Each source folder becomes a separate document.")) }
                    TextField(L("Document title (optional)"), text: $model.settings.title).textFieldStyle(.roundedBorder)
                }
                pageSection
                ocrSection
                inspectorSection(L("Folder import"), symbol: "folder") {
                    Toggle(L("Include subfolders"), isOn: $model.recursive).toggleStyle(.checkbox)
                    if model.recursive { Toggle(L("Include the top folder"), isOn: $model.includeRoot).toggleStyle(.checkbox) }
                    note(L("Applies when you add a folder. Existing pages stay as they are."))
                }
                inspectorSection(L("Navigation"), symbol: "bookmark") {
                    Toggle(L("Bookmark image files"), isOn: $model.settings.addFileBookmarks).toggleStyle(.checkbox)
                    Toggle(L("Read companion .itf files"), isOn: $model.settings.useInterfaceFile).toggleStyle(.checkbox)
                    note(L("Import compatible bookmarks, page labels and document details from the source folder."))
                    Picker(L("Reading layout"), selection: $model.settings.layout) { ForEach(PDFLayout.allCases, id: \.self) { Text(L($0.rawValue)).tag($0) } }.labelsHidden()
                }
                documentDetailsSection.id("documentDetails")
                Divider()
                encryptionSection.padding(.bottom, 10).id("encryptionSection")
            }.font(.system(size: 11)).padding(20)
        }.background(Color(nsColor: .windowBackgroundColor)).disabled(model.running)
            .task {
                supportedLanguages = (try? VNRecognizeTextRequest().supportedRecognitionLanguages()) ?? []
                if ProcessInfo.processInfo.arguments.contains("--ui-smoke-test"),
                   ProcessInfo.processInfo.arguments.contains("--encryption-settings") {
                    try? await Task.sleep(for: .seconds(3))
                    if !ProcessInfo.processInfo.arguments.contains("--encryption-collapsed") {
                        model.openingPasswordEnabled = !ProcessInfo.processInfo.arguments.contains("--editing-password-only")
                        model.editingPasswordEnabled = true
                        showEncryption = true
                    }
                    try? await Task.sleep(for: .milliseconds(150))
                    scroll.scrollTo("encryptionSection", anchor: .bottom)
                }
            }
        }
    }

    private var documentDetailsSection: some View {
        DisclosureGroup(isExpanded: $showDocumentDetails) {
            VStack(spacing: 10) {
                TextField(L("Author"), text: $model.settings.author)
                TextField(L("Subject"), text: $model.settings.subject)
                TextField(L("Keywords"), text: $model.settings.keywords)
            }.textFieldStyle(.roundedBorder)
        } label: {
            Text(L("Document details")).font(.system(size: 12, weight: .semibold))
        }
    }

    private var encryptionSection: some View {
        DisclosureGroup(isExpanded: $showEncryption) {
            PDFEncryptionSettingsView()
        } label: {
            Label(L("PDF encryption"), systemImage: model.encryptionEnabled ? "lock.fill" : "lock")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(model.encryptionEnabled ? FolioTheme.accent : .primary)
        }
    }

    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("A little care for every pixel.")).font(.system(size: 15, weight: .semibold, design: .rounded)).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                qualityButton(.lossless, title: L("Full quality"), symbol: "sparkles")
                qualityButton(.jpeg, title: L("Smaller file"), symbol: "arrow.down.right.and.arrow.up.left")
            }
            if model.settings.compression == .jpeg {
                HStack { Text(L("JPEG quality")); Spacer(); Text("\(Int(model.settings.jpegQuality * 100))%").monospacedDigit().foregroundStyle(.secondary) }
                Slider(value: $model.settings.jpegQuality, in: 0.2...1, step: 0.01).controlSize(.small)
                note(L("Smaller files trade some detail for space."))
            } else { note(L("Original pixel dimensions. No lossy recompression.")) }
        }
    }
    private func qualityButton(_ mode: ImageCompression, title: String, symbol: String) -> some View {
        Button { model.settings.compression = mode } label: {
            VStack(spacing: 9) { Image(systemName: symbol).font(.system(size: 19)); Text(title).font(.system(size: 11, weight: .medium)).multilineTextAlignment(.center).lineLimit(2).frame(minHeight: 28) }.frame(maxWidth: .infinity).padding(.vertical, 12)
                .foregroundStyle(model.settings.compression == mode ? FolioTheme.accent : .secondary)
                .background(model.settings.compression == mode ? FolioTheme.accent.opacity(0.08) : .primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(model.settings.compression == mode ? FolioTheme.accent.opacity(0.55) : .primary.opacity(0.08), lineWidth: 1))
        }.buttonStyle(.plain)
    }

    private var pageSection: some View {
        inspectorSection(L("Page & paper"), symbol: "rectangle.portrait") {
            Picker(L("Paper size"), selection: $model.settings.paperSize) { ForEach(PaperSize.allCases, id: \.self) { Text(L($0.rawValue)).tag($0) } }.labelsHidden()
            if model.settings.paperSize == .fixedWidth || model.settings.paperSize == .custom {
                HStack { dimensionField(L("Width"), value: $model.settings.widthMM); if model.settings.paperSize == .custom { dimensionField(L("Height"), value: $model.settings.heightMM) } }
            }
            if model.settings.paperSize != .image && model.settings.paperSize != .fixedWidth {
                Toggle(L("Landscape"), isOn: $model.settings.landscape).toggleStyle(.checkbox)
                Toggle(L("Enlarge smaller images"), isOn: $model.settings.enlargeSmallImages).toggleStyle(.checkbox)
            }
            DisclosureGroup(isExpanded: $showPageDetails) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Margins (mm)")).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                    HStack { marginField(L("Top"), value: $model.settings.margins.top); marginField(L("Bottom"), value: $model.settings.margins.bottom) }
                    HStack { marginField(L("Left"), value: $model.settings.margins.left); marginField(L("Right"), value: $model.settings.margins.right) }
                    Divider()
                    HStack { Text(L("Fallback DPI")); Spacer(); TextField("300", value: $model.settings.dpi, format: .number.precision(.fractionLength(0))).frame(width: 65).textFieldStyle(.roundedBorder) }
                    Toggle(L("Use image DPI when available"), isOn: $model.settings.useImageDPI).toggleStyle(.checkbox)
                    Toggle(L("Preserve transparency"), isOn: $model.settings.preserveTransparency).toggleStyle(.checkbox)
                    note(L("DPI changes page dimensions, not image resolution."))
                }.padding(.top, 10)
            } label: { Text(L("Margins & resolution")).foregroundStyle(.secondary) }
        }
    }
    private var ocrSection: some View {
        inspectorSection(L("Searchable text"), symbol: "text.viewfinder") {
            Toggle(L("Recognize text with OCR"), isOn: $model.settings.ocrEnabled).toggleStyle(.switch).controlSize(.small)
            if model.settings.ocrEnabled {
                Picker(L("Text language"), selection: Binding(get: { model.settings.ocrLanguages.first ?? "auto" }, set: { model.settings.ocrLanguages = $0 == "auto" ? [] : [$0] })) {
                    Text(L("Automatic")).tag("auto")
                    ForEach(supportedLanguages, id: \.self) { code in Text(Locale(identifier: language.resolvedLanguage).localizedString(forIdentifier: code) ?? code).tag(code) }
                }.labelsHidden()
                Toggle(L("Language correction"), isOn: $model.settings.ocrLanguageCorrection).toggleStyle(.checkbox)
                note(L("The image stays unchanged. A hidden text layer makes it searchable and selectable."))
            } else { note(L("Find and copy words in your scanned pages. Powered by Apple Vision, entirely on your Mac.")) }
        }
    }
    private func inspectorSection<Content: View>(_ title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) { Image(systemName: symbol).foregroundStyle(FolioTheme.accent); Text(title).font(.system(size: 12, weight: .semibold)) }
            content()
        }
    }
    private func dimensionField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 5) { Text(title + " (mm)").foregroundStyle(.secondary).font(.system(size: 10)); TextField("", value: value, format: .number.precision(.fractionLength(0...1))).textFieldStyle(.roundedBorder) }
    }
    private func marginField(_ title: String, value: Binding<Double>) -> some View {
        HStack(spacing: 4) { Text(title).font(.system(size: 10)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading); TextField("0", value: value, format: .number.precision(.fractionLength(0...1))).textFieldStyle(.roundedBorder).frame(width: 48) }
    }
    private func note(_ text: String) -> some View { Text(text).font(.system(size: 10)).foregroundStyle(.secondary).lineSpacing(3).fixedSize(horizontal: false, vertical: true) }
}
