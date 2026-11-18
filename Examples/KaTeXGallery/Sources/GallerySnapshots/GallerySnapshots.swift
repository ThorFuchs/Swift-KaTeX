// SPDX-License-Identifier: Apache-2.0
import AppKit
import Foundation
import GalleryContent
import KaTeX
import SwiftUI

/// Captures the actual SwiftUI gallery cards after rendering their formulas.
@main enum GallerySnapshots {
    @MainActor static func main() async throws {
        guard CommandLine.arguments.count == 2 else {
            fputs("Usage: GallerySnapshots <output-directory>\n", stderr)
            exit(2)
        }
        let output = URL(filePath: CommandLine.arguments[1], directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let renderer = KaTeXRenderer()
        for sample in FormulaSample.all {
            let source = try sample.source()
            // Seed the same renderer and exact inputs used by the SwiftUI card.
            let art = try await renderer.render(source, displayMode: !sample.inline, fontSize: sample.fontSize, color: "#000000")
            guard art.size.width > 0 && art.size.height > 0 else { throw SnapshotError.empty(sample.id) }
            let host = NSHostingView(rootView: GalleryCard(sample: sample, source: source, renderer: renderer))
            let frame = NSRect(x: 0, y: 0, width: 1000, height: 600)
            let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = host
            window.orderFront(nil)
            defer { window.orderOut(nil); window.contentView = nil }
            // Allow SwiftUI's task to consume the pre-rendered artwork and lay out.
            // Reject an empty formula panel instead of silently saving a placeholder.
            try await Task.sleep(for: .milliseconds(500))
            let deadline = ContinuousClock.now + .seconds(30)
            var saved = false
            while ContinuousClock.now < deadline {
                host.layoutSubtreeIfNeeded()
                host.displayIfNeeded()
                guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { throw SnapshotError.image(sample.id) }
                host.cacheDisplay(in: host.bounds, to: bitmap)
                if hasInkInFormulaPanel(bitmap) {
                    guard let png = bitmap.representation(using: .png, properties: [:]) else { throw SnapshotError.image(sample.id) }
                    try png.write(to: output.appending(path: "\(sample.id).png"), options: .atomic)
                    saved = true
                    break
                }
                try await Task.sleep(for: .milliseconds(100))
            }
            guard saved else { throw SnapshotError.empty(sample.id) }
            print("Captured \(sample.id)")
        }
    }

    /// The middle of the card contains only the light formula panel and its
    /// dark math or inline text, so it must contain visible foreground pixels.
    private static func hasInkInFormulaPanel(_ bitmap: NSBitmapImageRep) -> Bool {
        var darkPixels = 0
        for y in stride(from: bitmap.pixelsHigh / 3, to: bitmap.pixelsHigh * 2 / 3, by: 4) {
            for x in stride(from: bitmap.pixelsWide / 5, to: bitmap.pixelsWide * 4 / 5, by: 4) {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
                if color.alphaComponent > 0.5 && color.redComponent < 0.4 && color.greenComponent < 0.4 && color.blueComponent < 0.4 {
                    darkPixels += 1
                    if darkPixels >= 8 { return true }
                }
            }
        }
        return false
    }
    enum SnapshotError: Error { case empty(String), image(String) }
}
