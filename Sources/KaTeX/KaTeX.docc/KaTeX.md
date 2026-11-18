# ``KaTeX``

Display TeX mathematics in SwiftUI and export it as vector PDF artwork.

## Overview

Swift-KaTeX bundles KaTeX and renders formulas locally using WebKit. Use
``MathView`` to show a formula, ``InlineMath`` for an interpolated formula in
a text paragraph, or ``KaTeXRenderer`` to obtain ``Artwork`` for a custom
export or display flow.

```swift
import KaTeX

MathView(#"\int_0^1 x^2\,dx = \frac{1}{3}"#)
```

## Topics

### Guides

- <doc:GettingStarted>
- <doc:DisplayingMath>
- <doc:RenderingAndExport>
- <doc:ErrorsAndCaching>
- <doc:SecurityAndLimits>

### Display and rendering

- ``MathView``
- ``InlineMath``
- ``SwiftUICore/View/mathRenderer(_:)``
- ``SwiftUICore/View/mathColor(_:)``
- ``KaTeXRenderer``
- ``Artwork``
- ``KaTeXError``
