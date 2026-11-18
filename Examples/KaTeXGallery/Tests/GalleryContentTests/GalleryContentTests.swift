// SPDX-License-Identifier: Apache-2.0
import GalleryContent
import KaTeX
import Testing

@MainActor @Suite(.serialized) struct GalleryContentTests {
    @Test(arguments: FormulaSample.all) func everyExampleRenders(_ sample: FormulaSample) async throws {
        let source = try sample.source()
        #expect(!source.isEmpty)
        let artwork = try await KaTeXRenderer.shared.render(source, displayMode: !sample.inline, fontSize: sample.fontSize)
        #expect(artwork.size.width > 0 && artwork.size.height > 0)
        #expect(artwork.pdf.starts(with: Array("%PDF".utf8)))
        if sample.inline { #expect(artwork.baseline >= 0 && artwork.baseline <= artwork.size.height) }
    }

    @Test func documentedMacroScopeAndExtensionBoundary() async throws {
        let renderer = KaTeXRenderer()
        _ = try await renderer.render(#"\gdef\galleryonly{x^2} \galleryonly"#)
        for source in [#"\galleryonly"#, #"\ce{H2O}"#] {
            do {
                _ = try await renderer.render(source)
                Issue.record("Expected a parse error for \(source)")
            } catch KaTeXError.parse {
                // A later formula has a fresh macro namespace; mhchem isn't loaded.
            }
        }
    }
}
