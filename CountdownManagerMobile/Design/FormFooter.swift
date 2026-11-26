import SwiftUI

struct FormFooter: View {
    let title: String
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(BrandButtonStyle(minimumHeight: 50))
            .disabled(disabled)
            .frame(maxWidth: 530)
            .padding(.horizontal, 23)
            .padding(.top, 10)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
            .background(Palette.background.ignoresSafeArea(edges: .bottom))
    }
}
