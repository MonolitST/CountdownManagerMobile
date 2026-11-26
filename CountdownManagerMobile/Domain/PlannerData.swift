import Foundation

struct PlannerData: Codable, Equatable, Sendable {
    var plans: [Plan] = []
    var reminders: [Reminder] = []
    var settings = Settings()
    var focus: FocusSession?

    func attachmentsAdded(since previous: PlannerData) -> [PlanAttachment] {
        let existing = Set(previous.plans.flatMap(\.attachments).map(\.id))
        return plans.flatMap(\.attachments).filter { !existing.contains($0.id) }
    }

    mutating func save(plan: Plan) {
        if plan.isFavorite {
            for index in plans.indices { plans[index].isFavorite = false }
        }
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
        } else {
            plans.append(plan)
        }
        if let focus, focus.planID == plan.id, focus.planTitle != plan.title {
            self.focus = FocusSession(planID: focus.planID, planTitle: plan.title,
                                      minutes: focus.minutes, endsAt: focus.endsAt)
        }
    }

    mutating func toggleChecklistItem(_ itemID: UUID, in planID: UUID) -> Bool {
        guard let planIndex = plans.firstIndex(where: { $0.id == planID }),
              let itemIndex = plans[planIndex].checklist.firstIndex(where: { $0.id == itemID }) else { return false }
        plans[planIndex].checklist[itemIndex].isDone.toggle()
        return true
    }

    mutating func deletePlan(_ id: UUID) {
        plans.removeAll { $0.id == id }
        if focus?.planID == id { focus = nil }
    }

    mutating func save(reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
        } else {
            reminders.append(reminder)
        }
    }

    mutating func finishReminder(_ id: UUID, occurrence: Date, now: Date, snoozing: Bool) -> Bool {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return false }
        if snoozing {
            reminders[index].snooze(occurrence: occurrence, now: now)
        } else if case .once = reminders[index].rule {
            reminders.remove(at: index)
        } else {
            reminders[index].finish(occurrence: occurrence, now: now)
        }
        return true
    }
}
