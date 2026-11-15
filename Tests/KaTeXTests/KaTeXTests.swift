import CoreGraphics
import Foundation
import PDFKit
@testable import KaTeX
import Testing

@MainActor @Suite(.serialized) struct KaTeXRendering {
    let renderer = KaTeXRenderer.shared

    @Test func rendersVectorArtwork() async throws {
        let art = try await renderer.render(#"\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}"#)
        #expect(art.pdf.starts(with: Array("%PDF".utf8)))
        #expect(art.size.width > 60 && art.size.height > 20)
        #expect(art.page != nil)
    }

    @Test func firstRenderOfAFreshPageEmbedsTheMathFonts() async throws {
        // Regression: KaTeX fonts load lazily; the first PDF of a new page once missed glyphs.
        let fresh = KaTeXRenderer()
        let art = try await fresh.render(#"\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}"#)
        let pdf = String(decoding: art.pdf, as: UTF8.self)
        for face in ["KaTeX_Math", "KaTeX_Size", "KaTeX_Main"] {
            #expect(pdf.contains(face), "\(face) embedded")
        }
    }

    @Test func environmentsThatTextualCannotRender() async throws {
        for tex in [#"\begin{pmatrix} a & b \\ c & d \end{pmatrix}"#,
                    #"\mathbb{E}[X] = \sum_i x_i\, p(x_i), \quad \operatorname{div} F, \quad \binom{n}{k}, \quad \text{if } x \in \mathcal{A}"#,
                    #"\begin{aligned} f(x) &= x^2 \\ &= (x+1)^2 - 2x - 1 \end{aligned}"#] {
            let art = try await renderer.render(tex)
            #expect(art.size.width > 20, "\(tex)")
        }
    }

    @Test func inlineHasABaselineInsideItsHeight() async throws {
        let art = try await renderer.render(#"\frac{a}{b} + x^2"#, displayMode: false)
        #expect(art.baseline > 0 && art.baseline < art.size.height)
        let display = try await renderer.render(#"\frac{a}{b} + x^2"#, displayMode: true)
        #expect(display.size.height >= art.size.height)
    }

    @Test func undefinedCommandIsAParseErrorNotABlank() async {
        await #expect(throws: KaTeXError.self) { try await renderer.render(#"\notacommand{x}"#) }
        do { _ = try await renderer.render(#"\notacommand{x}"#) } catch KaTeXError.parse(let message) {
            #expect(message.contains("Undefined control sequence"))
        } catch { Issue.record("unexpected \(error)") }
    }

    @Test func untrustedCommandsDoNotLinkOrLoad() async throws {
        // trust: false: KaTeX shows \href and \includegraphics as plain text, never a link or a load.
        for tex in [#"\href{https://example.com}{x}"#, #"\url{https://example.com}"#, #"\includegraphics{https://example.com/a.png}"#] {
            let art = try await renderer.render(tex)
            let page = try #require(PDFDocument(data: art.pdf)?.page(at: 0))
            #expect(page.annotations.isEmpty, "no link annotation: \(tex)")
        }
    }

    @Test func hostileTextIsData() async throws {
        let art = try await renderer.render(#"\text{</script><img src=x onerror=alert(1)> `{x}` " ' \textbackslash}"#)
        #expect(art.size.width > 50)
    }

    @Test func colorAndSizeAreSeparateCacheEntries() async throws {
        let a = try await renderer.render("x+y", fontSize: 17, color: "#000000")
        let b = try await renderer.render("x+y", fontSize: 17, color: "#000000")
        let c = try await renderer.render("x+y", fontSize: 17, color: "#ffffff")
        let d = try await renderer.render("x+y", fontSize: 34, color: "#000000")
        #expect(a === b)
        #expect(a !== c)
        #expect(d.size.width > a.size.width * 1.6)
    }

    @Test func overlongSourceIsRejected() async {
        await #expect(throws: KaTeXError.tooLong) { try await renderer.render(String(repeating: "x", count: KaTeXRenderer.maximumSourceLength + 1)) }
    }

    @Test func concurrentRequestsAreSerialized() async throws {
        async let a = renderer.render("a_1", displayMode: false)
        async let b = renderer.render("b^{2}", displayMode: false)
        async let c = renderer.render(#"\sqrt{c}"#, displayMode: false)
        let all = try await [a, b, c]
        #expect(all.allSatisfy { $0.size.width > 0 })
    }
}

/// Writes sample artwork for visual review when `SWIFT_KATEX_SAMPLES` names a directory.
@MainActor @Suite struct KaTeXSamples {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SWIFT_KATEX_SAMPLES"] != nil))
    func writeSamples() async throws {
        let dir = URL(filePath: ProcessInfo.processInfo.environment["SWIFT_KATEX_SAMPLES"]!)
        let samples = [
            #"\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}"#,
            #"\begin{pmatrix} a & b \\ c & d \end{pmatrix} \cdot \vec{v} = \lambda \vec{v}"#,
            #"|x| = \begin{cases} x & x \ge 0 \\ -x & x < 0 \end{cases}"#,
            #"\mathbb{E}[X] = \sum_i x_i\, p(x_i), \quad \operatorname{div} F, \quad \binom{n}{k}, \quad \text{if } x \in \mathcal{A}"#,
        ]
        for (i, tex) in samples.enumerated() {
            for (name, color) in [("light", "#1d1d1f"), ("dark", "#f5f5f7")] {
                try await KaTeXRenderer.shared.render(tex, color: color).pdf.write(to: dir.appending(path: "katex-\(i)-\(name).pdf"))
            }
        }
    }
}
