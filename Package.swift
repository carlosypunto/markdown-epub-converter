// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "markdown-epub-converter",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.17"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.8.6")
    ],
    targets: [
        .executableTarget(
            name: "markdown-epub-converter",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "ZIPFoundation",
                "SwiftSoup"
            ]
        ),
    ]
)
