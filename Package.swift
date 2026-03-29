// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Clawdagotchi",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "Clawdagotchi",
            path: "Sources/Clawdagotchi"
        )
    ]
)
