# KaTeX notation quick reference

Find common forms by task, then follow the links for context and limitations.

Each fenced block is a single TeX payload. Pass it without outer math delimiters
and use a Swift raw string when entering it directly in Swift code. The blocks
are checked with the package's bundled KaTeX 0.19.1 renderer.

## Groups, scripts and text

| Write | Purpose |
| --- | --- |
| `x_{i+1}` | Group a subscript. |
| `x^{n+1}` | Group a superscript. |
| `\text{if }` | Insert words and spaces in math. |
| `\%` | Print a percent sign instead of starting a comment. |

```tex
x_{i+1}^{n+1} \quad \text{if } x \ge 0 \qquad 10\%
```

See <doc:MathSourceAndGroups>.

## Fractions, roots and binomials

| Write | Purpose |
| --- | --- |
| `\frac{a}{b}` | Fraction with numerator and denominator. |
| `\sqrt{x}` | Square root. |
| `\sqrt[3]{x}` | Indexed root. |
| `\binom{n}{k}` | Binomial coefficient. |

```tex
\frac{a}{b}, \quad \sqrt{x}, \quad \sqrt[3]{x}, \quad \binom{n}{k}
```

See <doc:MathFractionsAndRoots>.

## Letters, relations and arrows

| Write | Purpose |
| --- | --- |
| `\alpha`, `\Omega` | Greek letters. |
| `\mathbb{R}` | Blackboard-bold real-number symbol. |
| `\in`, `\subseteq` | Set membership and subset relation. |
| `\le`, `\ne`, `\ge` | Comparison relations. |
| `\to`, `\mapsto` | Arrows. |
| `\hat{x}`, `\vec{v}` | Accents. |

```tex
\alpha \in \mathbb{R}, \quad A \subseteq B, \quad x \mapsto \hat{x} + \vec{v}
```

See <doc:MathSymbolsAndAccents>.

## Operators and bounds

| Write | Purpose |
| --- | --- |
| `\sin x`, `\log x` | Named operators. |
| `\operatorname{rank}(A)` | Custom operator name. |
| `\sum_{i=1}^{n}` | Sum with bounds. |
| `\int_0^1` | Integral with bounds. |
| `\lim_{x \to 0}` | Limit with a grouped condition. |

```tex
\sum_{i=1}^{n} i, \qquad \int_0^1 x\,dx, \qquad \lim_{x \to 0} \sin x
```

See <doc:MathOperatorsAndLimits>.

## Matrices and aligned rows

| Write | Purpose |
| --- | --- |
| `\begin{pmatrix} … \end{pmatrix}` | Matrix with parentheses. |
| `\begin{cases} … \end{cases}` | Piecewise expression. |
| `\begin{aligned} … \end{aligned}` | Aligned equations. |
| `&` and `\\` | Separate columns/alignment points and rows. |

```tex
\begin{pmatrix} a & b \\ c & d \end{pmatrix}
```

See <doc:MathMatricesAndEquations>.

## Spacing and style

| Write | Purpose |
| --- | --- |
| `\,` | Thin mathematical space. |
| `\quad`, `\qquad` | Larger spaces. |
| `\displaystyle` | Request display math style. |
| `\color{blue}{x}` | Color part of a formula. |

```tex
\displaystyle \sum_{i=1}^{n} i \quad + \color{blue}{x}
```

See <doc:MathSpacingAndStyle> and <doc:MathCompatibility> for package
configuration and support boundaries.
