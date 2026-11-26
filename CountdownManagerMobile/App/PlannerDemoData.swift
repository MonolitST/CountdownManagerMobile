import Foundation

extension PlannerData {
    static func demo(at now: Date, calendar: Calendar = CalendarDay.calendar) -> Self {
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let later = calendar.date(byAdding: .day, value: 2, to: today) ?? today
        let nextReminder = calendar.date(bySettingHour: 16, minute: 30, second: 0, of: today) ?? now
        let workReminder = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? now
        let finalReminder = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today) ?? now
        return Self(
            plans: [
                Plan(title: String(localized: "Trip to Suzdal"), day: later,
                     note: String(localized: "Two days with no rush. Walk, drink coffee, and enjoy the autumn."), isFavorite: true,
                     checklist: [.init(title: String(localized: "Book a hotel"), isDone: true),
                                 .init(title: String(localized: "Pack your things")), .init(title: String(localized: "Download the route"))],
                     advanceNotice: .oneDay),
                Plan(title: String(localized: "Meet friends"), day: today),
                Plan(title: String(localized: "Send the mockups to Vlad"), day: tomorrow)
            ],
            reminders: [
                Reminder(title: String(localized: "Time to stretch"), rule: .interval(minutes: 60, days: Set(Weekday.allCases),
                                                                start: 9 * 60, end: 19 * 60)),
                Reminder(title: String(localized: "Drink water"), rule: .once(nextReminder)),
                Reminder(title: String(localized: "Send the mockups to Vlad"), rule: .once(workReminder)),
                Reminder(title: String(localized: "Get ready for the trip"), rule: .once(finalReminder))
            ],
            settings: Settings(city: .moscow, weatherLocationMode: .manual)
        )
    }
}
