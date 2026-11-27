import SwiftUI

struct FormFooter: View {
    let title: String
    var disabled = false
    var tablet = false
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(BrandButtonStyle(minimumHeight: 50))
            .disabled(disabled)
            .frame(maxWidth: tablet ? 178 : 530)
            .frame(maxWidth: tablet ? 680 : 530, alignment: tablet ? .trailing : .center)
            .padding(.horizontal, tablet ? 30 : 23)
            .padding(.top, 10)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
            .background(Palette.background.ignoresSafeArea(edges: .bottom))
    }
}
