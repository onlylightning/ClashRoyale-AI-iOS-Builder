// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClashRoyaleAI",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ClashRoyaleAICore",
            targets: ["ClashRoyaleAICore"]
        )
    ],
    targets: [
        .target(
            name: "ClashRoyaleAICore",
            path: "Shared"
        )
    ]
)
