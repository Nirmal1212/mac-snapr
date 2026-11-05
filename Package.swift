// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Snapr",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "SnaprCore", path: "Sources/SnaprCore"),
        .executableTarget(name: "Snapr", dependencies: ["SnaprCore"], path: "Sources/Snapr"),
        .testTarget(name: "SnaprCoreTests", dependencies: ["SnaprCore"], path: "Tests/SnaprCoreTests")
    ]
)
