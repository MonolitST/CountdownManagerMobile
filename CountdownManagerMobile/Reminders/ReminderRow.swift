import SwiftUI

struct ReminderRow: View {
    @Environment(\.calendar) private var calendar
    let occurrence: ReminderOccurrence
    let today: Date
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                Text(AppDate.clock(occurrence.date, calendar: calendar))
                    .brandFont(14, weight: .medium, relativeTo: .subheadline)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentText)
                    .frame(minWidth: 46, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(occurrence.title)
                        .brandFont(14, weight: .medium, relativeTo: .subheadline)
                    Text(subtitle)
                        .brandFont(12, relativeTo: .caption)
                        .foregroundStyle(Palette.secondary)
                }
                Spacer(minLength: 0)
                DesignIcon(.chevron).foregroundStyle(Palette.secondary)
            }
            .padding(13)
            .frame(minHeight: 66)
            .card(cornerRadius: 12)
            .contentShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        if calendar.isDate(occurrence.date, inSameDayAs: today) { return occurrence.summary }
        return "\(AppDate.short(occurrence.date)) · \(occurrence.summary)"
    }
}
