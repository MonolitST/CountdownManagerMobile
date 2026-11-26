import Foundation

struct Reminder: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    var title = ""
    var rule = ReminderRule.once(.now.addingTimeInterval(3600))
    var notifies = true
    var handledThrough: Date?
    var snoozedUntil: Date?

    func nextDisplayDate(at now: Date, calendar: Calendar) -> Date? {
        if let snoozedUntil { return snoozedUntil }
        if case let .once(date) = rule {
            return handledThrough == nil ? date : nil
        }
        return rule.occurrences(after: max(now, handledThrough ?? .distantPast), limit: 1, calendar: calendar).first
    }

    func matchesNotification(at occurrence: Date) -> Bool {
        guard occurrence > (handledThrough ?? .distantPast),
              occurrence >= (snoozedUntil ?? .distantPast) else { return false }
        if case let .once(date) = rule { return occurrence >= date }
        return true
    }

    mutating func finish(occurrence: Date, now: Date) {
        handledThrough = max(handledThrough ?? .distantPast, occurrence, now)
        snoozedUntil = nil
    }

    mutating func snooze(occurrence: Date, now: Date) {
        finish(occurrence: occurrence, now: now)
        // If the reminder is already overdue, postpone it from the current time.
        snoozedUntil = max(now, occurrence).addingTimeInterval(10 * 60)
    }
}
