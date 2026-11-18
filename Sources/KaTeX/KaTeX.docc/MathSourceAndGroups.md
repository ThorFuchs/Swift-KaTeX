# Source, groups and scripts

Build a mathematical expression from characters, commands and grouped arguments.

## Commands and braces

A command begins with a backslash. Braces delimit an argument or group; they
don't normally print as visible braces. Explicit grouping avoids ambiguity:

```tex
x_{i+1}^2 + y^{n+1}
```

`_` creates a subscript and `^` a superscript. Without braces the script applies
to the next token: `x^12` doesn't mean the same as `x^{12}`. A command can
also take several arguments, as in `\frac{a}{b}`.

## Words and literal characters

Math mode treats ordinary letters as mathematical symbols. Use `\text{…}` for
words and spaces within a formula:

```tex
f(x) = x^2 \quad \text{for } x \ge 0
```

Characters such as `%`, `_`, `&`, `#` and braces have special roles. Use an
appropriate escaped form for a literal character, for example `\%`, `\_`,
`\{` and `\}`. A percent sign starts a comment through the end of a line:

```tex
x + y % a comment
= z
```

Spaces in math input don't generally give the same spacing as prose. See
<doc:MathSpacingAndStyle> for explicit mathematical spacing. A missing brace
or an unknown command produces a parse error; ``MathView`` and ``InlineMath``
keep the source visible on failure.

See <doc:MathNotation> for the Swift string and document-boundary rules.
