// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FolioPDF",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "FolioCore", targets: ["FolioCore"]), .executable(name: "FolioPDF", targets: ["FolioPDF"])],
    targets: [
        .target(name: "FolioCore"),
        .executableTarget(name: "FolioPDF", dependencies: ["FolioCore"], resources: [.process("Resources")]),
        .testTarget(name: "FolioCoreTests", dependencies: ["FolioCore"], resources: [.copy("Fixtures")]),
        .testTarget(name: "FolioPDFTests", dependencies: ["FolioPDF"])
    ]
)
