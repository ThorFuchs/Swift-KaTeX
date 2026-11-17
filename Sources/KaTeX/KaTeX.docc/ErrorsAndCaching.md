# Errors, cancellation, and caching

Handle failed formulas and understand renderer reuse.

## Handle errors

``KaTeXRenderer/render(_:displayMode:fontSize:color:)`` throws
``KaTeXError`` for invalid or overlong input and engine failures. Cancellation
is reported separately as `CancellationError`.

```swift
import KaTeX

@MainActor
func inspectFormula(_ source: String) async {
    do {
        let artwork = try await KaTeXRenderer.shared.render(source)
        _ = artwork.pdf
    } catch is CancellationError {
        // The caller no longer needs the result.
    } catch KaTeXError.tooLong {
        // Ask for shorter source.
    } catch KaTeXError.parse(let message) {
        print("KaTeX rejected the formula: \(message)")
    } catch {
        print("Rendering failed: \(error)")
    }
}
```

An in-flight WebKit operation can take until it finishes or times out before
cancellation is observed. Engine error messages are diagnostic text, not
stable error codes.

## Use the cache

Each renderer caches successful artwork and parse errors by exact source,
display mode, point size, and CSS color. The cache may evict entries; engine
failures aren't cached. ``KaTeXRenderer/cached(_:displayMode:fontSize:color:)``
checks without rendering. A `nil` result means no matching entry is available.
Calling `render` directly is normally sufficient because it checks the cache.
