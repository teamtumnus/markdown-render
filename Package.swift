// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MarkdownRender",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "MarkdownRender",
            targets: ["MarkdownRender"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "MarkdownRender"
        ),
        .testTarget(
            name: "MarkdownRenderTests",
            dependencies: ["MarkdownRender"]
        ),
    ]
)
