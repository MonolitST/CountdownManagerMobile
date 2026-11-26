import SwiftUI

struct ScreenScroll<Content: View>: View {
    var topPadding: CGFloat = 10
    var fillsViewport = false
    @ViewBuilder var content: Content

    var body: some View {
        if fillsViewport {
            GeometryReader { viewport in
                scroll(minimumContentHeight: max(0, viewport.size.height - topPadding - 18))
            }
        } else {
            scroll(minimumContentHeight: nil)
        }
    }

    private func scroll(minimumContentHeight: CGFloat?) -> some View {
        ScrollView {
            content
                .frame(maxWidth: 530, minHeight: minimumContentHeight, alignment: .topLeading)
                .padding(.horizontal, 23)
                .padding(.top, topPadding)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.background.ignoresSafeArea())
    }
}

extension View {
    func card(_ color: Color = Palette.surface, cornerRadius: CGFloat = 14) -> some View {
        background(color, in: .rect(cornerRadius: cornerRadius))
    }

    func fieldSurface() -> some View {
        card(Palette.surface, cornerRadius: 9)
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Palette.outline, lineWidth: 1))
    }
}
