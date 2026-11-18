# Operators, sums and limits

Use mathematical operators and attach their bounds to the intended symbol.

## Named functions

Commands such as `\sin`, `\cos`, `\log` and `\exp` use operator spacing and
upright names. Use `\operatorname` for a custom operator name:

```tex
\sin^2(x) + \cos^2(x) = 1, \qquad \operatorname{rank}(A)
```

## Sums, integrals and limits

Attach lower and upper bounds with `_` and `^`; group multi-token bounds:

```tex
\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}
```

```tex
\int_0^1 x^2\,dx = \frac{1}{3}
```

```tex
\lim_{x \to 0} \frac{\sin x}{x} = 1
```

![A series with bounds in display style.](series.png)

KaTeX's inline and display styles can position bounds differently. Choose
`displayMode: false` for inline-style layout; ``InlineMath`` supplies a formula
for a SwiftUI text paragraph. The paragraph can wrap around its image, but the
formula image itself isn't split across lines. These expressions show notation;
Swift-KaTeX doesn't verify their mathematical truth or compute their values.
