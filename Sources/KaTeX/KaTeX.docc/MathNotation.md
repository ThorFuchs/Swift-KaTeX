# Writing mathematics with KaTeX

Learn the notation accepted by Swift-KaTeX's bundled renderer.

## Start with a formula

Swift-KaTeX accepts a TeX math **payload**: pass the expression itself, without
outer `$…$`, `\(…\)`, `$$…$$`, or `\[…\]` delimiters. Those delimiters belong
to a surrounding document format; this package doesn't scan prose or Markdown
for formulas. Select inline or display layout with the view or renderer API.
The package renders notation; it doesn't calculate or simplify the expression.

```swift
import KaTeX
import SwiftUI

struct QuadraticFormula: View {
    var body: some View {
        MathView(#"\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)
    }
}
```

![The quadratic formula rendered in a SwiftUI gallery card.](fractions.png)

A Swift raw string (`#"…"#`) keeps TeX backslashes readable. With an ordinary
Swift string, escape each backslash. For a complete inline paragraph, use
``InlineMath``; <doc:DisplayingMath> explains sizing, color and accessibility.

## Find the notation you need

- <doc:MathQuickReference> collects common forms on one page.
- <doc:MathSourceAndGroups> introduces commands, braces, scripts and text.
- <doc:MathFractionsAndRoots> covers fractions, roots and binomials.
- <doc:MathSymbolsAndAccents> groups letters, relations, arrows and delimiters.
- <doc:MathOperatorsAndLimits> covers functions, sums, integrals and limits.
- <doc:MathMatricesAndEquations> explains matrices, cases and aligned equations.
- <doc:MathSpacingAndStyle> covers spacing, style and color within a formula.
- <doc:MathCompatibility> describes macros, errors, options and limitations.
- <doc:MathGallery> shows all eight runnable examples and their sources.

## Sources and scope

This task-oriented guide is informed by the mathematics guide in the
RhoeLanguage Document Specification, whose reference edition uses KaTeX
0.19.0. It is adapted for Swift-KaTeX's API and bundled KaTeX **0.19.1**;
RhoeDoc's document delimiters, identity rules and native writer are separate.

For the complete, authoritative upstream lists, see KaTeX's
[0.19.1 supported functions](https://github.com/KaTeX/KaTeX/blob/v0.19.1/docs/supported.md),
[0.19.1 options](https://github.com/KaTeX/KaTeX/blob/v0.19.1/docs/options.md),
and [current support table](https://katex.org/docs/support_table). This guide
is a selected introduction, not a full LaTeX compatibility claim. The checked-in
`render.js` defines this package's actual KaTeX configuration.
