import XCTest
@testable import FolioCore

final class AssetLibraryTests: XCTestCase {
    private func asset(_ name: String) -> ImageAsset { ImageAsset(url: URL(fileURLWithPath: "/samples/\(name)"), pixelWidth: 100, pixelHeight: 100) }
    func testTrailingNumberAndStableOrder() {
        let input = [asset("page10.png"), asset("page003.png"), asset("page2.png"), asset("appendix.png")]
        XCTAssertEqual(AssetLibrary.sorted(input, by: .number).map(\.name), ["page2.png", "page003.png", "page10.png", "appendix.png"])
        XCTAssertEqual(AssetLibrary.sorted(input, by: .manual), input)
        XCTAssertNil(AssetLibrary.trailingNumber("abc123title"))
    }
    func testCommonBookPrefixes() {
        let input = [asset("bac001.png"), asset("000001.png"), asset("cov001.png"), asset("toc001.png"), asset("fow001.png")]
        XCTAssertEqual(AssetLibrary.sorted(input, by: .pdg).map(\.name), ["cov001.png", "fow001.png", "toc001.png", "000001.png", "bac001.png"])
    }
    func testRecursiveDiscoveryExcludesTopAndDeduplicates() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sub = root.appendingPathComponent("Chapter")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data([1]).write(to: root.appendingPathComponent("cover.png"))
        try Data([1]).write(to: sub.appendingPathComponent("page.png"))
        try Data([1]).write(to: sub.appendingPathComponent("notes.txt"))
        XCTAssertEqual(try AssetLibrary.discover(in: [root], recursive: false).map(\.lastPathComponent), ["cover.png"])
        XCTAssertEqual(try AssetLibrary.discover(in: [root], recursive: true, includeRoot: false).map(\.lastPathComponent), ["page.png"])
        XCTAssertEqual(try AssetLibrary.discover(in: [root, sub], recursive: true).count, 2)
    }
}
