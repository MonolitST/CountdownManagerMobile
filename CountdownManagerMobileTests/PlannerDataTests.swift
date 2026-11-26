import Foundation
import Testing
@testable import CountdownManagerMobile

struct PlannerDataTests {
    @Test func savingAFavoritePlanUpdatesItsTimerTitle() {
        let first = Plan(title: "Earlier favorite", isFavorite: true)
        var second = Plan(title: "Before")
        let end = Date(timeIntervalSinceReferenceDate: 850_000_000)
        var data = PlannerData(
            plans: [first, second],
            focus: FocusSession(planID: second.id, planTitle: second.title, minutes: 25, endsAt: end)
        )

        second.title = "After"
        second.isFavorite = true
        data.save(plan: second)

        #expect(data.plans.filter(\.isFavorite).map(\.id) == [second.id])
        #expect(data.focus?.planTitle == second.title)
        #expect(data.focus?.endsAt == end)
    }

    @Test func completingAnOccurrenceOnlyRemovesAOneTimeReminder() {
        let date = Date(timeIntervalSinceReferenceDate: 850_000_000)
        let once = Reminder(title: "One time", rule: .once(date))
        let recurring = Reminder(title: "Repeat", rule: .interval(minutes: 60, days: [.friday], start: 540, end: 1080))
        var data = PlannerData(reminders: [once, recurring])

        let completedOnce = data.finishReminder(once.id, occurrence: date, now: date, snoozing: false)
        let completedRecurring = data.finishReminder(recurring.id, occurrence: date, now: date, snoozing: false)

        #expect(completedOnce)
        #expect(completedRecurring)
        #expect(data.reminders.map(\.id) == [recurring.id])
        #expect(data.reminders.first?.handledThrough == date)
    }
}
