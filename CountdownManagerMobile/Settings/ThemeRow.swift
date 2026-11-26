import SwiftUI

struct ThemeRow: View {
    let preference: AppearancePreference
    let selected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack {
                Text(preference.title).brandFont(16)
                Spacer()
                Circle()
                    .strokeBorder(selected ? Palette.accent : Palette.secondary, lineWidth: 0.8)
                    .frame(width: 20, height: 20)
                    .overlay {
                        if selected {
                            Circle().fill(Palette.accent).frame(width: 9, height: 9)
                        }
                    }
                    .padding(.trailing, 5)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 50)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
