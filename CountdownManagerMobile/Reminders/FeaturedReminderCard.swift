import SwiftUI

struct FeaturedReminderCard: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let occurrence: ReminderOccurrence
    let today: Date
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(String(localized: "Next reminder"))
                .brandFont(12, relativeTo: .caption)
                .foregroundStyle(Palette.secondary)
            Button(action: onEdit) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(occurrence.title).displayFont(24, relativeTo: .title2)
                        Text(dateAndTime)
                            .brandFont(14, weight: .medium, relativeTo: .subheadline)
                            .foregroundStyle(occurrence.date < today ? Palette.accentText : Palette.success)
                            .contentTransition(.opacity)
                            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: occurrence.date)
                        Text(occurrence.summary)
                            .brandFont(12, relativeTo: .caption)
                            .foregroundStyle(Palette.secondary)
                    }
                    Spacer(minLength: 8)
                    CalendarLeaf(date: occurrence.date)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            switch occurrence.source {
            case let .reminder(reminder):
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { actions(for: reminder) }
                    VStack(spacing: 10) { actions(for: reminder) }
                }
            case .plan:
                Button(String(localized: "Open plan"), action: onEdit)
                    .buttonStyle(BrandButtonStyle())
            }
        }
        .padding(16)
        .card()
    }

    private var dateAndTime: String {
        let offset = AppDate.dayOffset(to: occurrence.date, from: today, calendar: calendar)
        let day = (-1...1).contains(offset) ? AppDate.relative(offset) : AppDate.short(occurrence.date)
        return "\(day), \(AppDate.clock(occurrence.date, calendar: calendar))"
    }

    private func actions(for reminder: Reminder) -> some View {
        Group {
            Button {
                store.finish(reminder, occurrence: occurrence.date, snoozing: false)
            } label: {
                Label { Text(String(localized: "Done")) } icon: { DesignIcon(.done) }
            }
            .buttonStyle(BrandButtonStyle())
            Button(String(localized: "Snooze")) {
                store.finish(reminder, occurrence: occurrence.date, snoozing: true)
            }
            .buttonStyle(BrandButtonStyle(outlined: true))
            .accessibilityHint(String(localized: "For 10 minutes"))
        }
    }
}
