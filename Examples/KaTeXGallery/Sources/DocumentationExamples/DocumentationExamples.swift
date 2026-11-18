// SPDX-License-Identifier: Apache-2.0
import AppKit
import Foundation
import KaTeX

/// Verifies every fenced TeX example in the notation guides with the bundled renderer.
@main enum DocumentationExamples {
    @MainActor static func main() async throws {
        guard CommandLine.arguments.count == 2 else {
            fputs("Usage: DocumentationExamples <docc-catalog>\n", stderr)
            exit(2)
        }
        let catalog = URL(filePath: CommandLine.arguments[1], directoryHint: .isDirectory)
        let pages = try FileManager.default.contentsOfDirectory(at: catalog, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("Math") && $0.pathExtension == "md" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        let pattern = try NSRegularExpression(pattern: "```tex\\n([\\s\\S]*?)\\n```")
        NSApplication.shared.setActivationPolicy(.accessory)
        let renderer = KaTeXRenderer()
        var count = 0
        for page in pages {
            let text = try String(contentsOf: page, encoding: .utf8)
            let matches = pattern.matches(in: text, range: NSRange(text.startIndex..., in: text))
            guard matches.count == text.components(separatedBy: "```tex\n").count - 1 else {
                throw Failure.unclosedFence(page.lastPathComponent)
            }
            for (index, match) in matches.enumerated() {
                guard let range = Range(match.range(at: 1), in: text) else { throw Failure.invalid(page.lastPathComponent) }
                let tex = String(text[range])
                do {
                    let result = try await renderer.render(tex, displayMode: true)
                    guard result.size.width > 0, result.size.height > 0,
                          result.pdf.starts(with: Array("%PDF".utf8)) else { throw Failure.invalid(page.lastPathComponent) }
                } catch {
                    fputs("Failed \(page.lastPathComponent) example \(index + 1): \(error)\n", stderr)
                    throw error
                }
                count += 1
            }
            if !matches.isEmpty { print("Verified \(page.lastPathComponent): \(matches.count) examples") }
        }
        guard count > 0 else { throw Failure.noExamples }
        print("Verified \(count) TeX examples with bundled KaTeX \(KaTeXRenderer.katexVersion).")
    }

    enum Failure: Error { case invalid(String), unclosedFence(String), noExamples }
}
