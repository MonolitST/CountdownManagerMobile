import SwiftUI

struct EditorCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            DesignIcon(.close)
                .foregroundStyle(Palette.accentText)
                .frame(width: 44, height: 44)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .conceptGlass(in: Circle(), interactive: true)
        .accessibilityLabel(String(localized: "Close"))
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
