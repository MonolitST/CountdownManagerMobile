import SwiftUI

struct RemindersView: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let today: Date
    let onAdd: () -> Void
    let onEdit: (Reminder) -> Void
    let onOpenPlan: (UUID) -> Void
    var tablet = false
    var wide = false

    var body: some View {
        let model = RemindersViewModel(data: store.data, today: today, calendar: calendar)
        let header = ScreenHeader(
            title: String(localized: "Reminders"), date: today,
            addLabel: String(localized: "New reminder"), onAdd: onAdd,
            extendedAction: tablet, titleSize: tablet ? 36 : 31
        )

        ScreenScroll(topPadding: tablet ? 26 : 10, fillsViewport: model.featured == nil,
                     contentWidth: tablet ? (wide ? 920 : 722) : 530, horizontalPadding: tablet ? 30 : 23) {
            if let next = model.featured {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if wide && (!model.laterToday.isEmpty || !model.otherDays.isEmpty) {
                        HStack(alignment: .top, spacing: 20) {
                            featured(next).frame(minWidth: 275, maxWidth: 380)
                            reminderSections(model).frame(minWidth: 260, maxWidth: .infinity)
                        }
                    } else {
                        scheduled(next, model: model)
                    }
                }
            } else {
                EmptyListLayout {
                    header
                    EmptyListCard(
                        icon: .emptyBell,
                        iconSize: 22,
                        title: "No reminders yet",
                        message: "Create a one-time reminder\nor set a recurring schedule.",
                        buttonTitle: "Create reminder", tablet: tablet,
                        onAdd: onAdd
                    )
                }
            }
        }
    }

    private func featured(_ next: ReminderOccurrence) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if tablet {
                Text("Next reminder")
                    .brandFont(13, weight: .semibold, relativeTo: .footnote)
                    .foregroundStyle(Palette.secondary)
                    .accessibilityAddTraits(.isHeader)
            }
            FeaturedReminderCard(occurrence: next, today: today, onEdit: { open(next) }, tablet: tablet)
                .id(next.id)
                .transition(.opacity)
        }
    }

    private func reminderSections(_ model: RemindersViewModel) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            reminderSection(String(localized: "More today"), occurrences: model.laterToday)
            reminderSection(String(localized: "Other reminders"), occurrences: model.otherDays)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: model.orderedIDs)
    }

    private func scheduled(_ next: ReminderOccurrence, model: RemindersViewModel) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            featured(next)
            reminderSections(model)
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
