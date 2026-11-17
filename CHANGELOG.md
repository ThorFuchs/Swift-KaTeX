# Changelog

## 0.1.1 (2026-11-17)

- Avoid stale artwork when a view's inputs change and honor cancellation before rendering cached or queued requests.
- Use unambiguous cache keys, reject invalid font sizes, and reset the previous CSS color before each render.
- Bound queue waits, content-rule compilation, page loading, JavaScript rendering, and PDF creation; recover the host after a rendering or PDF timeout.
- Document installation, platform limits, and the distinct Swift-MD server-side adapter.
- Add macOS and iOS Simulator test jobs for GitHub Actions.

## 0.1.0 (2026-11-16)

- First version: `KaTeXRenderer` renders to vector PDF artwork in one shared offscreen WKWebView; `MathView` shows it in SwiftUI with light and dark, scale-to-fit, Show/Copy Source and VoiceOver.
- Bundles katex 0.19.1 (npm `sha512-jG8uKntjSEcm2EpQOh0XturpPuuC9r3Sq5HLHdsFdWZT27E672SF19QEi+of0/YeOy15lDgRhKvr5614uRrEfA==`).
