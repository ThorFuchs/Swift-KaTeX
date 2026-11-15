// SPDX-License-Identifier: Apache-2.0
import SwiftUI

/// Display (or inline) math rendered by KaTeX as vector artwork.
///
/// - The color follows the environment's primary text color, light or dark.
/// - Wider than the space offered, the artwork scales down uniformly.
/// - The context menu offers "Show Source" and "Copy Source"; VoiceOver reads the TeX.
/// - A formula KaTeX rejects shows its source in monospace with KaTeX's reason.
public struct MathView: View {
    private let tex: String
    private let displayMode: Bool
    private let fontSize: CGFloat
    @Environment(\.self) private var environment
    @State private var state: Phase = .rendering
    @State private var showSource = false

    enum Phase { case rendering, ready(Artwork), failed(String) }

    public init(_ tex: String, displayMode: Bool = true, fontSize: CGFloat = 17) {
        self.tex = tex
        self.displayMode = displayMode
        self.fontSize = fontSize
    }

    private var color: String { Color.cssHex(Color.primary.resolve(in: environment)) }

    public var body: some View {
        Group {
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
        .frame(maxWidth: .infinity, alignment: displayMode ? .center : .leading)
        .contextMenu {
            Button(showSource ? "Show Rendered" : "Show Source") { showSource.toggle() }
            Button("Copy Source") { copy(tex) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Formula"))
        .accessibilityValue(Text(tex))
        .task(id: "\(tex)|\(color)|\(fontSize)|\(displayMode)") { await render() }
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
        let renderer = KaTeXRenderer.shared
        if let hit = renderer.cached(tex, displayMode: displayMode, fontSize: fontSize, color: color) {
            apply(hit); return
        }
        do {
            apply(.success(try await renderer.render(tex, displayMode: displayMode, fontSize: fontSize, color: color)))
        } catch {
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
