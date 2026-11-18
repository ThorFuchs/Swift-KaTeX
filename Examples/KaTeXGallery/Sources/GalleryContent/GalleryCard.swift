// SPDX-License-Identifier: Apache-2.0
import KaTeX
import SwiftUI

/// One card shared by the interactive gallery and the screenshot generator.
public struct GalleryCard: View {
    let sample: FormulaSample
    let source: String
    let renderer: KaTeXRenderer

    public init(sample: FormulaSample, source: String, renderer: KaTeXRenderer) {
        self.sample = sample
        self.source = source
        self.renderer = renderer
    }

    private var accent: Color { Color(hex: sample.accent) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: sample.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                        .frame(width: 32, height: 32)
                        .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    Text(sample.category)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.3)
                        .foregroundStyle(accent)
                }
                Spacer()
                Text("SWIFT KATEX")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color(red: 0.59, green: 0.61, blue: 0.67))
            }
            .padding(.bottom, 20)

            Text(sample.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.15, green: 0.17, blue: 0.23))
            Text(sample.subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 0.43, green: 0.46, blue: 0.52))
                .padding(.top, 6)
                .padding(.bottom, 22)

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.970, green: 0.974, blue: 0.985))
                if sample.inline {
                    InlineMath(source, fontSize: sample.fontSize) { formula in
                        Text("A small equation, \(formula), can live naturally inside a sentence and wrap with the surrounding words.")
                            .font(.system(size: 24))
                    }
                    .mathRenderer(renderer)
                    .mathColor(.black)
                    .padding(36)
                } else {
                    MathView(source, fontSize: sample.fontSize)
                        .mathRenderer(renderer)
                        .mathColor(.black)
                        .padding(32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(alignment: .top, spacing: 18) {
                Text("TEX SOURCE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(accent)
                    .frame(width: 92, alignment: .leading)
                Text(source)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(red: 0.30, green: 0.32, blue: 0.38))
                    .lineLimit(4)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 20)
        }
        .padding(32)
        .background(.white)
        .environment(\.colorScheme, .light)
    }
}

private extension Color {
    init(hex: String) {
        let value = UInt64(hex.dropFirst(), radix: 16) ?? 0
        self.init(red: Double((value >> 16) & 255) / 255,
                  green: Double((value >> 8) & 255) / 255,
                  blue: Double(value & 255) / 255)
    }
}
