import SwiftUI

struct ScreenHeader: View {
    let title: String
    var date: Date?
    var addLabel: String?
    var onAdd: (() -> Void)?
    var extendedAction = false
    var titleSize: CGFloat = 31

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).displayFont(titleSize)
                    .accessibilityAddTraits(.isHeader)
                if let date {
                    Text(AppDate.heading(date)).brandFont(12, relativeTo: .caption)
                        .foregroundStyle(Palette.secondary)
                }
            }
            Spacer(minLength: 0)
            if let onAdd, let addLabel {
                Button(action: onAdd) {
                    Group {
                        if extendedAction {
                            Label { Text(addLabel).brandFont(14, weight: .semibold, relativeTo: .subheadline) }
                            icon: { DesignIcon(.addSmall) }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 5)
                                .frame(minHeight: 44)
                        } else {
                            DesignIcon(.add).frame(width: 44, height: 44)
                        }
                    }
                    .foregroundStyle(Palette.onAccent)
                    .card(Palette.accent, cornerRadius: 11)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(addLabel)
            }
        }
    }
}
