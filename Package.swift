// swift-tools-version: 5.10
import PackageDescription
let package = Package(
    name: "FrameStudio",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "FrameStudio", targets: ["FrameStudio"]), .executable(name: "frame-studio-mcp", targets: ["StudioMCP"]), .library(name: "StudioCore", targets: ["StudioCore"])],
    targets: [.target(name: "StudioCore", resources: [.copy("ExportTemplates")]), .executableTarget(name: "FrameStudio", dependencies: ["StudioCore"]), .executableTarget(name: "StudioMCP", dependencies: ["StudioCore"]), .testTarget(name: "StudioCoreTests", dependencies: ["StudioCore"])])
