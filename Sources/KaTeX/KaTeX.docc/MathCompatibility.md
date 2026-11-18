# Macros, compatibility and errors

Understand the boundary between KaTeX features and Swift-KaTeX's fixed renderer configuration.

## Define a macro within an expression

A TeX macro expands input tokens; it doesn't execute Swift or evaluate a
mathematical result. For example:

```tex
\def\square#1{#1^2} \square{x} + \square{y}
```

Swift-KaTeX doesn't expose a shared macro dictionary as a public option. Each
render call supplies no `macros` object to KaTeX, so don't rely on definitions
persisting across independent formulas. Keep a required definition in the same
payload. Macro expansion is bounded by `maxExpand: 1000`.

## Know the bundled configuration

The package bundles KaTeX 0.19.1 and selects inline or display mode per request.
Its page uses `throwOnError: true`, `strict: 'ignore'`, `trust: false`,
`maxExpand: 1000`, `maxSize: 50` and HTML output. These are package settings,
not general KaTeX defaults or caller-configurable options. Inputs are limited
to 20,000 Swift characters. See <doc:SecurityAndLimits> for the full boundary.

Commands that require trust, such as links, HTML and remote images, aren't
permitted as active content. A denied command can produce KaTeX's visual
fallback rather than a parse error. Optional extensions, such as mhchem's
`\ce` command, aren't loaded by this package. KaTeX is a mathematical typesetter,
not a full LaTeX document processor; don't assume arbitrary LaTeX packages or
document-level cross-references are supported.

## Handle failures

An unknown command, malformed group or missing argument can cause a
``KaTeXError/parse(_:)`` error. ``MathView`` shows the source and a reason;
``InlineMath`` supplies the source in place of the rendered image. Rendering
can also fail for resource limits or a transient WebKit error. Use
``KaTeXRenderer/render(_:displayMode:fontSize:color:)`` when the caller needs
to inspect errors directly.

For detailed command support, consult the [KaTeX 0.19.1 supported-functions list](https://github.com/KaTeX/KaTeX/blob/v0.19.1/docs/supported.md)
and [options reference](https://github.com/KaTeX/KaTeX/blob/v0.19.1/docs/options.md).
