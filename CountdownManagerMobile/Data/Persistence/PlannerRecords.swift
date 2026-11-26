import Foundation
import GRDB

struct PlanRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable {
    static let databaseTableName = "plans"

    let id: UUID
    let position: Int
    let title: String
    let year: Int
    let month: Int
    let day: Int
    let note: String
    let isFavorite: Bool
    let advanceNotice: String

    init(_ plan: Plan, position: Int) {
        id = plan.id
        self.position = position
        title = plan.title
        year = plan.calendarDay.year
        month = plan.calendarDay.month
        day = plan.calendarDay.day
        note = plan.note
        isFavorite = plan.isFavorite
        advanceNotice = plan.advanceNotice.rawValue
    }

    func plan(checklist: [ChecklistItem], attachments: [PlanAttachment]) throws -> Plan {
        guard let notice = AdvanceNotice(rawValue: advanceNotice) else {
            throw PlannerStorageError.invalidAdvanceNotice
        }
        let date = CalendarDay(year: year, month: month, day: day)
        return Plan(id: id, title: title, calendarDay: date, note: note, isFavorite: isFavorite,
                    checklist: checklist, advanceNotice: notice, attachments: attachments)
    }
}

struct ChecklistItemRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable {
    struct Key: Hashable {
        let planID: UUID
        let itemID: UUID
    }

    static let databaseTableName = "checklist_items"

    let planID: UUID
    let itemID: UUID
    let position: Int
    let title: String
    let isDone: Bool

    var id: Key { Key(planID: planID, itemID: itemID) }
    var item: ChecklistItem { ChecklistItem(id: itemID, title: title, isDone: isDone) }

    init(_ item: ChecklistItem, planID: UUID, position: Int) {
        self.planID = planID
        itemID = item.id
        self.position = position
        title = item.title
        isDone = item.isDone
    }

    static func orderedRecords(for plans: [Plan]) -> [Self] {
        plans.flatMap { plan in
            plan.checklist.enumerated().map { position, item in
                Self(item, planID: plan.id, position: position)
            }
        }
    }
}

struct ReminderRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable {
    static let databaseTableName = "reminders"

    let id: UUID
    let position: Int
    let title: String
    let notifies: Bool
    // Use Foundation's reference date to preserve timestamp precision.
    let scheduledAt: Double?
    let intervalMinutes: Int?
    let weekdays: Int?
    let startMinute: Int?
    let endMinute: Int?
    let handledThrough: Double?
    let snoozedUntil: Double?

    init(_ reminder: Reminder, position: Int) {
        id = reminder.id
        self.position = position
        title = reminder.title
        notifies = reminder.notifies
        handledThrough = reminder.handledThrough?.timeIntervalSinceReferenceDate
        snoozedUntil = reminder.snoozedUntil?.timeIntervalSinceReferenceDate
        switch reminder.rule {
        case let .once(date):
            scheduledAt = date.timeIntervalSinceReferenceDate
            intervalMinutes = nil
            weekdays = nil
            startMinute = nil
            endMinute = nil
        case let .interval(minutes, days, start, end):
            scheduledAt = nil
            intervalMinutes = minutes
            weekdays = days.reduce(0) { $0 | (1 << $1.rawValue) }
            startMinute = start
            endMinute = end
        }
    }

    func reminder() throws -> Reminder {
        let rule: ReminderRule
        if let scheduledAt {
            rule = .once(Date(timeIntervalSinceReferenceDate: scheduledAt))
        } else {
            guard let intervalMinutes, let weekdays, let startMinute, let endMinute else {
                throw PlannerStorageError.invalidReminderRule
            }
            let days = Weekday.allCases.filter { weekdays & (1 << $0.rawValue) != 0 }
            rule = .interval(minutes: intervalMinutes, days: Set(days), start: startMinute, end: endMinute)
        }
        return Reminder(id: id, title: title, rule: rule, notifies: notifies,
                        handledThrough: handledThrough.map(Date.init(timeIntervalSinceReferenceDate:)),
                        snoozedUntil: snoozedUntil.map(Date.init(timeIntervalSinceReferenceDate:)))
    }
}
