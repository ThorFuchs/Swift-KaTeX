// SPDX-License-Identifier: Apache-2.0
import CoreGraphics
import Foundation

/// A formula parsing, input-length, or rendering failure.
///
/// ``MathView`` displays the source when rendering fails. Cancellation is
/// reported separately as `CancellationError`.
public enum KaTeXError: Error, Sendable, Equatable {
    /// KaTeX rejected the TeX, for example an undefined control sequence. The message is KaTeX's.
    case parse(String)
    /// The source exceeds `KaTeXRenderer.maximumSourceLength`.
    case tooLong
    /// The engine failed, timed out, or returned no measurable result.
    ///
    /// The associated string is diagnostic text rather than a stable error code.
    case engine(String)
}

/// Renders TeX into vector PDF artwork using an offscreen WebKit view.
///
/// Use ``shared`` for a renderer shared by the app, or create a renderer with
/// its own host and cache. Each renderer serializes requests and caches artwork
/// and parse errors by source, layout mode, size, and color. Cache entries may
/// be evicted; transient engine failures aren't cached. All renderer operations
/// are main-actor isolated.
@MainActor public final class KaTeXRenderer {
    /// The renderer used by math views without an injected renderer.
    public static let shared = KaTeXRenderer()
    /// Exact upstream version bundled in this package.
    public nonisolated static let katexVersion = "0.19.1"
    /// The maximum accepted source length, measured in Swift characters.
    public nonisolated static let maximumSourceLength = 20_000

    private let host: WebRenderHost
    private let cache = ArtworkCache()

    /// Creates a renderer with its own WebKit host and cache.
    ///
    /// Independent renderers don't share cached results or a rendering queue.
    public init() {
        let page = Bundle.module.url(forResource: "render", withExtension: "html")!
        host = WebRenderHost(page: page, readAccess: page.deletingLastPathComponent())
    }

    /// Returns a cached result without starting a render.
    ///
    /// - Parameters:
    ///   - tex: The exact TeX source to look up, without delimiters.
    ///   - displayMode: Whether the source uses display layout.
    ///   - fontSize: The point size used for rendering.
    ///   - color: The CSS color used for rendering.
    /// - Returns: Cached artwork or a parse error, or `nil` if no entry exists.
    public func cached(_ tex: String, displayMode: Bool = true, fontSize: CGFloat = 17, color: String = "#000000") -> Result<Artwork, any Error>? {
        cache.value(Self.key(tex, displayMode, fontSize, color))
    }

    /// Renders TeX or returns a matching cached result.
    ///
    /// - Parameters:
    ///   - tex: TeX source without delimiters.
    ///   - displayMode: block (`\[…\]`, `$$…$$`) or inline layout.
    ///   - fontSize: point size of the surrounding text.
    ///   - color: a CSS color, normally the resolved primary text color.
    /// - Returns: A single-page vector PDF and its layout measurements.
    /// - Throws: ``KaTeXError`` or `CancellationError`. A WebKit operation
    ///   already in flight may take until its deadline to finish after cancellation.
    public func render(_ tex: String, displayMode: Bool = true, fontSize: CGFloat = 17, color: String = "#000000") async throws -> Artwork {
        try Task.checkCancellation()
        guard tex.count <= Self.maximumSourceLength else { throw KaTeXError.tooLong }
        guard fontSize.isFinite, fontSize > 0 else { throw KaTeXError.engine("fontSize must be finite and positive") }
        let key = Self.key(tex, displayMode, fontSize, color)
        if let hit = cache.value(key) { return try hit.get() }
        let result: Result<Artwork, any Error>
        do {
            result = .success(try await draw(tex, displayMode, fontSize, color))
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as KaTeXError {
            result = .failure(error)
        } catch {
            try Task.checkCancellation()
            throw KaTeXError.engine(String(describing: error)) // transient: not cached
        }
        try Task.checkCancellation()
        if case .failure(KaTeXError.engine) = result {} else { cache.store(key, result) }
        return try result.get()
    }

    private func draw(_ tex: String, _ display: Bool, _ fontSize: CGFloat, _ color: String) async throws -> Artwork {
        return try await host.exclusive { view in
            let r = try await host.call(view, "return await window.renderTeX(tex, display, fontPx, color);",
                                        arguments: ["tex": tex, "display": display, "fontPx": Double(fontSize), "color": color],
                                        timeout: .seconds(30))
            if let message = r["error"] as? String { throw KaTeXError.parse(message) }
            guard let x = r["x"] as? Double, let y = r["y"] as? Double, let w = r["width"] as? Double, let h = r["height"] as? Double,
                  w > 0, h > 0 else { throw KaTeXError.engine("no measurable result") }
            let baseline = display ? h : ((r["baseline"] as? Double) ?? h)
            let pdf = try await host.pdf(view, rect: CGRect(x: x, y: y, width: w, height: h))
            return Artwork(pdf: pdf, size: CGSize(width: w, height: h), baseline: baseline)
        }
    }

    static func key(_ tex: String, _ display: Bool, _ fontSize: CGFloat, _ color: String) -> ArtworkCache.Key {
        ArtworkCache.Key(tex: tex, displayMode: display, fontSize: fontSize, color: color)
    }
}
