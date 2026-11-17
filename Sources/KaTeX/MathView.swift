// SPDX-License-Identifier: Apache-2.0
import SwiftUI

/// A SwiftUI view that renders TeX as vector artwork using bundled KaTeX.
///
/// Pass TeX source without delimiters. The default point size scales with
/// Dynamic Type; use ``init(_:displayMode:fontSize:)`` for a fixed size. The
/// view draws a PDF, scales it down to fit, and follows `Color.primary` unless
/// you set a math color with `.mathColor(_:)`.
///
/// Inline views provide first and last text baselines for alignment alongside
/// other views. This doesn't embed a view inside a wrapping `Text` paragraph.
/// The context menu offers Show Source and Copy Source; VoiceOver reads the
/// TeX. A rejected formula displays its source and a reason.
public struct MathView: View {
    private let tex: String
    private let displayMode: Bool
    private let explicitFontSize: CGFloat?
    @Environment(\.self) private var environment
    @Environment(\.mathRenderer) private var injectedRenderer
    @Environment(\.mathColor) private var mathColor
    @ScaledMetric(relativeTo: .body) private var scaledFontSize: CGFloat = 17
    @State private var state: Phase = .rendering
    @State private var showSource = false

    enum Phase { case rendering, ready(Artwork), failed(String) }

    /// Creates a view whose default size follows Dynamic Type.
    ///
    /// - Parameters:
    ///   - tex: TeX source without delimiters.
    ///   - displayMode: Whether to use display layout instead of inline layout.
    public init(_ tex: String, displayMode: Bool = true) {
        self.tex = tex
        self.displayMode = displayMode
        self.explicitFontSize = nil
    }

    /// Creates a view with an explicit, unscaled point size.
    ///
    /// - Parameters:
    ///   - tex: TeX source without delimiters.
    ///   - displayMode: Whether to use display layout instead of inline layout.
    ///   - fontSize: A fixed point size. Scale it in the caller if desired.
    public init(_ tex: String, displayMode: Bool = true, fontSize: CGFloat) {
        self.tex = tex
        self.displayMode = displayMode
        self.explicitFontSize = fontSize
    }

    private var fontSize: CGFloat { explicitFontSize ?? scaledFontSize }
    private var color: String { Color.cssHex((mathColor ?? .primary).resolve(in: environment)) }
    private var renderer: KaTeXRenderer { injectedRenderer ?? .shared }
    private var inlineBaselineFraction: CGFloat? {
        guard !displayMode, !showSource, case .ready(let artwork) = state,
              artwork.size.height > 0 else { return nil }
        return artwork.baseline / artwork.size.height
    }

    private struct RenderID: Hashable {
        let key: ArtworkCache.Key
        let renderer: ObjectIdentifier
    }

    /// The rendered formula, a placeholder, or its source and an error message.
    public var body: some View {
        let baselineFraction = inlineBaselineFraction
        return Group {
            if showSource {
                source(note: nil)
            } else {
                switch state {
                case .rendering:
                    Color.clear.frame(height: fontSize * (displayMode ? 2.2 : 1.2))
                case .ready(let artwork):
                    ArtworkCanvas(artwork: artwork)
                case .failed(let reason):
                    source(note: reason)
                }
            }
        }
        .frame(maxWidth: displayMode ? .infinity : nil, alignment: displayMode ? .center : .leading)
        .alignmentGuide(.firstTextBaseline) { dimensions in
            guard let baselineFraction else { return dimensions[.firstTextBaseline] }
            return baselineFraction * dimensions.height
        }
        .alignmentGuide(.lastTextBaseline) { dimensions in
            guard let baselineFraction else { return dimensions[.lastTextBaseline] }
            return baselineFraction * dimensions.height
        }
        .contextMenu {
            Button(showSource ? "Show Rendered" : "Show Source") { showSource.toggle() }
            Button("Copy Source") { copy(tex) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Formula"))
        .accessibilityValue(Text(tex))
        .task(id: RenderID(key: KaTeXRenderer.key(tex, displayMode, fontSize, color), renderer: ObjectIdentifier(renderer))) {
            await render()
        }
    }

    private func source(note: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tex).font(.system(size: fontSize * 0.82, design: .monospaced)).textSelection(.enabled)
            if let note {
                Label(note, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func render() async {
        guard !Task.isCancelled else { return }
        let renderer = renderer
        if let hit = renderer.cached(tex, displayMode: displayMode, fontSize: fontSize, color: color) {
            apply(hit); return
        }
        state = .rendering
        do {
            let artwork = try await renderer.render(tex, displayMode: displayMode, fontSize: fontSize, color: color)
            guard !Task.isCancelled else { return }
            apply(.success(artwork))
        } catch {
            guard !Task.isCancelled else { return }
            apply(.failure(error))
        }
    }

    private func apply(_ result: Result<Artwork, any Error>) {
        switch result {
        case .success(let artwork): state = .ready(artwork)
        case .failure(KaTeXError.parse(let message)): state = .failed(message)
        case .failure(KaTeXError.tooLong): state = .failed("Formula too long to render")
        case .failure: state = .failed("Formula could not be rendered")
        }
    }

    private func copy(_ text: String) {
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }
}
