# Matrices, cases and aligned equations

Use environments to describe rows, columns and equation alignment.

## Matrices

An environment begins with `\begin{name}` and ends with the matching
`\end{name}`. Inside a matrix, `&` separates columns and `\\` separates rows:

```tex
\begin{pmatrix} a & b \\ c & d \end{pmatrix}
```

`pmatrix` adds parentheses; `bmatrix` uses square brackets. The `array`
environment additionally takes a column-alignment specification:

```tex
\begin{array}{rl} x & y \\ 1 & 2 \end{array}
```

![A matrix transformation rendered with Swift-KaTeX.](matrix.png)

## Piecewise definitions

The `cases` environment combines rows of values and conditions. Put prose in
`\text` so its spacing is treated as text:

```tex
f(x) = \begin{cases} x^2 & \text{if } x \ge 0 \\ -x & \text{if } x < 0 \end{cases}
```

## Aligned derivations

`aligned` marks a common alignment point with `&`:

```tex
\begin{aligned} (x+y)^2 &= (x+y)(x+y) \\ &= x^2+2xy+y^2 \end{aligned}
```

![Two equations aligned at their equals signs.](aligned.png)

An environment name must match at both ends. This package renders each input
as an independent formula; don't assume a document-level equation counter,
label registry or cross-reference system. See <doc:MathCompatibility> and the
[upstream supported environments](https://github.com/KaTeX/KaTeX/blob/v0.19.1/docs/supported.md).
