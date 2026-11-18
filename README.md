# Swift-KaTeX

TeX math for SwiftUI, rendered by the bundled [KaTeX](https://katex.org) 0.19.1 to **vector PDF artwork**.

## Installation

Add `https://github.com/ThorFuchs/Swift-KaTeX.git` as a Swift package dependency
and add the `KaTeX` product to your target. For a SwiftPM package:

```swift
dependencies: [
    .package(url: "https://github.com/ThorFuchs/Swift-KaTeX.git", from: "0.2.0"),
],
targets: [
    .target(name: "YourTarget", dependencies: [.product(name: "KaTeX", package: "Swift-KaTeX")]),
]
```

## Usage

```swift
import KaTeX

MathView(#"\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}"#)              // display math
MathView(#"a^2 + b^2 = c^2"#, displayMode: false, fontSize: 15)           // inline layout

let art = try await KaTeXRenderer.shared.render(#"\binom{n}{k}"#, color: "#1d1d1f")
art.pdf       // one-page vector PDF, for export or printing
art.size      // points
art.baseline  // from the top, for inline alignment
```

The default font size follows Dynamic Type. A `fontSize` passed explicitly is
a fixed point size; use `@ScaledMetric` in the caller if that size should scale.
For inline math, an `HStack(alignment: .firstTextBaseline)` aligns the formula
with adjacent views. This doesn't insert a view into a wrapping `Text` paragraph.

For a single formula in a wrapping paragraph, `InlineMath` supplies a `Text`
value that can be interpolated:

```swift
import KaTeX
import SwiftUI

struct FormulaParagraph: View {
    var body: some View {
        InlineMath(#"E = mc^2"#) { formula in
            Text("Einstein showed that \(formula) relates mass and energy.")
        }
    }
}
```

The formula is an image in the paragraph, rendered asynchronously at display
resolution. Its source is shown while loading and if rendering fails. The
paragraph wraps around it, but the formula doesn't split across lines. When
the closure returns `Text`, the paragraph's accessibility label includes
the TeX source. For other returned views, provide an accessibility label on
the view yourself. Use an explicit paragraph label for a spoken mathematical
description, and verify VoiceOver in your app.
Copying or selecting the image doesn't guarantee TeX output. The default size
scales with body Dynamic Type, not with arbitrary paragraph fonts; `fontSize:`
specifies a fixed point size.

Use the following modifiers on a math view or an ancestor to select a color and
share a custom renderer. Without them, math uses the primary color and
`KaTeXRenderer.shared`. The renderer is main-actor isolated; retain a custom
instance for as long as its views should share a host and cache.

```swift
import KaTeX
import SwiftUI

struct FormulaGroup: View {
    @State private var renderer = KaTeXRenderer()

    var body: some View {
        VStack {
            MathView(#"a^2+b^2=c^2"#)
            MathView(#"\sqrt{x}"#)
        }
        .mathRenderer(renderer)
        .mathColor(.blue)
    }
}
```

The color is resolved in the view's environment and baked into the PDF.
Arbitrary SwiftUI foreground styles, such as gradients, aren't inherited.

## How it works

- **A shared renderer by default.** One hidden `WKWebView` loads KaTeX from the package's own files, renders one formula at a time, and returns a PDF of the measured box. Results are cached by source, display mode, size and color. Custom renderers have their own hosts and caches.
- **The view draws artwork, not a WebView.** `MathView` draws that PDF natively:
  - it follows the primary text color in light and dark;
  - it scales down to fit;
  - its context menu has **Show Source** and **Copy Source**;
  - VoiceOver reads the TeX.
- **Rejected formulas stay visible.** A formula KaTeX rejects shows its source with KaTeX's reason, never a blank.
- Inline artwork exposes a baseline from its top through `Artwork.baseline`;
  `MathView` uses it for first and last baseline alignment with adjacent views.

## Safety

- **The TeX is data.** It is passed as an argument to the page, never interpolated into script.
- **Nothing is loaded from the network.** Every `http`/`https` load is blocked, and the CSP allows only the package's own script, styles and fonts.
- **KaTeX runs with `trust: false`:** `\href`, `\url` and `\includegraphics` render as text, never as links or loads.
- Sources are limited to 20,000 Swift characters; KaTeX uses `maxExpand: 1000` and `maxSize: 50`. Waiting in the render queue is limited to 60 seconds. Content-rule compilation, page loading, JavaScript rendering, and PDF creation each have their own 30-second deadline. These are asynchronous operation deadlines, not a process sandbox or a complete resource limit for untrusted input.

## Related project

[Swift-MD](https://github.com/ThorFuchs/Swift-MD) has an experimental, opt-in server-side KaTeX adapter. It runs a configured local Node installation and emits MathML for `math` code fences; it does not depend on this Apple-only WebKit package. Its KaTeX settings and input limits differ, so identical output and error handling should not be assumed. Both currently use KaTeX 0.19.1 in their checked-in configurations.

## Requirements

- macOS 14, iOS 17 or visionOS 1, and Swift 6.4 tools.
- Tested on macOS and the iOS Simulator. The visionOS Simulator build is supported; runtime tests are pending.
- The package uses SwiftUI and WebKit and does not support Linux.
- tvOS is not supported: its SDK does not provide the WebKit module used by the renderer.
- Run `swift test` on macOS. The rendering tests require a working WebKit content process.
- In Xcode, choose **Product > Build Documentation** to browse the DocC guides.
  Run `Scripts/build-docc.sh` to validate the API reference and guide examples.

## Updating KaTeX

```bash
Scripts/update-upstream.sh 0.19.1
```

- The script checks the npm registry integrity before it replaces anything, and rewrites `Upstream.json`.
- `swift test` then verifies every bundled file against `Upstream.json`.
- Check that a new version has been public for two weeks before adopting it; the script reports the publication date but does not enforce this policy.
- Set `SWIFT_KATEX_SAMPLES=<dir>` while running `swift test` to write sample PDFs for a visual check in light and dark.

## License

- Apache-2.0 for this package.
- KaTeX is MIT-licensed; see `Licenses/KaTeX-LICENSE` and `NOTICE`.
