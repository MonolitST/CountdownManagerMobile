import SwiftUI

struct RemindersView: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let today: Date
    let onAdd: () -> Void
    let onEdit: (Reminder) -> Void
    let onOpenPlan: (UUID) -> Void

    var body: some View {
        let model = RemindersViewModel(data: store.data, today: today, calendar: calendar)
        let header = ScreenHeader(
            title: String(localized: "Reminders"), date: today,
            addLabel: String(localized: "New reminder"), onAdd: onAdd
        )

        ScreenScroll(fillsViewport: model.featured == nil) {
            if let next = model.featured {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    VStack(alignment: .leading, spacing: 18) {
                        FeaturedReminderCard(occurrence: next, today: today) { open(next) }
                            .id(next.id)
                            .transition(.opacity)
                        reminderSection(String(localized: "More today"), occurrences: model.laterToday)
                        reminderSection(String(localized: "Other reminders"), occurrences: model.otherDays)
                    }
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: model.orderedIDs)
                }
            } else {
                EmptyListLayout {
                    header
                    EmptyListCard(
                        icon: .emptyBell,
                        iconSize: 22,
                        title: "No reminders yet",
                        message: "Create a one-time reminder\nor set a recurring schedule.",
                        buttonTitle: "Create reminder",
                        onAdd: onAdd
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func reminderSection(_ title: String, occurrences: [ReminderOccurrence]) -> some View {
        if !occurrences.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
                Text(title)
                    .brandFont(13, relativeTo: .footnote)
                    .foregroundStyle(Palette.secondary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(occurrences) { occurrence in
                    ReminderRow(occurrence: occurrence, today: today) { open(occurrence) }
                }
            }
        }
    }

    private func open(_ occurrence: ReminderOccurrence) {
        switch occurrence.source {
        case let .reminder(reminder): onEdit(reminder)
        case let .plan(plan): onOpenPlan(plan.id)
        }
    }
}
