// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Snapr",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Snapr", path: "Sources/Snapr")
    ]
)
