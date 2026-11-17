# Rendering and exporting artwork

Render TeX independently of a SwiftUI view and obtain a vector PDF.

## Render on the main actor

```swift
import Foundation
import KaTeX

@MainActor
func formulaPDF(source: String) async throws -> Data {
    let artwork = try await KaTeXRenderer.shared.render(source, displayMode: false)
    return artwork.pdf
}
```

``Artwork/pdf`` contains the transparent, one-page vector PDF;
``Artwork/size`` is its natural size in points. ``Artwork/baseline`` is
measured from the top. For inline formulas, it is the measured text baseline.
The PDF color is selected when calling the renderer and doesn't adapt later.

## Share a custom renderer

``KaTeXRenderer/shared`` is used by default. If you need a separate queue and
cache, create a renderer and set `.mathRenderer(_:)` on an ancestor:

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
    }
}
```

Each renderer owns its own WebKit host and cache. Keep the instance stable for
as long as its views should share work. An explicitly injected renderer doesn't
change the process-wide ``KaTeXRenderer/shared`` instance.
