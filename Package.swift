// swift-tools-version: 6.4
// SPDX-License-Identifier: Apache-2.0
import PackageDescription

let package = Package(
    name: "Swift-KaTeX",
    platforms: [.macOS(.v14), .iOS(.v17), .visionOS(.v1)],
    products: [
        .library(name: "KaTeX", targets: ["KaTeX"]),
    ],
    targets: [
        .target(name: "KaTeX", resources: [.copy("Resources/render.html"), .copy("Resources/render.js"), .copy("Resources/katex")]),
        .testTarget(name: "KaTeXTests", dependencies: ["KaTeX"]),
    ],
    swiftLanguageModes: [.v6]
)
