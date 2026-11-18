// SPDX-License-Identifier: Apache-2.0
import GalleryContent
import KaTeX
import SwiftUI

@main struct KaTeXGalleryApp: App {
    var body: some Scene {
        WindowGroup("KaTeX Gallery") { GalleryView() }
            .defaultSize(width: 1100, height: 760)
    }
}

private struct GalleryView: View {
    @State private var selection: String? = FormulaSample.all.first?.id
    @State private var renderer = KaTeXRenderer()
    @State private var showSource = false

    private var selected: FormulaSample { FormulaSample.all.first { $0.id == selection } ?? FormulaSample.all[0] }

    var body: some View {
        NavigationSplitView {
            List(FormulaSample.all, selection: $selection) { sample in
                Label(sample.title, systemImage: sample.symbol).tag(sample.id)
            }
            .navigationTitle("KaTeX Gallery")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240)
        } detail: {
            VStack(spacing: 0) {
                HStack {
                    Text("EXPLORE THE EXAMPLES")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(1.2).foregroundStyle(.secondary)
                    Spacer()
                    Toggle("Show source", isOn: $showSource).toggleStyle(.button)
                }.padding(.horizontal, 28).padding(.vertical, 15)
                if let source = try? selected.source() {
                    if showSource {
                        ScrollView {
                            Text(source).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(28)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.background, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20).padding(.bottom, 20)
                    } else {
                        GalleryCard(sample: selected, source: source, renderer: renderer)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.06), radius: 20, y: 6)
                            .padding(.horizontal, 20).padding(.bottom, 20)
                    }
                } else {
                    ContentUnavailableView("Formula unavailable", systemImage: "exclamationmark.triangle", description: Text("The bundled example could not be loaded."))
                }
            }
            .background(Color(red: 0.96, green: 0.965, blue: 0.98))
        }
        .frame(minWidth: 780, minHeight: 560)
    }
}
