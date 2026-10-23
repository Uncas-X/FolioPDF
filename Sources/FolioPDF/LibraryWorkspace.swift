import SwiftUI
import AppKit
import UniformTypeIdentifiers
import FolioCore

struct LibraryWorkspace: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var language: LanguageStore
    @State private var dropTargeted = false
    @State private var largePreview: ImageAsset?
    @State private var viewAsList = false
    var body: some View {
        VStack(spacing: 0) {
            if model.assets.isEmpty { emptyState }
            else {
                libraryToolbar
                ScrollView {
                    if viewAsList { LazyVStack(spacing: 5) { ForEach(Array(model.assets.enumerated()), id: \.element.id) { index, asset in imageRow(asset, index: index) } }.padding(20) }
                    else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 144, maximum: 190), spacing: 18)], spacing: 20) {
                            ForEach(Array(model.assets.enumerated()), id: \.element.id) { index, asset in imageCard(asset, index: index) }
                        }.padding(24)
                    }
                }
                libraryFooter
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FolioTheme.canvas.opacity(0.55))
        .overlay { if dropTargeted { RoundedRectangle(cornerRadius: 15).strokeBorder(FolioTheme.accent, style: StrokeStyle(lineWidth: 3, dash: [8])).padding(12).allowsHitTesting(false) } }
        .overlay { if model.importing { ZStack { Color.black.opacity(0.08); VStack(spacing: 12) { ProgressView(); Text(L("Reading your images…")).font(.system(size: 12)) }.padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16)) } } }
        .onDrop(of: [UTType.fileURL], isTargeted: $dropTargeted) { providers in
            guard !model.running && !model.importing else { return false }
            Task {
                var urls: [URL] = []
                for provider in providers {
                    let url: URL? = await withCheckedContinuation { continuation in
                        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                            if let data = item as? Data { continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil)) }
                            else if let url = item as? URL { continuation.resume(returning: url) }
                            else { continuation.resume(returning: nil) }
                        }
                    }
                    if let url { urls.append(url) }
                }
                model.importURLs(urls)
            }
            return true
        }
        .sheet(item: $largePreview) { asset in ImagePreviewSheet(asset: asset) }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 25)
            ZStack {
                Circle().fill(FolioTheme.accent.opacity(0.055)).frame(width: 240, height: 240)
                Circle().stroke(FolioTheme.accent.opacity(0.07), lineWidth: 1).frame(width: 275, height: 275)
                paperIllustration(color: FolioTheme.mint.opacity(0.2), angle: -18).offset(x: -32, y: 5)
                paperIllustration(color: FolioTheme.accent.opacity(0.18), angle: 13).offset(x: 30, y: -5)
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "sparkles").font(.system(size: 27)).foregroundStyle(FolioTheme.accent).padding(.bottom, 8)
                    RoundedRectangle(cornerRadius: 2).fill(FolioTheme.accent.opacity(0.6)).frame(width: 66, height: 5)
                    RoundedRectangle(cornerRadius: 2).fill(.gray.opacity(0.2)).frame(width: 85, height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(.gray.opacity(0.2)).frame(width: 70, height: 4)
                    Spacer()
                    Text("PDF").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(2).foregroundStyle(FolioTheme.accent)
                }.padding(22).frame(width: 132, height: 172).background(FolioTheme.card, in: RoundedRectangle(cornerRadius: 11)).rotationEffect(.degrees(-3)).shadow(color: .black.opacity(0.09), radius: 18, y: 12)
            }.frame(height: 255).accessibilityHidden(true)
            Text(L("A new chapter starts here.")).font(.system(size: 26, weight: .semibold, design: .rounded)).multilineTextAlignment(.center).padding(.top, 12)
            Text(L("Drop in your images. We’ll bring them together.")).font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.top, 10)
            HStack(spacing: 12) {
                Button { model.chooseImages() } label: { Label(L("Add images"), systemImage: "plus").padding(.horizontal, 8).padding(.vertical, 4) }.buttonStyle(.borderedProminent)
                Button { model.chooseFolder() } label: { Label(L("Add folder"), systemImage: "folder").padding(.horizontal, 8).padding(.vertical, 4) }.buttonStyle(.bordered)
            }.padding(.top, 26).disabled(model.importing)
            Text("JPEG · PNG · TIFF · HEIC · GIF · BMP").font(.system(size: 10)).foregroundStyle(.tertiary).padding(.top, 18)
            Spacer(minLength: 30)
            HStack(alignment: .top, spacing: 30) {
                feature("photo.on.rectangle.angled", title: L("Keep the detail"), subtitle: L("Full-resolution pages"))
                feature("text.viewfinder", title: L("Find every word"), subtitle: L("On-device text recognition"))
                feature("square.stack", title: L("Do more at once"), subtitle: L("Folders become documents"))
            }.padding(.horizontal, 24).padding(.bottom, 35)
        }.padding(.horizontal, 24)
    }

    private func paperIllustration(color: Color, angle: Double) -> some View {
        RoundedRectangle(cornerRadius: 11).fill(color).frame(width: 132, height: 172).rotationEffect(.degrees(angle))
    }
    private func feature(_ symbol: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) { Image(systemName: symbol).font(.system(size: 18)).foregroundStyle(FolioTheme.accent.opacity(0.8)); Text(title).font(.system(size: 10, weight: .semibold)); Text(subtitle).font(.system(size: 9)).foregroundStyle(.secondary).multilineTextAlignment(.center) }.frame(maxWidth: .infinity)
    }
    private var libraryToolbar: some View {
        HStack(spacing: 10) {
            Text(String(format: L("%d images"), model.assets.count)).font(.system(size: 12, weight: .semibold))
            Spacer()
            Menu {
                ForEach(FolioCore.SortOrder.allCases, id: \.self) { order in
                    Button { model.changeSort(order) } label: {
                        if order == model.sortOrder { Label(L(order.rawValue), systemImage: "checkmark") }
                        else { Text(L(order.rawValue)) }
                    }
                }
            } label: {
                Label(L(model.sortOrder.rawValue), systemImage: "arrow.up.arrow.down").font(.system(size: 11))
            }.menuStyle(.borderlessButton).fixedSize()
            Divider().frame(height: 16)
            Button { viewAsList.toggle() } label: { Image(systemName: viewAsList ? "square.grid.2x2" : "list.bullet") }.buttonStyle(.plain).help(L("Change view"))
        }.padding(.horizontal, 24).frame(height: 48).disabled(model.running)
    }
    private var libraryFooter: some View {
        HStack(spacing: 12) {
            if !model.selection.isEmpty {
                Button { model.moveSelection(-1) } label: { Image(systemName: "arrow.up") }.help(L("Move earlier"))
                Button { model.moveSelection(1) } label: { Image(systemName: "arrow.down") }.help(L("Move later"))
                Button { model.removeSelection() } label: { Image(systemName: "trash") }.help(L("Remove selected"))
            }
            Spacer()
            Button(L("Select all images")) { model.selection = Set(model.assets.map(\.id)) }.font(.system(size: 10)).buttonStyle(.plain)
            Text(String(format: L("%d pages"), model.totalPages) + " · " + ByteCountFormatter.string(fromByteCount: model.totalBytes, countStyle: .file)).font(.system(size: 10)).foregroundStyle(.secondary)
            Button(L("Clear")) { model.clear() }.font(.system(size: 10)).buttonStyle(.plain)
        }.buttonStyle(.borderless).padding(.horizontal, 24).frame(height: 44).background(.bar).disabled(model.running)
    }
    private func imageCard(_ asset: ImageAsset, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                AssetThumbnail(url: asset.url).padding(10).frame(maxWidth: .infinity).frame(height: 164).background(FolioTheme.card)
                Text(String(format: "%02d", index + 1)).font(.system(size: 10, weight: .semibold, design: .monospaced)).padding(.horizontal, 7).padding(.vertical, 4).background(.regularMaterial, in: Capsule()).padding(8)
                if model.selection.contains(asset.id) { Image(systemName: "checkmark.circle.fill").symbolRenderingMode(.palette).foregroundStyle(.white, FolioTheme.accent).font(.system(size: 18)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(9) }
            }.clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(model.selection.contains(asset.id) ? FolioTheme.accent : .primary.opacity(0.06), lineWidth: model.selection.contains(asset.id) ? 2 : 1))
                .shadow(color: .black.opacity(0.035), radius: 4, y: 3)
            Text(asset.name).font(.system(size: 11, weight: .medium)).lineLimit(1).truncationMode(.middle)
            Text(asset.frameCount > 1 ? String(format: L("%d pages"), asset.frameCount) : "\(asset.pixelWidth) × \(asset.pixelHeight)").font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { largePreview = asset }
        .onTapGesture { select(asset) }
        .onDrag { NSItemProvider(object: asset.id.uuidString as NSString) }
        .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in reorderDrop(providers, target: asset.id) }
        .contextMenu { Button(L("Preview")) { largePreview = asset }; Button(L("Show in Finder")) { NSWorkspace.shared.activateFileViewerSelecting([asset.url]) }; Divider(); Button(L("Remove"), role: .destructive) { model.selection = [asset.id]; model.removeSelection() }.disabled(model.running) }
        .accessibilityElement(children: .combine).accessibilityLabel("\(index + 1). \(asset.name)")
    }
    private func imageRow(_ asset: ImageAsset, index: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)").font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary).frame(width: 24)
            AssetThumbnail(url: asset.url).frame(width: 35, height: 44)
            VStack(alignment: .leading, spacing: 4) { Text(asset.name).font(.system(size: 12, weight: .medium)).lineLimit(1); Text(asset.folder.lastPathComponent).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1) }
            Spacer()
            Text(String(format: L("%d pages"), asset.frameCount)).font(.system(size: 10)).foregroundStyle(.secondary)
        }.padding(10).background(model.selection.contains(asset.id) ? FolioTheme.accent.opacity(0.1) : FolioTheme.card, in: RoundedRectangle(cornerRadius: 9)).contentShape(Rectangle())
            .onTapGesture(count: 2) { largePreview = asset }.onTapGesture { select(asset) }
            .onDrag { NSItemProvider(object: asset.id.uuidString as NSString) }
            .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in reorderDrop(providers, target: asset.id) }
    }
    private func select(_ asset: ImageAsset) {
        if NSEvent.modifierFlags.contains(.command) {
            if model.selection.contains(asset.id) { model.selection.remove(asset.id) } else { model.selection.insert(asset.id) }
        } else { model.selection = [asset.id] }
    }
    private func reorderDrop(_ providers: [NSItemProvider], target: UUID) -> Bool {
        guard !model.running, let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: String.self) { value, _ in
            if let value, let uuid = UUID(uuidString: value) { Task { @MainActor in model.reorder(uuid, before: target) } }
        }
        return true
    }
}

struct AssetThumbnail: View {
    let url: URL
    var maxPixels = 500
    @State private var image: NSImage?
    var body: some View {
        Group { if let image { Image(nsImage: image).resizable().interpolation(.high).scaledToFit() } else { Image(systemName: "photo").font(.system(size: 25)).foregroundStyle(.quaternary) } }
            .task(id: url) {
                let url = url, size = maxPixels
                let cgImage = await Task.detached(priority: .utility) { ImagePipeline.thumbnail(url, maxPixelSize: size) }.value
                if let cgImage, !Task.isCancelled { image = NSImage(cgImage: cgImage, size: .zero) }
            }
    }
}

struct ImagePreviewSheet: View {
    let asset: ImageAsset
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 0) {
            HStack { VStack(alignment: .leading, spacing: 3) { Text(asset.name).font(.headline); Text("\(asset.pixelWidth) × \(asset.pixelHeight) · " + String(format: L("%d pages"), asset.frameCount)).font(.caption).foregroundStyle(.secondary) }; Spacer(); Button(L("Done")) { dismiss() }.keyboardShortcut(.defaultAction) }.padding(18)
            AssetThumbnail(url: asset.url, maxPixels: 1800).padding(25).frame(maxWidth: .infinity, maxHeight: .infinity).background(FolioTheme.canvas)
        }.frame(width: 720, height: 650)
    }
}
