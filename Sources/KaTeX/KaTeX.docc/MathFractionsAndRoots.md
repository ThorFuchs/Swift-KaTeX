# Fractions, roots and powers

Use grouped arguments to make the structure of a formula explicit.

## Fractions

`\frac{numerator}{denominator}` takes two arguments. Fractions can be nested;
`\dfrac` and `\tfrac` request display and text fraction styles respectively.

```tex
\frac{1}{1 + \frac{1}{x}}
```

This is a typeset expression, not an instruction to divide or simplify.

## Roots and powers

`\sqrt{…}` makes a square root. An optional bracketed index gives another root:

```tex
\sqrt{x^2 + y^2} \qquad \sqrt[3]{8}
```

Group compound exponents and subscripts with braces. For example,
`a^{n+1}` attaches the complete expression `n+1` as a superscript.

## Binomial coefficients

`\binom{n}{k}` uses two arguments and displays them without a fraction bar:

```tex
\binom{n}{k} = \frac{n!}{k!(n-k)!}
```

![A fraction and root rendered as a quadratic formula.](fractions.png)

Explore the editable example in <doc:MathGallery> and the upstream
[fractions and binomials reference](https://github.com/KaTeX/KaTeX/blob/v0.19.1/docs/supported.md).
