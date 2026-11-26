import Foundation
import Testing
@testable import CountdownManagerMobile

struct NotificationScheduleTests {
    @Test func unrelatedPlanAndWeatherChangesLeaveScheduleIdentical() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        var data = PlannerData(plans: [Plan(title: "Trip", day: date, advanceNotice: .oneDay)])
        let originalSchedule = NotificationSchedule(data)
        data.plans[0].note = "Bring tickets"
        data.plans[0].checklist = [ChecklistItem(title: "Pack", isDone: true)]
        data.settings.weatherLocationMode = .manual
        data.settings.city = .moscow
        data.settings.appearance = .dark

        #expect(NotificationSchedule(data) == originalSchedule)
    }

    @Test func scheduledDateAndNotificationSoundChangeTheSchedule() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        var data = PlannerData(plans: [Plan(title: "Trip", day: date, advanceNotice: .oneDay)])
        let originalSchedule = NotificationSchedule(data)
        data.plans[0].advanceNotice = .oneWeek
        let differentDate = NotificationSchedule(data)
        data.settings.notificationSound = .silent

        #expect(differentDate != originalSchedule)
        #expect(NotificationSchedule(data) != differentDate)
    }

    @Test func notificationIdentifiersRouteToTheOwningRecord() {
        let id = UUID()
        #expect(NotificationDestination(identifier: "countdown.reminder.\(id).weekly.2.16.0.true") == .reminder(id))
        #expect(NotificationDestination(identifier: "countdown.plan.\(id).1800000000.UTC.false") == .plan(id))
        #expect(NotificationDestination(identifier: "countdown.focus.\(id).1800000000.UTC.true") == .focus(id))
        #expect(NotificationDestination(identifier: "another-app.reminder.\(id)") == nil)
        #expect(NotificationDestination(identifier: "countdown.reminder.invalid") == nil)
    }

    @Test func staleReminderActionsDoNotAffectARescheduledOccurrence() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        var reminder = Reminder(title: "Stretch", rule: .once(date))
        #expect(!reminder.matchesNotification(at: date.addingTimeInterval(-60)))
        #expect(reminder.matchesNotification(at: date))

        reminder.snooze(occurrence: date, now: date)
        #expect(!reminder.matchesNotification(at: date))
        #expect(reminder.matchesNotification(at: date.addingTimeInterval(600)))
    }
}
