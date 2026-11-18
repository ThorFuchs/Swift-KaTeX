# KaTeX Gallery

A small macOS SwiftUI app showing eight runnable examples of the bundled KaTeX
renderer. Select a card in the sidebar and choose **Show source** to inspect
or copy its TeX. The cards use `MathView` or `InlineMath` and share one
`KaTeXRenderer`. The gallery is a separate macOS example package; the library
also supports iOS and visionOS.

From the repository root, build and run the app:

```sh
swift run --package-path Examples/KaTeXGallery KaTeXGallery
```

The editable inputs are in [Formulas](Sources/GalleryContent/Formulas). Test all
of them against the local checkout's renderer:

```sh
swift test --package-path Examples/KaTeXGallery
```

The DocC notation guide's fenced TeX examples are checked independently with
the same bundled renderer:

```sh
swift run --package-path Examples/KaTeXGallery DocumentationExamples Sources/KaTeX/KaTeX.docc
```

To regenerate the README and DocC screenshots on macOS, run:

```sh
swift run --package-path Examples/KaTeXGallery GallerySnapshots Sources/KaTeX/KaTeX.docc/Resources
```

This captures the same SwiftUI cards shown in the app. Rendering can vary with
macOS, Xcode and fonts; inspect regenerated images before committing them.
The cards use a fixed light appearance; they aren't a dark-mode comparison.
