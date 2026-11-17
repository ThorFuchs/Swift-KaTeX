// SPDX-License-Identifier: Apache-2.0
import CoreGraphics
import Foundation

/// Why a formula could not be rendered. The view shows the source instead, never a blank.
public enum KaTeXError: Error, Sendable, Equatable {
    /// KaTeX rejected the TeX, for example an undefined control sequence. The message is KaTeX's.
    case parse(String)
    /// The source exceeds `KaTeXRenderer.maximumSourceLength`.
    case tooLong
    /// The page could not load, timed out, or returned no measurable result.
    case engine(String)
}

/// Renders TeX to vector artwork with the bundled KaTeX, one formula at a time, in one
/// hidden WebView shared by all callers. Results are cached by every input that affects them.
@MainActor public final class KaTeXRenderer {
    public static let shared = KaTeXRenderer()
    /// Exact upstream version bundled in this package.
    public nonisolated static let katexVersion = "0.19.1"
    public nonisolated static let maximumSourceLength = 20_000

    private let host: WebRenderHost
    private let cache = ArtworkCache()

    public init() {
        let page = Bundle.module.url(forResource: "render", withExtension: "html")!
        host = WebRenderHost(page: page, readAccess: page.deletingLastPathComponent())
    }

    /// A cached result, if any, without rendering.
    public func cached(_ tex: String, displayMode: Bool = true, fontSize: CGFloat = 17, color: String = "#000000") -> Result<Artwork, any Error>? {
        cache.value(Self.key(tex, displayMode, fontSize, color))
    }

    /// - Parameters:
    ///   - tex: TeX source without delimiters.
    ///   - displayMode: block (`\[…\]`, `$$…$$`) or inline layout.
    ///   - fontSize: point size of the surrounding text.
    ///   - color: a CSS color, normally the resolved primary text color.
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
            throw KaTeXError.engine(String(describing: error)) // transient: not cached
        }
        if case .failure(KaTeXError.engine) = result {} else { cache.store(key, result) }
        return try result.get()
    }

    private func draw(_ tex: String, _ display: Bool, _ fontSize: CGFloat, _ color: String) async throws -> Artwork {
        return try await host.exclusive { view in
            let r = try await host.call(view, "return await window.renderTeX(tex, display, fontPx, color);",
                                        arguments: ["tex": tex, "display": display, "fontPx": Double(fontSize), "color": color],
                                        timeout: .seconds(10))
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
