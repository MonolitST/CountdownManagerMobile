import Foundation
import Testing
@testable import CountdownManagerMobile

struct ReminderRuleTests {
    @Test func springTimeChangeSkipsTheMissingHour() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 8)))
        let rule = ReminderRule.interval(minutes: 60, days: [.sunday], start: 60, end: 240)
        let hours = rule.occurrences(after: day, limit: 4, calendar: calendar).map {
            calendar.component(.hour, from: $0)
        }

        #expect(hours == [1, 3, 4, 1])
    }
}
