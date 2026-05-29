// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Zzan",
    platforms: [
        // Translation.framework's programmatic API (TranslationSession) requires macOS 15+.
        .macOS("15.0")
    ],
    targets: [
        .executableTarget(
            name: "Zzan",
            path: "Sources/Zzan",
            swiftSettings: [
                // Translation.framework's API isn't fully Sendable-annotated yet,
                // so use the Swift 5 concurrency model to avoid spurious errors.
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
