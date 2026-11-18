// swift-tools-version: 6.4
// SPDX-License-Identifier: Apache-2.0
import PackageDescription

let package = Package(
    name: "KaTeXGallery",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../..")],
    targets: [
        .target(name: "GalleryContent", dependencies: [.product(name: "KaTeX", package: "Swift-KaTeX")], resources: [.copy("Formulas")]),
        .executableTarget(name: "KaTeXGallery", dependencies: ["GalleryContent", .product(name: "KaTeX", package: "Swift-KaTeX")]),
        .executableTarget(name: "GallerySnapshots", dependencies: ["GalleryContent", .product(name: "KaTeX", package: "Swift-KaTeX")]),
        .executableTarget(name: "DocumentationExamples", dependencies: [.product(name: "KaTeX", package: "Swift-KaTeX")]),
        .testTarget(name: "GalleryContentTests", dependencies: ["GalleryContent", .product(name: "KaTeX", package: "Swift-KaTeX")]),
    ],
    swiftLanguageModes: [.v6]
)
