import Foundation

struct ReminderOccurrence: Identifiable {
    enum Source {
        case reminder(Reminder)
        case plan(Plan)
    }

    let source: Source
    let date: Date

    var id: UUID {
        switch source {
        case let .reminder(reminder): reminder.id
        case let .plan(plan): plan.id
        }
    }

    var title: String {
        switch source {
        case let .reminder(reminder): reminder.title
        case let .plan(plan): plan.title
        }
    }

    var summary: String {
        switch source {
        case let .reminder(reminder):
            reminder.snoozedUntil == nil ? reminder.rule.summary : String(localized: "Snoozed reminder")
        case .plan:
            String(localized: "Plan reminder")
        }
    }
}
