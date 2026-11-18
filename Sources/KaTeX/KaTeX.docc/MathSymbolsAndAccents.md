# Symbols, delimiters and accents

Write Greek letters, relations, sets, arrows and decorated expressions.

## Letters and mathematical alphabets

Commands such as `\alpha`, `\beta`, `\theta` and `\Omega` select Greek letters.
Use mathematical alphabet commands when the font conveys meaning:

```tex
\alpha + \beta \in \mathbb{R}, \qquad \mathcal{F} \subseteq \mathcal{P}(X)
```

Here `\mathbb` selects blackboard bold and `\mathcal` a calligraphic alphabet.
Not every alphabet contains every character; consult the upstream support list.
For words, use `\text{…}` rather than changing a sequence of variables into
prose by adding spaces.

## Relations and arrows

Common commands include `\le`, `\ge`, `\ne`, `\in`, `\subseteq`, `\forall`,
`\exists`, `\to`, `\mapsto` and `\Longrightarrow`:

```tex
\forall x \in \mathbb{R},\quad x^2 \ge 0 \Longrightarrow |x| \ge 0
```

![Set membership and an implication rendered in the gallery.](symbols.png)

## Fences and accents

Braces used for grouping aren't printed. Write `\{` and `\}` for visible
braces. Paired `\left` and `\right` size delimiters to their contents:

```tex
\left\langle \frac{x}{y}, \sqrt{z} \right\rangle
```

Accents and decorations apply to a grouped argument:

```tex
\hat{\theta} + \bar{x} + \vec{v} + \overline{AB}
```

The [KaTeX 0.19.1 supported-functions list](https://github.com/KaTeX/KaTeX/blob/v0.19.1/docs/supported.md)
provides a wider selection and details on the available alphabets.
