import CoreGraphics
import Foundation
import PDFKit
@testable import KaTeX
import Testing
import WebKit

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

    @Test func requestedColorAppearsInThePDF() async throws {
        let red = try await renderer.render("x+y", color: "#ff0000")
        let blue = try await renderer.render("x+y", color: "#0000ff")
        #expect(try coloredPixelCount(red, redDominant: true) > 0)
        #expect(try coloredPixelCount(blue, redDominant: false) > 0)
    }

    private func coloredPixelCount(_ artwork: Artwork, redDominant: Bool) throws -> Int {
        let width = max(1, Int(ceil(artwork.size.width * 2)))
        let height = max(1, Int(ceil(artwork.size.height * 2)))
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        return try pixels.withUnsafeMutableBytes { buffer in
            let context = try #require(CGContext(data: buffer.baseAddress, width: width, height: height,
                                                 bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                                 space: CGColorSpaceCreateDeviceRGB(),
                                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
            let page = try #require(artwork.page)
            context.scaleBy(x: 2, y: 2)
            context.drawPDFPage(page)
            let bytes = buffer.bindMemory(to: UInt8.self)
            var count = 0
            for offset in stride(from: 0, to: bytes.count, by: 4) where bytes[offset + 3] > 32 {
                let red = Int(bytes[offset])
                let blue = Int(bytes[offset + 2])
                if redDominant ? red > blue + 20 : blue > red + 20 { count += 1 }
            }
            return count
        }
    }

    @Test func cacheKeysCannotCollideAtFieldBoundaries() {
        #expect(KaTeXRenderer.key("b|c", false, 17, "a") != KaTeXRenderer.key("c", false, 17, "a|b"))
    }

    @Test func invalidFontSizesAreRejected() async {
        for size: CGFloat in [0, -1, .infinity, .nan] {
            do {
                _ = try await renderer.render("x", fontSize: size)
                Issue.record("accepted invalid font size \(size)")
            } catch KaTeXError.engine {
                // Invalid sizes fail before reaching WebKit.
            } catch {
                Issue.record("unexpected error: \(error)")
            }
        }
    }

    @Test func cancelledRequestDoesNotReturnCachedArtwork() async throws {
        let fresh = KaTeXRenderer()
        _ = try await fresh.render("x")
        let task = Task { @MainActor in try await fresh.render("x") }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func javascriptTimeoutReleasesTheHost() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let page = directory.appending(path: "index.html")
        try Data("<!doctype html><title>test</title>".utf8).write(to: page)
        let host = WebRenderHost(page: page, readAccess: directory)
        do {
            _ = try await host.exclusive { view in
                try await host.call(view, "await new Promise(() => {}); return {};", arguments: [:], timeout: .milliseconds(100))
            }
            Issue.record("a never-resolving JavaScript promise should time out")
        } catch WebRenderHost.Failure.timeout {
            // A subsequent request must get a fresh, usable page.
        }
        let result = try await host.exclusive { view in
            try await host.call(view, "return { ok: true };", arguments: [:], timeout: .seconds(10))
        }
        #expect(result["ok"] as? Bool == true)
    }

    @Test func deadlineBoundsAnUnfinishedOperation() async throws {
        let host = WebRenderHost(page: URL(filePath: "/unused"), readAccess: URL(filePath: "/"))
        var timedOut = false
        do {
            let _: Data = try await host.withDeadline(.milliseconds(100), onTimeout: { timedOut = true }) {
                try await Task.sleep(for: .seconds(30))
                return Data()
            }
            Issue.record("unfinished operation should time out")
        } catch WebRenderHost.Failure.timeout {}
        #expect(timedOut)
        let value = try await host.withDeadline(.seconds(2)) { Data([42]) }
        #expect(value == Data([42]))
    }

    @Test func pdfTimeoutReleasesAndReplacesThePage() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let page = directory.appending(path: "index.html")
        try Data("<!doctype html><title>test</title>".utf8).write(to: page)
        let host = WebRenderHost(page: page, readAccess: directory)
        var oldView: WKWebView?
        do {
            _ = try await host.exclusive { view in
                oldView = view
                return try await host.pdf(view, rect: CGRect(x: 0, y: 0, width: 10, height: 10), timeout: .milliseconds(100)) { _, _ in
                    try await Task.sleep(for: .seconds(30))
                    return Data()
                }
            }
            Issue.record("unfinished PDF operation should time out")
        } catch WebRenderHost.Failure.timeout {}
        try await host.exclusive { view in
            #expect(view !== oldView)
            let result = try await host.call(view, "return { ok: true };", arguments: [:], timeout: .seconds(10))
            #expect(result["ok"] as? Bool == true)
        }
    }

    @Test func queuedRequestsTimeOutOrCancelWithoutBlockingOthers() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let page = directory.appending(path: "index.html")
        try Data("<!doctype html><title>test</title>".utf8).write(to: page)
        let host = WebRenderHost(page: page, readAccess: directory)
        var holding = false
        let holder = Task { @MainActor in
            try await host.exclusive { _ in
                holding = true
                try await Task.sleep(for: .seconds(30))
            }
        }
        defer { holder.cancel() }
        let startupDeadline = ContinuousClock.now + .seconds(45)
        while !holding {
            guard ContinuousClock.now < startupDeadline else {
                Issue.record("host did not start")
                return
            }
            try Task.checkCancellation()
            try await Task.sleep(for: .milliseconds(10))
        }
        do {
            try await host.exclusive(queueTimeout: .milliseconds(100)) { _ in }
            Issue.record("queued request should time out")
        } catch WebRenderHost.Failure.timeout {}

        let cancelled = Task { @MainActor in try await host.exclusive { _ in } }
        await Task.yield()
        cancelled.cancel()
        await #expect(throws: CancellationError.self) { try await cancelled.value }
        holder.cancel()
        _ = try? await holder.value
        let result = try await host.exclusive { view in
            try await host.call(view, "return { ok: true };", arguments: [:], timeout: .seconds(10))
        }
        #expect(result["ok"] as? Bool == true)
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
