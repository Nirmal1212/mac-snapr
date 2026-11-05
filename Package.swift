// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Snapr",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .target(name: "SnaprCore", path: "Sources/SnaprCore"),
        .executableTarget(name: "Snapr", dependencies: ["SnaprCore", .product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/Snapr"),
        .testTarget(name: "SnaprCoreTests", dependencies: ["SnaprCore"], path: "Tests/SnaprCoreTests")
    ]
)
