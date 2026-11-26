import SwiftUI

struct OptionButtonStyle: ButtonStyle {
    var selected: Bool
    var showsOutlineWhenUnselected = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brandFont(14, weight: .medium, relativeTo: .subheadline)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(selected ? Palette.accentText : Palette.secondary)
            .background(selected ? Palette.inset : .clear, in: .rect(cornerRadius: 11))
            .overlay {
                if selected || showsOutlineWhenUnselected {
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(selected ? Palette.accent : Palette.outline, lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(.rect(cornerRadius: 11))
    }
}
