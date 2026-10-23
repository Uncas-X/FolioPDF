import Foundation

public enum AssetLibrary {
    public static func discover(in urls: [URL], recursive: Bool, includeRoot: Bool = true) throws -> [URL] {
        var found: [URL] = []
        let manager = FileManager.default
        for url in urls {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            if values.isDirectory == true {
                if recursive {
                    guard let enumerator = manager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
                    for case let child as URL in enumerator {
                        let resource = try? child.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
                        guard resource?.isRegularFile == true, resource?.isSymbolicLink != true else { continue }
                        if !includeRoot && child.deletingLastPathComponent().standardizedFileURL == url.standardizedFileURL { continue }
                        if ImagePipeline.supportedExtensions.contains(child.pathExtension.lowercased()) { found.append(child) }
                    }
                } else {
                    let children = try manager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
                    found += children.filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true && ImagePipeline.supportedExtensions.contains($0.pathExtension.lowercased()) }
                }
            } else if ImagePipeline.supportedExtensions.contains(url.pathExtension.lowercased()) {
                found.append(url)
            }
        }
        var seen = Set<URL>()
        return found.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }.filter { seen.insert($0.standardizedFileURL).inserted }
    }

    public static func sorted(_ assets: [ImageAsset], by order: SortOrder) -> [ImageAsset] {
        guard order != .manual else { return assets }
        return assets.enumerated().sorted { lhs, rhs in
            let a = lhs.element, b = rhs.element
            if order == .number {
                let an = trailingNumber(a.url.deletingPathExtension().lastPathComponent), bn = trailingNumber(b.url.deletingPathExtension().lastPathComponent)
                if an != bn { return (an ?? Int.max) < (bn ?? Int.max) }
            }
            if order == .pdg {
                let ar = bookRank(a.name), br = bookRank(b.name)
                if ar != br { return ar < br }
            }
            let comparison = a.name.localizedStandardCompare(b.name)
            return comparison == .orderedSame ? lhs.offset < rhs.offset : comparison == .orderedAscending
        }.map(\.element)
    }

    public static func trailingNumber(_ text: String) -> Int? {
        let digits = text.reversed().prefix(while: { $0.isNumber }).reversed()
        return digits.isEmpty ? nil : Int(String(digits))
    }

    // Common Pdg2Pic filename groups; unrecognized prefixes remain after known groups.
    public static func bookRank(_ filename: String) -> Int {
        let name = filename.lowercased()
        for (index, prefix) in ["cov", "bok", "leg", "fow", "!", "toc", "000", "att", "ins", "bac"].enumerated() {
            if name.hasPrefix(prefix) { return index }
        }
        if name.first?.isNumber == true { return 6 }
        return 10
    }
}
