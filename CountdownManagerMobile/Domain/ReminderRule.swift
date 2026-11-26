import Foundation

enum ReminderRule: Codable, Equatable, Sendable {
    case once(Date)
    case interval(minutes: Int, days: Set<Weekday>, start: Int, end: Int)

    var summary: String {
        switch self {
        case .once: String(localized: "One-time reminder")
        case let .interval(60, _, _, end): String(localized: "Hourly until \(AppDate.clock(minutes: end))")
        case let .interval(minutes, _, _, end):
            String(localized: "Every \(minutes) min · until \(AppDate.clock(minutes: end))")
        }
    }

    var notificationSummary: String {
        switch self {
        case .once: String(localized: "Reminder")
        case .interval: String(localized: "Reminder · \(summary)")
        }
    }

    var repeatingTimes: [DateComponents] {
        guard case let .interval(minutes, days, start, end) = self,
              minutes > 0, (0..<1440).contains(start), (start..<1440).contains(end) else { return [] }
        let weekdays: [Int?] = days.count == Weekday.allCases.count
            ? [nil]
            : Weekday.allCases.filter(days.contains).map { $0.rawValue }
        return weekdays.flatMap { weekday in
            stride(from: start, through: end, by: minutes).map { time in
                DateComponents(hour: time / 60, minute: time % 60, weekday: weekday)
            }
        }
    }

    func occurrences(after reference: Date, limit: Int, calendar: Calendar) -> [Date] {
        guard limit > 0 else { return [] }
        switch self {
        case let .once(date):
            return date > reference ? [date] : []
        case let .interval(minutes, days, start, end):
            guard minutes > 0, !days.isEmpty, (0..<1440).contains(start),
                  (start..<1440).contains(end) else { return [] }
            var result: [Date] = []
            let day = calendar.startOfDay(for: reference)
            // Include an extra week for wall-clock times skipped by daylight saving.
            for offset in 0...((limit + 1) * 7) {
                guard let date = calendar.date(byAdding: .day, value: offset, to: day),
                      let weekday = Weekday(rawValue: calendar.component(.weekday, from: date)),
                      days.contains(weekday) else { continue }
                for time in stride(from: start, through: end, by: minutes) {
                    guard let candidate = calendar.date(bySettingHour: time / 60, minute: time % 60,
                                                       second: 0, of: date, matchingPolicy: .strict),
                          calendar.isDate(candidate, inSameDayAs: date), candidate > reference else { continue }
                    result.append(candidate)
                    if result.count == limit { return result }
                }
            }
            return result
        }
    }
}
