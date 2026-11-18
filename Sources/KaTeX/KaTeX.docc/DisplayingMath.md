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
single wrapping `Text` value.

## Put a formula in a paragraph

Use ``InlineMath`` to interpolate one formula as a `Text` value. The paragraph
can wrap around the formula, which itself stays together as one image.

```swift
import KaTeX
import SwiftUI

struct FormulaParagraph: View {
    var body: some View {
        InlineMath(#"E = mc^2"#) { formula in
            Text("Einstein showed that \(formula) relates mass and energy.")
        }
        .mathColor(.blue)
    }
}
```

Rendering is asynchronous. The TeX source remains visible while it loads and
if rendering or image creation fails. The image is rasterized at the display's
scale. When the closure returns `Text`, the view provides an accessibility
label for the whole paragraph that includes the TeX source. If the closure
returns another view type, provide its accessibility label yourself. For a
spoken mathematical description, set an explicit label on the paragraph and
check VoiceOver in your app. The formula is an image: selection and copying
don't necessarily produce the TeX source. Supply a separate copy action if
your application needs that behavior. The content closure can be evaluated
more than once and should have no side effects.

The default formula size tracks body Dynamic Type, not arbitrary fonts applied
to the surrounding text. For other font sizes, supply a `fontSize` explicitly
and scale it in the caller if appropriate. Formulas that are wider than the
available line don't break internally. Very large raster images fall back to
the source to limit memory use. For editable or semantic math text, use a
dedicated text-layout solution rather than this image-based prototype.

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
