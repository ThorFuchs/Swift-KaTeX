// SPDX-License-Identifier: Apache-2.0
import SwiftUI

extension EnvironmentValues {
    @Entry var mathRenderer: KaTeXRenderer? = nil
    @Entry var mathColor: Color? = nil
}

extension View {
    /// Uses a renderer for mathematical views in this view hierarchy.
    ///
    /// The renderer owns its own WebKit host and cache. Without this modifier,
    /// ``MathView`` uses ``KaTeXRenderer/shared``.
    ///
    /// - Parameter renderer: The renderer to use for descendant math views.
    public func mathRenderer(_ renderer: KaTeXRenderer) -> some View {
        environment(\.mathRenderer, renderer)
    }

    /// Sets the color used to render mathematical views in this view hierarchy.
    ///
    /// The color is resolved in each view's environment, so dynamic colors can
    /// adapt to appearance. Without this modifier, math uses `Color.primary`.
    ///
    /// - Parameter color: A SwiftUI color for descendant math views.
    public func mathColor(_ color: Color) -> some View {
        environment(\.mathColor, color)
    }
}
