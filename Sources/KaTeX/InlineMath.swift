// SPDX-License-Identifier: Apache-2.0
import CoreGraphics
import SwiftUI

/// Provides a formula as a `Text` value for interpolation into a paragraph.
///
/// The formula is rendered asynchronously in inline mode. Until it is ready,
/// or if rendering fails, the supplied `Text` contains the TeX source. The
/// rendered formula is an image in the text, so it cannot break across lines.
/// When `content` returns a `Text`, its accessibility label includes the TeX
/// source. For other content, provide a label on the resulting view when
/// needed. A spoken mathematical description can be set on the surrounding
/// view with `accessibilityLabel(_:)`.
///
/// The default size scales relative to body text; it doesn't automatically
/// match an arbitrary font applied to the surrounding paragraph. Use
/// ``init(_:fontSize:content:)`` to supply a fixed point size. Color and
/// renderer are inherited through `.mathColor(_:)` and `.mathRenderer(_:)`.
public struct InlineMath<Content: View>: View {
    private let tex: String
    private let explicitFontSize: CGFloat?
    private let content: (Text) -> Content
    @Environment(\.self) private var environment
    @Environment(\.mathRenderer) private var injectedRenderer
    @Environment(\.mathColor) private var mathColor
    @Environment(\.displayScale) private var displayScale
    @ScaledMetric(relativeTo: .body) private var scaledFontSize: CGFloat = 17
    @State private var output: Output?

    private struct RenderID: Hashable {
        let key: ArtworkCache.Key
        let renderer: ObjectIdentifier
        let scale: CGFloat
    }
    private struct Output {
        let id: RenderID
        let image: CGImage
        let descent: CGFloat
    }

    /// Creates inline math whose default size follows Dynamic Type.
    ///
    /// - Parameters:
    ///   - tex: TeX source without delimiters.
    ///   - content: Builds the surrounding view using the formula's `Text`.
    ///     The closure may be evaluated more than once and should be free of
    ///     side effects.
    public init(_ tex: String, @ViewBuilder content: @escaping (Text) -> Content) {
        self.tex = tex
        self.explicitFontSize = nil
        self.content = content
    }

    /// Creates inline math using a fixed, unscaled font size.
    ///
    /// - Parameters:
    ///   - tex: TeX source without delimiters.
    ///   - fontSize: A fixed point size. Scale it in the caller if desired.
    ///   - content: Builds the surrounding view using the formula's `Text`.
    ///     The closure may be evaluated more than once and should be free of
    ///     side effects.
    public init(_ tex: String, fontSize: CGFloat, @ViewBuilder content: @escaping (Text) -> Content) {
        self.tex = tex
        self.explicitFontSize = fontSize
        self.content = content
    }

    private var fontSize: CGFloat { explicitFontSize ?? scaledFontSize }
    private var color: String { Color.cssHex((mathColor ?? .primary).resolve(in: environment)) }
    private var renderer: KaTeXRenderer { injectedRenderer ?? .shared }
    private var renderID: RenderID {
        RenderID(key: KaTeXRenderer.key(tex, false, fontSize, color),
                 renderer: ObjectIdentifier(renderer), scale: displayScale)
    }

    /// The surrounding content, updated when the formula is ready.
    public var body: some View {
        let id = renderID
        let formula: Text = if let output, output.id == id {
            Text(Image(output.image, scale: id.scale, label: Text(verbatim: tex)))
                .baselineOffset(-output.descent)
                .accessibilityLabel(Text(verbatim: tex))
        } else {
            Text(verbatim: tex)
        }
        // A SwiftUI image's label is lost when it is interpolated into Text.
        // Rebuild a plain-TeX paragraph for accessibility when possible.
        let renderedContent = content(formula)
        let accessibilityText = content(Text(verbatim: tex)) as? Text
        Group {
            if let accessibilityText {
                renderedContent.accessibilityLabel(accessibilityText)
            } else {
                renderedContent
            }
        }
        .task(id: id) { await render(id) }
    }

    private func render(_ id: RenderID) async {
        guard !Task.isCancelled else { return }
        if output?.id != id { output = nil }
        let renderer = renderer
        do {
            let artwork = try await renderer.render(id.key.tex, displayMode: false,
                                                    fontSize: id.key.fontSize, color: id.key.color)
            guard !Task.isCancelled, let image = inlineImage(artwork, scale: id.scale) else { return }
            output = Output(id: id, image: image, descent: artwork.size.height - artwork.baseline)
        } catch {
            // The source remains visible for parse errors and transient failures.
        }
    }
}

/// Rasterize at display scale; bound allocation for unusually large formulas.
func inlineImage(_ artwork: Artwork, scale: CGFloat) -> CGImage? {
    guard let page = artwork.page, scale.isFinite, scale > 0,
          artwork.size.width.isFinite, artwork.size.height.isFinite,
          artwork.size.width > 0, artwork.size.height > 0 else { return nil }
    let width = ceil(artwork.size.width * scale)
    let height = ceil(artwork.size.height * scale)
    guard width <= 8192, height <= 8192, width * height <= 16_000_000 else { return nil }
    guard let context = CGContext(data: nil, width: Int(width), height: Int(height),
                                  bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    let box = page.getBoxRect(.mediaBox)
    guard box.width > 0, box.height > 0 else { return nil }
    context.scaleBy(x: artwork.size.width * scale / box.width,
                    y: artwork.size.height * scale / box.height)
    context.translateBy(x: -box.minX, y: -box.minY)
    context.drawPDFPage(page)
    return context.makeImage()
}
