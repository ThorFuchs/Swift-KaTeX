# Spacing, style and color

Control the presentation of a formula without changing its mathematical source structure.

## Spacing

KaTeX applies mathematical spacing based on the kinds of symbols involved.
Use explicit spacing sparingly: `\,` adds a thin space, `\!` a negative thin
space, and `\quad` or `\qquad` larger spaces.

```tex
\int_0^1 x^2\,dx \qquad a\!b
```

For words and their spaces, use `\text{…}`. Source whitespace alone isn't a
reliable way to lay out mathematical symbols.

## Math style

Display and inline layout use different math styles. Within a formula,
`\displaystyle` and `\textstyle` can request a particular style:

```tex
\displaystyle \sum_{i=1}^{n} i = \frac{n(n+1)}{2}
```

The enclosing SwiftUI APIs still choose whether the formula is displayed as
its own view or embedded in a paragraph; a TeX style command doesn't change the
surrounding SwiftUI layout.

## Color

Use `.mathColor(_:)` to set the default formula color in a view hierarchy.
A color command inside the TeX can style a portion of a formula:

```tex
x + \color{blue}{y} = z
```

The renderer bakes colors into its PDF; arbitrary SwiftUI foreground gradients
don't recolor the artwork. <doc:DisplayingMath> explains dynamic colors and
explicit point sizes.
