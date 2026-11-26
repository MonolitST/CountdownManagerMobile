import Foundation

struct Plan: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    var title = ""
    private(set) var calendarDay: CalendarDay
    var note = ""
    var isFavorite = false
    var checklist: [ChecklistItem] = []
    var advanceNotice: AdvanceNotice = .none
    var attachments: [PlanAttachment] = []

    init(id: UUID = UUID(), title: String = "", day: Date = .now, note: String = "",
         isFavorite: Bool = false, checklist: [ChecklistItem] = [], advanceNotice: AdvanceNotice = .none,
         attachments: [PlanAttachment] = []) {
        self.init(id: id, title: title, calendarDay: CalendarDay(day), note: note, isFavorite: isFavorite,
                  checklist: checklist, advanceNotice: advanceNotice, attachments: attachments)
    }

    init(id: UUID, title: String, calendarDay: CalendarDay, note: String,
         isFavorite: Bool, checklist: [ChecklistItem], advanceNotice: AdvanceNotice,
         attachments: [PlanAttachment] = []) {
        self.id = id
        self.title = title
        self.calendarDay = calendarDay
        self.note = note
        self.isFavorite = isFavorite
        self.checklist = checklist
        self.advanceNotice = advanceNotice
        self.attachments = attachments
    }

    var day: Date {
        get { calendarDay.date() }
        set { calendarDay = CalendarDay(newValue) }
    }

    static let noteLimit = 150
    static let checklistLimit = 10

    var completedCount: Int { checklist.count(where: \.isDone) }

    func noticeDate(calendar: Calendar) -> Date? {
        guard let days = advanceNotice.daysBefore else { return nil }
        guard let noticeDay = calendar.date(byAdding: .day, value: -days, to: calendarDay.date(in: calendar)) else { return nil }
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: noticeDay)
    }
}
