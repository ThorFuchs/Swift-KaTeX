// SPDX-License-Identifier: Apache-2.0
import CoreGraphics
import Foundation
import SwiftUI

/// Vector artwork: a one-page PDF with its size in points and, for inline use, its baseline
/// measured from the top. The PDF is what export embeds; the view draws the same page.
public final class Artwork: @unchecked Sendable {
    public let pdf: Data
    public let size: CGSize
    public let baseline: CGFloat
    /// Immutable after creation; only read for drawing.
    let page: CGPDFPage?

    init(pdf: Data, size: CGSize, baseline: CGFloat) {
        self.pdf = pdf
        self.size = size
        self.baseline = baseline
        page = CGDataProvider(data: pdf as CFData).flatMap(CGPDFDocument.init)?.page(at: 1)
    }
}

/// Draws an `Artwork` at its natural size, scaled down uniformly when narrower space is offered.
struct ArtworkCanvas: View {
    let artwork: Artwork

    var body: some View {
        Canvas { context, size in
            guard let page = artwork.page else { return }
            let box = page.getBoxRect(.mediaBox)
            guard box.width > 0, box.height > 0 else { return }
            context.withCGContext { cg in
                cg.translateBy(x: 0, y: size.height)
                cg.scaleBy(x: size.width / box.width, y: -size.height / box.height)
                cg.translateBy(x: -box.minX, y: -box.minY)
                cg.drawPDFPage(page)
            }
        }
        .aspectRatio(artwork.size, contentMode: .fit)
        .frame(maxWidth: artwork.size.width)
    }
}

/// A small bounded cache shared by a renderer's views.
@MainActor final class ArtworkCache {
    struct Key: Hashable {
        let tex: String
        let displayMode: Bool
        let fontSize: CGFloat
        let color: String
    }
    private final class CacheKey: NSObject {
        let value: Key
        init(_ value: Key) { self.value = value }
        override var hash: Int { value.hashValue }
        override func isEqual(_ object: Any?) -> Bool { (object as? CacheKey)?.value == value }
    }
    private final class Box { let value: Result<Artwork, any Error>; init(_ v: Result<Artwork, any Error>) { value = v } }
    private let cache: NSCache<CacheKey, Box> = { let c = NSCache<CacheKey, Box>(); c.countLimit = 4_000; return c }()

    func value(_ key: Key) -> Result<Artwork, any Error>? { cache.object(forKey: CacheKey(key))?.value }
    func store(_ key: Key, _ value: Result<Artwork, any Error>) { cache.setObject(Box(value), forKey: CacheKey(key)) }
}

extension Color {
    /// `#rrggbb` (or `#rrggbbaa`) for passing a resolved SwiftUI color to the page.
    /// `Color.Resolved` stores linear components, so convert through sRGB first.
    static func cssHex(_ resolved: Color.Resolved) -> String {
        let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
        let comps = resolved.cgColor.converted(to: srgb, intent: .defaultIntent, options: nil)?.components ?? [0, 0, 0, 1]
        func c(_ v: CGFloat) -> String { String(format: "%02x", Int((max(0, min(1, v)) * 255).rounded())) }
        let alpha = comps.count > 3 ? comps[3] : 1
        return "#" + c(comps[0]) + c(comps[1]) + c(comps[2]) + (alpha < 1 ? c(alpha) : "")
    }
}
