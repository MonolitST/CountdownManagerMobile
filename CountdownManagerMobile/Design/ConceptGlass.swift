import SwiftUI

extension View {
    @ViewBuilder
    func conceptGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular.tint(Palette.surface.opacity(0.24)).interactive(interactive), in: shape)
        } else {
            background(Palette.surface.opacity(0.5), in: shape)
                .background(.regularMaterial, in: shape)
                .overlay {
                    shape.stroke(Palette.outline.opacity(0.55), lineWidth: 0.7)
                        .allowsHitTesting(false)
                }
        }
    }
}
