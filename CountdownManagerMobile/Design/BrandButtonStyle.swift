import SwiftUI

struct BrandButtonStyle: ButtonStyle {
    var outlined = false
    var compact = false
    var minimumHeight: CGFloat? = nil

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brandFont(compact ? 14 : 15, weight: .semibold, relativeTo: .subheadline)
            .multilineTextAlignment(.center)
            .padding(.vertical, 10)
            .padding(.horizontal, compact ? 4 : 8)
            .frame(maxWidth: .infinity, minHeight: minimumHeight ?? (compact ? 44 : 48))
            .foregroundStyle(outlined ? Palette.accentText : Palette.onAccent)
            .card(outlined ? Palette.surface : Palette.accent, cornerRadius: 12)
            .overlay {
                if outlined { RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.accent, lineWidth: 1) }
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.45)
            .contentShape(.rect(cornerRadius: 12))
    }
}
