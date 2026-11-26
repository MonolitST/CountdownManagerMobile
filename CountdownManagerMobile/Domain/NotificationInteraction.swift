import Foundation

enum NotificationDestination: Hashable, Sendable {
    case plan(UUID)
    case reminder(UUID)
    case focus(UUID)

    init?(identifier: String) {
        let parts = identifier.split(separator: ".", maxSplits: 3)
        guard parts.count >= 3, parts[0] == "countdown", let id = UUID(uuidString: String(parts[2])) else { return nil }
        switch parts[1] {
        case "plan": self = .plan(id)
        case "reminder": self = .reminder(id)
        case "focus": self = .focus(id)
        default: return nil
        }
    }
}

struct NotificationInteraction: Equatable, Sendable {
    enum Action: Hashable, Sendable {
        case open, openReminders, done, snooze

        var identifier: String {
            switch self {
            case .open: "open"
            case .openReminders: "countdown.reminder.open"
            case .done: "countdown.reminder.done"
            case .snooze: "countdown.reminder.snooze"
            }
        }
    }

    static let reminderCategory = "countdown.reminder"
    let destination: NotificationDestination
    let date: Date
    let action: Action
}
