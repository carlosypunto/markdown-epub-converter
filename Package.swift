// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "markdown-epub-converter",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.17"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.8.6"),
        .package(url: "https://github.com/swiftlang/swift-format.git", from: "602.0.0")
    ],
    targets: [
        .executableTarget(
            name: "markdown-epub-converter",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftFormat", package: "swift-format"),
                "ZIPFoundation",
                "SwiftSoup"
            ]
        ),
    ]
)
