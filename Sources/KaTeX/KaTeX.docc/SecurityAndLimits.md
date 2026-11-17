# Security and resource limits

Understand the renderer's safeguards and their boundaries.

The renderer passes TeX as a JavaScript argument, not executable script.
The bundled page uses a restrictive Content Security Policy, blocks HTTP and
HTTPS through a WebKit content rule, and rejects navigation away from the
page. KaTeX runs with `trust: false`. These protections aren't a general
sandbox or a guarantee that arbitrary hostile input is safe.

``KaTeXRenderer/maximumSourceLength`` is 20,000 Swift characters. Waiting for
a renderer is limited to 60 seconds. Content-rule compilation, page loading,
JavaScript rendering, and PDF creation each have a separate 30-second
deadline. These are individual asynchronous deadlines, not a total time or a
complete CPU and memory limit. The cache limits entry count, not total memory.

Swift-MD's experimental server-side KaTeX adapter runs separately in Node and
emits MathML rather than PDF. Its settings and limits differ; see the
[Swift-MD project](https://github.com/ThorFuchs/Swift-MD) for its status.
