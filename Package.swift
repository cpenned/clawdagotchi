// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClaudeTamagotchi",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "ClaudeTamagotchi",
            path: "Sources/ClaudeTamagotchi"
        )
    ]
)
