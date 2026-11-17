#if os(macOS) || os(iOS)
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Foundation
@testable import KaTeX
import SwiftUI
import Testing

@MainActor @Suite(.serialized) struct MathViewIntegrationTests {
    #if os(macOS)
    private func window(_ root: AnyView, width: CGFloat = 240) -> (NSWindow, NSHostingView<AnyView>) {
        let host = NSHostingView(rootView: root)
        let window = NSWindow(contentRect: NSRect(x: -4000, y: -4000, width: width, height: 200),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.orderFrontRegardless()
        return (window, host)
    }
    private func close(_ window: NSWindow) { window.close() }
    #else
    private func window(_ root: AnyView, width: CGFloat = 240) -> (UIWindow, UIHostingController<AnyView>) {
        let host = UIHostingController(rootView: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 200))
        window.rootViewController = host
        window.isHidden = false
        return (window, host)
    }
    private func close(_ window: UIWindow) { window.isHidden = true; window.rootViewController = nil }
    #endif

    private func waitUntil(_ condition: @MainActor () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(120)
        while !condition() {
            guard ContinuousClock.now < deadline else { throw TestTimeout() }
            try await Task.sleep(for: .milliseconds(25))
        }
    }

    private struct TestTimeout: Error {}

    @Test func defaultsToTheSharedRenderer() async throws {
        let source = #"x_{\mathrm{shared}}+42"#
        let (window, _) = window(AnyView(MathView(source, fontSize: 19).mathColor(.black)))
        defer { close(window) }
        try await waitUntil { KaTeXRenderer.shared.cached(source, fontSize: 19, color: "#000000") != nil }
        _ = try #require(KaTeXRenderer.shared.cached(source, fontSize: 19, color: "#000000")).get()
    }

    @Test func usesInjectedRendererAndUpdatesWhenRendererOrColorChanges() async throws {
        let source = #"\frac{a}{b} + x"#
        let first = KaTeXRenderer()
        let second = KaTeXRenderer()
        let red = Color(.sRGB, red: 1, green: 0, blue: 0)
        let blue = Color(.sRGB, red: 0, green: 0, blue: 1)
        func view(_ renderer: KaTeXRenderer, _ color: Color) -> AnyView {
            AnyView(VStack {
                MathView(source, displayMode: false, fontSize: 20)
            }.mathRenderer(renderer).mathColor(color))
        }
        let (window, host) = window(view(first, red))
        defer { close(window) }

        try await waitUntil { first.cached(source, displayMode: false, fontSize: 20, color: "#ff0000") != nil }
        _ = try #require(first.cached(source, displayMode: false, fontSize: 20, color: "#ff0000")).get()
        #expect(second.cached(source, displayMode: false, fontSize: 20, color: "#ff0000") == nil)
        host.rootView = view(second, red)
        try await waitUntil { second.cached(source, displayMode: false, fontSize: 20, color: "#ff0000") != nil }
        _ = try #require(second.cached(source, displayMode: false, fontSize: 20, color: "#ff0000")).get()
        host.rootView = view(second, blue)
        try await waitUntil { second.cached(source, displayMode: false, fontSize: 20, color: "#0000ff") != nil }
        _ = try #require(second.cached(source, displayMode: false, fontSize: 20, color: "#0000ff")).get()
    }

    @Test func inlineArtworkReportsBaselineAtNaturalAndConstrainedSizes() async throws {
        let source = #"\frac{a+b+c+d+e}{x+y+z} + \sqrt{x}"#
        let renderer = KaTeXRenderer()
        let artwork = try await renderer.render(source, displayMode: false, fontSize: 20)
        let recorder = BaselineRecorder()
        func probe(width: CGFloat) -> AnyView {
            AnyView(BaselineProbe(recorder: recorder, width: width) {
                MathView(source, displayMode: false, fontSize: 20)
                    .mathRenderer(renderer).mathColor(.black)
            })
        }
        let (window, host) = window(probe(width: artwork.size.width), width: artwork.size.width)
        defer { close(window) }
        try await waitUntil {
            guard let sample = recorder.sample else { return false }
            return abs(sample.width - artwork.size.width) < 1 && abs(sample.height - artwork.size.height) < 1
        }
        let natural = try #require(recorder.sample)
        #expect(abs(natural.first - artwork.baseline) < 0.5)
        #expect(abs(natural.last - artwork.baseline) < 0.5)

        host.rootView = probe(width: artwork.size.width / 2)
        try await waitUntil {
            guard let sample = recorder.sample else { return false }
            return sample.width > 0 && sample.width < artwork.size.width * 0.8 &&
                abs(sample.height - artwork.size.height * sample.width / artwork.size.width) < 1
        }
        let sample = try #require(recorder.sample)
        let expected = artwork.baseline * sample.height / artwork.size.height
        #expect(abs(sample.first - expected) < 0.5)
        #expect(abs(sample.last - expected) < 0.5)
    }

    @Test func dynamicMathColorRespondsToAppearanceChanges() async throws {
        let source = "x_{color}+42"
        let renderer = KaTeXRenderer()
        let colors = ColorRecorder()
        func root(_ scheme: ColorScheme) -> AnyView {
            AnyView(ColorProbe(source: source, colors: colors)
                .mathRenderer(renderer)
                .mathColor(.primary)
                .environment(\.colorScheme, scheme))
        }
        let (window, host) = window(root(.light))
        defer { close(window) }
        try await waitUntil { colors.value != nil }
        let light = try #require(colors.value)
        try await waitUntil { renderer.cached(source, fontSize: 20, color: light) != nil }
        _ = try #require(renderer.cached(source, fontSize: 20, color: light)).get()
        host.rootView = root(.dark)
        try await waitUntil { colors.value != nil && colors.value != light }
        let dark = try #require(colors.value)
        try await waitUntil { renderer.cached(source, fontSize: 20, color: dark) != nil }
        _ = try #require(renderer.cached(source, fontSize: 20, color: dark)).get()
    }

    @Test func dynamicTypeScalesTheDefaultButNotAnExplicitSize() async throws {
        let defaultSource = "x+y+z"
        let fixedSource = "a+b+c"
        let renderer = KaTeXRenderer()
        let sizes = ScaledSizeRecorder()
        func root(_ dynamicSize: DynamicTypeSize) -> AnyView {
            AnyView(VStack {
                ScaledSizeProbe(source: defaultSource, sizes: sizes)
                MathView(fixedSource, fontSize: 20)
            }
            .mathRenderer(renderer)
            .mathColor(.black)
            .environment(\.dynamicTypeSize, dynamicSize))
        }
        let (window, host) = window(root(.large))
        defer { close(window) }
        try await waitUntil { sizes.value != nil }
        let normalSize = try #require(sizes.value)
        try await waitUntil { renderer.cached(defaultSource, fontSize: normalSize, color: "#000000") != nil }
        host.rootView = root(.accessibility3)
        #if os(iOS)
        try await waitUntil { (sizes.value ?? 0) > normalSize }
        #endif
        let expectedSize = try #require(sizes.value)
        #if os(iOS)
        #expect(expectedSize > normalSize)
        #else
        // macOS doesn't necessarily scale metrics for a Dynamic Type override.
        #expect(expectedSize >= 17)
        #endif
        try await waitUntil { renderer.cached(defaultSource, fontSize: expectedSize, color: "#000000") != nil }
        try await waitUntil { renderer.cached(fixedSource, fontSize: 20, color: "#000000") != nil }
        _ = try #require(renderer.cached(defaultSource, fontSize: expectedSize, color: "#000000")).get()
        _ = try #require(renderer.cached(fixedSource, fontSize: 20, color: "#000000")).get()
    }
}

@MainActor private final class ScaledSizeRecorder { var value: CGFloat? }
@MainActor private final class ColorRecorder { var value: String? }

private struct ColorProbe: View {
    let source: String
    let colors: ColorRecorder
    @Environment(\.self) private var environment
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        MathView(source, fontSize: 20)
            .onChange(of: scheme, initial: true) {
                colors.value = Color.cssHex(Color.primary.resolve(in: environment))
            }
    }
}

private struct ScaledSizeProbe: View {
    let source: String
    let sizes: ScaledSizeRecorder
    @ScaledMetric(relativeTo: .body) private var scaledSize: CGFloat = 17

    var body: some View {
        MathView(source)
            .onChange(of: scaledSize, initial: true) { sizes.value = scaledSize }
    }
}

private final class BaselineRecorder: @unchecked Sendable {
    struct Sample { let width: CGFloat; let height: CGFloat; let first: CGFloat; let last: CGFloat }
    private let lock = NSLock()
    private var value: Sample?
    var sample: Sample? { lock.lock(); defer { lock.unlock() }; return value }
    func record(_ value: Sample) { lock.lock(); defer { lock.unlock() }; self.value = value }
}

private struct BaselineProbe: Layout {
    let recorder: BaselineRecorder
    let width: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let view = subviews.first else { return .zero }
        let dimensions = view.dimensions(in: ProposedViewSize(width: width, height: nil))
        recorder.record(.init(width: dimensions.width, height: dimensions.height,
                              first: dimensions[.firstTextBaseline], last: dimensions[.lastTextBaseline]))
        return CGSize(width: dimensions.width, height: dimensions.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(width: width, height: nil))
    }
}
#endif
