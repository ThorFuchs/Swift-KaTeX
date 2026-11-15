# Swift-KaTeX

TeX math for SwiftUI, rendered by the bundled [KaTeX](https://katex.org) 0.19.1 to **vector PDF artwork**.

```swift
import KaTeX

MathView(#"\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}"#)              // display math
MathView(#"a^2 + b^2 = c^2"#, displayMode: false, fontSize: 15)           // inline layout

let art = try await KaTeXRenderer.shared.render(#"\binom{n}{k}"#, color: "#1d1d1f")
art.pdf       // one-page vector PDF, for export or printing
art.size      // points
art.baseline  // from the top, for inline alignment
```

## How it works

- **One shared renderer.** One hidden `WKWebView` serves the whole app. It loads KaTeX once from the package's own files, renders one formula at a time, and returns a PDF of the measured box. Results are cached by source, display mode, size and color.
- **The view draws artwork, not a WebView.** `MathView` draws that PDF natively:
  - it follows the primary text color in light and dark;
  - it scales down to fit;
  - its context menu has **Show Source** and **Copy Source**;
  - VoiceOver reads the TeX.
- **Rejected formulas stay visible.** A formula KaTeX rejects shows its source with KaTeX's reason, never a blank.

## Safety

- **The TeX is data.** It is passed as an argument to the page, never interpolated into script.
- **Nothing is loaded from the network.** Every `http`/`https` load is blocked, and the CSP allows only the package's own script, styles and fonts.
- **KaTeX runs with `trust: false`:** `\href`, `\url` and `\includegraphics` render as text, never as links or loads.

## Requirements

- macOS 14, iOS 17 or visionOS 1, and Swift 6.4 tools.
- Tested on macOS.

## Updating KaTeX

```bash
Scripts/update-upstream.sh 0.19.1
```

- The script checks the npm registry integrity before it replaces anything, and rewrites `Upstream.json`.
- `swift test` then verifies every bundled file against `Upstream.json`.
- Adopt a new version only after it has been public for two weeks.
- Set `SWIFT_KATEX_SAMPLES=<dir>` while running `swift test` to write sample PDFs for a visual check in light and dark.

## License

- Apache-2.0 for this package.
- KaTeX is MIT-licensed; see `Licenses/KaTeX-LICENSE` and `NOTICE`.
