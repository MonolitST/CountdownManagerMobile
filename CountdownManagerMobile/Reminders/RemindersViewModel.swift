import Foundation

struct RemindersViewModel {
    let featured: ReminderOccurrence?
    let laterToday: [ReminderOccurrence]
    let otherDays: [ReminderOccurrence]
    let orderedIDs: [UUID]

    init(data: PlannerData, today: Date, calendar: Calendar) {
        let reminders: [ReminderOccurrence] = data.reminders.compactMap { reminder in
            guard let date = reminder.nextDisplayDate(at: today, calendar: calendar) else { return nil }
            return ReminderOccurrence(source: .reminder(reminder), date: date)
        }
        let plans: [ReminderOccurrence] = data.plans.compactMap { plan in
            guard let date = plan.noticeDate(calendar: calendar), date >= today else { return nil }
            return ReminderOccurrence(source: .plan(plan), date: date)
        }
        let occurrences = (reminders + plans).sorted { first, second in
            if first.date != second.date { return first.date < second.date }
            return first.title.localizedStandardCompare(second.title) == .orderedAscending
        }
        let remaining = occurrences.dropFirst()
        featured = occurrences.first
        laterToday = remaining.filter { calendar.isDate($0.date, inSameDayAs: today) }
        otherDays = remaining.filter { !calendar.isDate($0.date, inSameDayAs: today) }
        orderedIDs = occurrences.map(\.id)
    }
}
