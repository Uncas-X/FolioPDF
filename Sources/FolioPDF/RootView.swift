import SwiftUI
import AppKit
import PDFKit
import UniformTypeIdentifiers
import FolioCore

enum FolioTheme {
    static let accent = Color(red: 0.36, green: 0.33, blue: 0.86)
    static let mint = Color(red: 0.2, green: 0.69, blue: 0.57)
    static let canvas = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(calibratedRed: 0.10, green: 0.105, blue: 0.13, alpha: 1)
            : NSColor(calibratedRed: 0.94, green: 0.945, blue: 0.97, alpha: 1)
    })
    static let card = Color(nsColor: .controlBackgroundColor)
}

struct FolioMark: View {
    var size: CGFloat = 38
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27).fill(LinearGradient(colors: [FolioTheme.accent, Color(red: 0.25, green: 0.2, blue: 0.62)], startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: size * 0.055).fill(.white.opacity(0.3)).frame(width: size * 0.42, height: size * 0.56).rotationEffect(.degrees(-15)).offset(x: -size * 0.09, y: size * 0.02)
            RoundedRectangle(cornerRadius: size * 0.055).fill(.white).frame(width: size * 0.42, height: size * 0.56).rotationEffect(.degrees(9)).offset(x: size * 0.07, y: -size * 0.025)
            Image(systemName: "sparkle").font(.system(size: size * 0.23, weight: .bold)).foregroundStyle(FolioTheme.accent).offset(x: size * 0.07)
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}

private enum Workspace: String, CaseIterable { case create, bookmarks, activity }

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var language: LanguageStore
    @State private var workspace: Workspace = .create
    @State private var showInspector = true
    @State private var showLog = false
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 190)
            Divider()
            VStack(spacing: 0) {
                topbar
                Divider()
                ZStack {
                    HStack(spacing: 0) {
                        LibraryWorkspace()
                        if showInspector { Divider(); ConversionInspector().frame(width: 294) }
                    }
                    .opacity(workspace == .create ? 1 : 0).allowsHitTesting(workspace == .create).accessibilityHidden(workspace != .create).disabled(workspace != .create)
                    BookmarksWorkspace()
                        .opacity(workspace == .bookmarks ? 1 : 0).allowsHitTesting(workspace == .bookmarks).accessibilityHidden(workspace != .bookmarks).disabled(workspace != .bookmarks)
                    activity
                        .opacity(workspace == .activity ? 1 : 0).allowsHitTesting(workspace == .activity).accessibilityHidden(workspace != .activity).disabled(workspace != .activity)
                }
                if model.running { conversionProgress }
            }
        }
        .frame(minWidth: 1080, minHeight: 690)
        .disclosureGroupStyle(FullRowDisclosureStyle())
        .background(Color(nsColor: .windowBackgroundColor))
        .alert(L("Something needs your attention"), isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button(L("OK"), role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
        .sheet(isPresented: $model.showResults) { ExportResultsView() }
        .sheet(isPresented: $showLog) { LogView() }
        .sheet(item: Binding(get: { model.previewURL.map(PreviewItem.init) }, set: { model.previewURL = $0?.url })) { item in
            PDFPreviewSheet(url: item.url)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) { FolioMark(); VStack(alignment: .leading, spacing: 3) { Text("FolioPDF").font(.system(size: 16, weight: .bold)); Text(L("Your pages, together.")).font(.system(size: 10)).foregroundStyle(.secondary) } }.padding(.top, 42).padding(.bottom, 32)
            Text(L("WORKSPACE")).font(.system(size: 9, weight: .semibold)).tracking(1.5).foregroundStyle(.tertiary).padding(.horizontal, 10).padding(.bottom, 10)
            sidebarButton(.create, title: L("Create PDF"), symbol: "square.stack.3d.up", badge: model.assets.isEmpty ? nil : "\(model.assets.count)")
            sidebarButton(.bookmarks, title: L("Bookmarks"), symbol: "bookmark")
            sidebarButton(.activity, title: L("Recent exports"), symbol: "clock.arrow.circlepath")
            Spacer()
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 7) { Image(systemName: "lock.shield").foregroundStyle(FolioTheme.mint); Text(L("Made on your Mac")).font(.system(size: 11, weight: .medium)) }
                Text(L("Your images and text stay on this device.")).font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).lineSpacing(3)
            }.padding(12).background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12)).padding(.bottom, 14)
            HStack {
                Button { FolioAppDelegate.current?.showPreferences() } label: {
                    Label(L("Settings"), systemImage: "gearshape").font(.system(size: 11))
                        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading).contentShape(Rectangle())
                }.buttonStyle(.plain)
                Button { showLog = true } label: {
                    Image(systemName: "text.alignleft").frame(width: 28, height: 28).contentShape(Rectangle())
                }.buttonStyle(.plain).help(L("View log"))
            }.foregroundStyle(.secondary).padding(.horizontal, 8).padding(.bottom, 18)
        }.padding(.horizontal, 14).background(.ultraThinMaterial)
    }

    private func sidebarButton(_ page: Workspace, title: String, symbol: String, badge: String? = nil) -> some View {
        Button { NSApp.keyWindow?.makeFirstResponder(nil); workspace = page } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 14)).frame(width: 18)
                Text(title).font(.system(size: 12, weight: workspace == page ? .semibold : .regular))
                Spacer(minLength: 2)
                if let badge { Text(badge).font(.system(size: 10, weight: .medium)).padding(.horizontal, 6).padding(.vertical, 2).background(.quaternary, in: Capsule()) }
            }.foregroundStyle(workspace == page ? FolioTheme.accent : .primary).padding(.horizontal, 10).padding(.vertical, 11)
                .background(workspace == page ? FolioTheme.accent.opacity(0.11) : Color.clear, in: RoundedRectangle(cornerRadius: 9))
                .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }.buttonStyle(.plain).padding(.bottom, 3)
    }

    private var topbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(workspace == .create ? L("Create a document") : workspace == .bookmarks ? L("Give every chapter a place") : L("Fresh off the press"))
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                Text(workspace == .create ? L("Arrange. Refine. Make it a PDF.") : workspace == .bookmarks ? L("A clear path through your PDF.") : L("Your finished documents, ready to use."))
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            if workspace == .create {
                Menu { Button(L("Add images…")) { model.chooseImages() }; Button(L("Add folder…")) { model.chooseFolder() } } label: { Label(L("Add"), systemImage: "plus") }.menuStyle(.borderlessButton).fixedSize().disabled(model.running || model.importing)
                Button { showInspector.toggle() } label: { Image(systemName: "sidebar.right") }.buttonStyle(.plain).help(L("Show export settings"))
                Button { model.chooseDestination() } label: { Label(L("Create PDF"), systemImage: "arrow.up.doc").padding(.horizontal, 6).padding(.vertical, 3) }
                    .buttonStyle(.borderedProminent).disabled(model.assets.isEmpty || model.running || model.importing)
            }
        }.padding(.horizontal, 24).frame(height: 86)
    }

    private var conversionProgress: some View {
        VStack(spacing: 7) {
            Divider()
            HStack(spacing: 14) {
                ProgressView().controlSize(.small)
                VStack(alignment: .leading, spacing: 3) {
                    Text(L("Creating PDF…")).font(.system(size: 12, weight: .medium))
                    Text(model.progress?.currentFile ?? L("Preparing your pages…")).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                if let progress = model.progress { Text("\(progress.completedPages) / \(progress.totalPages)").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary) }
                Button(L("Cancel")) { model.cancel() }.controlSize(.small)
            }.padding(.horizontal, 24).padding(.bottom, 12)
            if let p = model.progress { ProgressView(value: Double(p.completedPages), total: Double(max(p.totalPages, 1))).progressViewStyle(.linear).padding(.horizontal, 24).padding(.bottom, 10) }
        }.background(.bar)
    }

    private var activity: some View {
        Group {
            if model.exports.isEmpty {
                ContentUnavailableView(L("A fresh start"), systemImage: "tray", description: Text(L("Your exported documents will appear here.")))
            } else {
                List(model.exports) { record in
                    HStack(spacing: 14) {
                        Image(systemName: "doc.richtext").font(.system(size: 28)).foregroundStyle(FolioTheme.accent).frame(width: 42)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.url.lastPathComponent).font(.system(size: 13, weight: .medium))
                            Text(record.date.formatted(date: .abbreviated, time: .shortened) + " · " + String(format: L("%d pages"), record.pageCount)).font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(L("Preview")) { model.previewURL = record.url }
                        Button { NSWorkspace.shared.activateFileViewerSelecting([record.url]) } label: { Image(systemName: "folder") }.help(L("Show in Finder"))
                    }.padding(.vertical, 10)
                }.listStyle(.inset)
            }
        }
    }
}

struct PreviewItem: Identifiable { var url: URL; var id: URL { url } }

struct PDFPreview: NSViewRepresentable {
    let document: PDFDocument
    func makeNSView(context: Context) -> PDFView { let view = PDFView(); view.autoScales = true; view.displayMode = .singlePageContinuous; view.backgroundColor = .underPageBackgroundColor; view.document = document; return view }
    func updateNSView(_ nsView: PDFView, context: Context) { if nsView.document !== document { nsView.document = document } }
}

struct PDFPreviewSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var document: PDFDocument?
    @State private var locked = false
    @State private var password = ""
    @State private var incorrectPassword = false
    var body: some View {
        VStack(spacing: 0) {
            HStack { Text(url.lastPathComponent).font(.headline); Spacer(); Button(L("Open in Preview")) { NSWorkspace.shared.open(url) }; Button(L("Done")) { dismiss() }.keyboardShortcut(.cancelAction) }.padding(18)
            Divider()
            if let document {
                if locked {
                    VStack(spacing: 18) {
                        Image(systemName: "lock.doc").font(.system(size: 36)).foregroundStyle(FolioTheme.accent)
                        Text(L("Enter the password to view this PDF.")).font(.headline)
                        SecureField(L("Password"), text: $password).textFieldStyle(.roundedBorder)
                            .frame(width: 280).onSubmit { unlock() }
                        if incorrectPassword { Text(L("Incorrect password.")).foregroundStyle(.red) }
                        Button(L("Unlock PDF")) { unlock() }.keyboardShortcut(.defaultAction).disabled(password.isEmpty)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else { PDFPreview(document: document) }
            } else { ContentUnavailableView(L("Unable to open PDF"), systemImage: "doc.badge.ellipsis") }
        }.frame(width: 860, height: 680).onAppear {
            document = PDFDocument(url: url)
            locked = document?.isLocked == true
        }
    }

    private func unlock() {
        guard document?.unlock(withPassword: password) == true else { incorrectPassword = true; return }
        locked = false
        incorrectPassword = false
        password = ""
    }
}

struct ExportResultsView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) { Image(systemName: "checkmark.circle.fill").font(.system(size: 38)).foregroundStyle(FolioTheme.mint); VStack(alignment: .leading, spacing: 4) { Text(L("Beautifully put together.")).font(.system(size: 22, weight: .semibold, design: .rounded)); Text(String(format: L("Created %d PDF files."), model.lastResults.count)).foregroundStyle(.secondary) } }
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(model.lastResults, id: \.self) { url in
                        HStack { Image(systemName: "doc.richtext").foregroundStyle(FolioTheme.accent); Text(url.lastPathComponent).lineLimit(1); Spacer(); Button(L("Open")) { NSWorkspace.shared.open(url) }; Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: { Image(systemName: "folder") }.help(L("Show in Finder")) }.padding(12).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                    }
                    if !model.lastExportWarnings.isEmpty {
                        Text(L("Please review these notes")).font(.headline).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 12)
                        ForEach(Array(model.lastExportWarnings.enumerated()), id: \.offset) { _, warning in Text(localizedWarning(warning)).font(.system(size: 11)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading) }
                    }
                }
            }.frame(maxHeight: 290)
            HStack { Text(L("Existing files are never overwritten.")).font(.system(size: 11)).foregroundStyle(.secondary); Spacer(); Button(L("Done")) { dismiss() }.keyboardShortcut(.defaultAction) }
        }.padding(28).frame(width: 570)
    }
}

struct LogView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 16) {
            HStack { Text(L("Activity log")).font(.title2.bold()); Spacer(); Button(L("Save log…")) { model.saveLog() }; Button(L("Done")) { dismiss() }.keyboardShortcut(.defaultAction) }
            ScrollView { Text(model.logs.isEmpty ? L("No issues to report.") : model.logs.joined(separator: "\n\n")).font(.system(size: 11, design: .monospaced)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding() }.background(FolioTheme.canvas, in: RoundedRectangle(cornerRadius: 12))
        }.padding(24).frame(width: 650, height: 440)
    }
}
