import SwiftUI

struct ScreenHeader: View {
    let title: String
    var date: Date?
    var addLabel: String?
    var onAdd: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).displayFont(31)
                    .accessibilityAddTraits(.isHeader)
                if let date {
                    Text(AppDate.heading(date)).brandFont(12, relativeTo: .caption)
                        .foregroundStyle(Palette.secondary)
                }
            }
            Spacer(minLength: 0)
            if let onAdd, let addLabel {
                Button(action: onAdd) {
                    DesignIcon(.add)
                        .frame(width: 44, height: 44)
                        .foregroundStyle(Palette.onAccent)
                        .card(Palette.accent, cornerRadius: 11)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(addLabel)
            }
        }
    }
}
