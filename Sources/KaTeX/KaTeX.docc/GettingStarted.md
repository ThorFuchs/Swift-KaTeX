# Getting started

Add Swift-KaTeX to an Apple-platform app and display a formula.

## Add the package

Add `https://github.com/ThorFuchs/Swift-KaTeX.git` in Xcode and select the
`KaTeX` product. The package requires Swift 6.4 and supports macOS 14, iOS 17,
and visionOS 1 or later. Check the repository README for tested platforms.

## Show a formula

```swift
import KaTeX
import SwiftUI

struct FormulaScreen: View {
    var body: some View {
        MathView(#"\int_0^1 x^2\,dx = \frac{1}{3}"#)
    }
}
```

Pass TeX without surrounding `$`, `$$`, `\(` or `\[` delimiters. Swift raw
strings, written `#"..."#`, let you write TeX backslashes directly. The view
renders asynchronously, uses display layout by default, and scales down when
its container is narrower than the artwork.

See <doc:DisplayingMath> for inline layout, color, and Dynamic Type.
