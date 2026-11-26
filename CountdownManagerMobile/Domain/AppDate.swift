import Foundation

enum AppDate {
    static var languageCode: String {
        Bundle.main.preferredLocalizations.first == "ru" ? "ru" : "en"
    }

    static var locale: Locale {
        let region = Locale.autoupdatingCurrent.region?.identifier ?? (languageCode == "ru" ? "RU" : "US")
        return Locale(identifier: "\(languageCode)_\(region)")
    }

    static func full(_ date: Date) -> String {
        if languageCode == "ru" {
            return "\(short(date)) \(date.formatted(.dateTime.year().locale(locale)))"
        }
        return date.formatted(.dateTime.day().month(.wide).year().locale(locale))
    }

    static func short(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).locale(locale))
    }

    static func abbreviated(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(locale))
    }

    static func heading(_ date: Date) -> String {
        let heading = date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
        return heading.prefix(1).uppercased(with: locale) + heading.dropFirst()
    }

    static func clock(_ date: Date, calendar: Calendar = CalendarDay.calendar) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale,
                                        calendar: calendar, timeZone: calendar.timeZone))
    }

    static func clock(minutes: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return clock(Date(timeIntervalSince1970: Double(minutes) * 60), calendar: calendar)
    }

    static func countdown(_ seconds: Int) -> String {
        "\(padded(seconds / 60)):\(padded(seconds % 60))"
    }

    static func dayOffset(to date: Date, from today: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: today),
                                to: calendar.startOfDay(for: date)).day ?? 0
    }

    static func relative(_ days: Int) -> String {
        switch days {
        case -1: String(localized: "Yesterday")
        case 0: String(localized: "Today")
        case 1: String(localized: "Tomorrow")
        case 2...: String(localized: "In \(days) days")
        default: String(localized: "\(-days) days ago")
        }
    }

    private static func padded(_ value: Int) -> String {
        value.formatted(.number.grouping(.never).precision(.integerLength(2)).locale(locale))
    }
}
