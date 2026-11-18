// SPDX-License-Identifier: Apache-2.0
import Foundation

/// A runnable formula and its presentation in the gallery.
public struct FormulaSample: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let category: String
    public let subtitle: String
    public let symbol: String
    public let accent: String
    public let inline: Bool

    public var fontSize: CGFloat { inline ? 24 : 32 }

    public func source() throws -> String {
        guard let url = Bundle.module.url(forResource: id, withExtension: "tex", subdirectory: "Formulas") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static let all: [FormulaSample] = [
        .init(id: "fractions", title: "A familiar proportion", category: "FRACTIONS & ROOTS", subtitle: "Build structure with fractions, roots and powers.", symbol: "divide", accent: "#826AB1", inline: false),
        .init(id: "calculus", title: "A continuous idea", category: "INTEGRALS", subtitle: "Make limits and differentials easy to read.", symbol: "function", accent: "#587EAE", inline: false),
        .init(id: "series", title: "An infinite sum", category: "SERIES & LIMITS", subtitle: "Bring a sum and its bounds together.", symbol: "sum", accent: "#AA7456", inline: false),
        .init(id: "matrix", title: "A small transformation", category: "MATRICES", subtitle: "Arrange expressions in rows and columns.", symbol: "square.grid.3x3", accent: "#558A7B", inline: false),
        .init(id: "cases", title: "A piecewise rule", category: "CASES", subtitle: "Combine mathematics with explanatory text.", symbol: "curlybraces", accent: "#B36A7F", inline: false),
        .init(id: "symbols", title: "Sets and symbols", category: "LOGIC & SETS", subtitle: "Express relationships with familiar notation.", symbol: "circle.hexagongrid", accent: "#6888B8", inline: false),
        .init(id: "aligned", title: "Steps in balance", category: "ALIGNED EQUATIONS", subtitle: "Keep a derivation aligned as it unfolds.", symbol: "equal", accent: "#9A75A8", inline: false),
        .init(id: "inline", title: "Math in a sentence", category: "INLINE MATH", subtitle: "Place a formula in a wrapping SwiftUI paragraph.", symbol: "text.alignleft", accent: "#4D8994", inline: true),
    ]
}
