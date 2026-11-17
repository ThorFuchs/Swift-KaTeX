# Displaying mathematics

Choose layout, color, and sizing for formulas in SwiftUI.

## Align inline math

Set `displayMode` to `false` for inline KaTeX layout. Inline math reports its
first and last text baselines so an `HStack` can align it with surrounding
text, including when the artwork is scaled down.

```swift
import KaTeX
import SwiftUI

struct InlineFormula: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Einstein:")
            MathView(#"E = mc^2"#, displayMode: false)
        }
        .mathColor(.blue)
    }
}
```

This aligns separate views in a stack; `MathView` isn't embedded within a
single wrapping `Text` value. For paragraphs with mixed text and formulas,
the surrounding layout is the application's responsibility.

## Set size and color

When `fontSize` is omitted, the default 17-point size follows Dynamic Type
relative to the body text style. An explicitly supplied `fontSize` is a fixed
point size. You can use `@ScaledMetric` in your own view if you want an
explicit base size that scales.

Use `.mathColor(_:)` on a formula or an ancestor to choose a SwiftUI `Color`.
It resolves in the formula's environment, so dynamic colors can respond to
appearance changes. The default is `Color.primary`. Color is baked into the
PDF; arbitrary foreground styles such as gradients aren't inherited.

The context menu offers Show Source and Copy Source, and VoiceOver reads the
TeX. If rendering fails, the source and a reason stay visible.
