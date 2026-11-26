import SwiftUI

struct SettingsValueRow: View {
    let title: String
    let value: String
    var prominent = false

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .brandFont(prominent ? 16 : 14, relativeTo: .subheadline)
                .foregroundStyle(prominent ? Palette.text : Palette.secondary)
            Spacer(minLength: 6)
            Text(value).brandFont(14, relativeTo: .subheadline)
                .foregroundStyle(prominent ? Palette.secondary : Palette.text)
                .multilineTextAlignment(.trailing)
            DesignIcon(.chevron).foregroundStyle(Palette.secondary)
                .padding(.trailing, 6)
        }
        .frame(minHeight: 44)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
