import Foundation

struct NotificationSchedule: Equatable, Sendable {
    let isEnabled: Bool
    let sound: NotificationSound
    let plans: [PlanNotice]
    let reminders: [Reminder]
    let focus: FocusSession?

    init(_ data: PlannerData, calendar: Calendar = CalendarDay.calendar) {
        isEnabled = data.settings.notificationsEnabled
        sound = data.settings.notificationSound
        plans = data.plans.compactMap { plan in
            guard let date = plan.noticeDate(calendar: calendar) else { return nil }
            return PlanNotice(id: plan.id, title: plan.title, date: date, eventDay: plan.day)
        }
        reminders = data.reminders.filter(\.notifies)
        focus = data.focus
    }

    struct PlanNotice: Equatable, Sendable {
        let id: UUID
        let title: String
        let date: Date
        let eventDay: Date
    }
}
