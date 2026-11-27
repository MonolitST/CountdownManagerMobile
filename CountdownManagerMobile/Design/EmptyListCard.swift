import SwiftUI

struct EmptyListCard: View {
    let icon: ImageResource
    var iconSize: CGFloat = 32
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let buttonTitle: LocalizedStringResource
    var tablet = false
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(Palette.accentText)
                .frame(width: 58, height: 58)
                .card(Palette.inset, cornerRadius: 16)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(title)
                    .displayFont(tablet ? 36 : 26, relativeTo: .title2)
                    .frame(minHeight: 32)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .brandFont(14, relativeTo: .subheadline)
                    .foregroundStyle(Palette.secondary)
                    .lineSpacing(3)
                    .frame(maxWidth: tablet ? 420 : 236, minHeight: tablet ? nil : 40)
            }
            .multilineTextAlignment(.center)

            Button(action: onAdd) {
                if tablet {
                    Label { Text(buttonTitle) } icon: { DesignIcon(.addSmall) }
                } else {
                    Text(buttonTitle)
                }
            }
            .buttonStyle(BrandButtonStyle(compact: true))
            .frame(maxWidth: 168)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .card(tablet ? .clear : Palette.surface)
    }
}
