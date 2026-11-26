import Foundation

struct ReminderDraft {
    var title = ""
    var mode = Mode.interval
    var time = Date.now.addingTimeInterval(60 * 60)
    var minutes = 60
    var weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    var startsAt = 9 * 60
    var endsAt = 19 * 60
    var notifies = true

    enum Mode: CaseIterable, Identifiable {
        case time, interval

        var title: String {
            switch self {
            case .time: String(localized: "Time")
            case .interval: String(localized: "Interval")
            }
        }

        var id: Self { self }
    }

    init(reminder: Reminder? = nil) {
        guard let reminder else { return }
        title = reminder.title
        notifies = reminder.notifies
        switch reminder.rule {
        case let .once(date):
            mode = .time
            time = date
        case let .interval(minutes, days, start, end):
            mode = .interval
            self.minutes = minutes
            weekdays = days
            startsAt = start
            endsAt = end
        }
    }

    var rule: ReminderRule {
        switch mode {
        case .time:
            .once(CalendarDay.calendar.dateInterval(of: .minute, for: time)?.start ?? time)
        case .interval: .interval(minutes: minutes, days: weekdays, start: startsAt, end: endsAt)
        }
    }

    func validationMessage(at now: Date, original: Reminder?) -> String? {
        switch mode {
        case .time:
            guard case let .once(date) = rule, date <= now, original?.rule != rule else { return nil }
            return String(localized: "Choose a time in the future.")
        case .interval:
            if !(1...720).contains(minutes) { return String(localized: "Enter an interval from 1 to 720 minutes.") }
            if weekdays.isEmpty { return String(localized: "Select at least one day.") }
            if startsAt >= endsAt { return String(localized: "End time must be later than the start time.") }
            return nil
        }
    }

    func reminder(updatedFrom original: Reminder?) -> Reminder {
        let rule = rule
        var reminder = original ?? Reminder()
        reminder.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        reminder.notifies = notifies
        if reminder.rule != rule {
            reminder.rule = rule
            reminder.handledThrough = nil
            reminder.snoozedUntil = nil
        }
        return reminder
    }
}
