import Foundation
import UserNotifications

actor NotificationScheduler {
    private let center = UNUserNotificationCenter.current()
    private let identifierPrefix = "countdown."
    private let capacity = 60

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func sync(_ schedule: NotificationSchedule, requestPermission: Bool) async throws -> Bool? {
        let pending = await center.pendingNotificationRequests()
        let owned = pending.filter { $0.identifier.hasPrefix(identifierPrefix) }
        guard schedule.isEnabled else {
            center.removePendingNotificationRequests(withIdentifiers: owned.map(\.identifier))
            return nil
        }

        var status = await authorizationStatus()
        if status == .notDetermined, requestPermission {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            status = await authorizationStatus()
        }
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            center.removePendingNotificationRequests(withIdentifiers: owned.map(\.identifier))
            return status == .denied ? false : nil
        }

        let scheduled = requests(for: schedule, at: .now, calendar: CalendarDay.calendar)
        let desired = Set(scheduled.map(\.identifier))
        let previous = Dictionary(uniqueKeysWithValues: owned.map { ($0.identifier, $0.content) })
        center.removePendingNotificationRequests(withIdentifiers: owned.map(\.identifier).filter { !desired.contains($0) })
        for request in scheduled {
            let content = previous[request.identifier]
            if content?.title != request.content.title || content?.body != request.content.body
                || content?.categoryIdentifier != request.content.categoryIdentifier {
                try await center.add(request)
            }
        }
        return true
    }

    private func requests(for schedule: NotificationSchedule, at now: Date, calendar: Calendar) -> [UNNotificationRequest] {
        let sound = schedule.sound == .soft
        var dated: [DatedRequest] = []
        var intervals: [Reminder] = []

        for plan in schedule.plans where plan.date > now {
            let offset = AppDate.dayOffset(to: plan.eventDay, from: plan.date, calendar: calendar)
            let date = AppDate.short(plan.eventDay)
            let body = (0...1).contains(offset) ? "\(AppDate.relative(offset)), \(date)" : date
            dated.append(.init(date: plan.date, id: "plan.\(plan.id)", title: plan.title, body: body))
        }
        if let focus = schedule.focus, focus.isRunning(at: now) {
            dated.append(.init(date: focus.endsAt, id: "focus.\(focus.planID)", title: String(localized: "Time’s up"), body: focus.planTitle))
        }

        for reminder in schedule.reminders {
            let id = "reminder.\(reminder.id)"
            if let snooze = reminder.snoozedUntil, snooze > now {
                dated.append(.init(date: snooze, id: id, title: reminder.title, body: String(localized: "Snoozed reminder")))
            }
            switch reminder.rule {
            case let .once(date):
                if reminder.handledThrough == nil, reminder.snoozedUntil == nil, date > now {
                    dated.append(.init(date: date, id: id, title: reminder.title, body: String(localized: "Reminder")))
                }
            case .interval:
                intervals.append(reminder)
            }
        }

        let datedRequests = dated.sorted(by: byDate).prefix(capacity).map {
            makeDatedRequest($0, sound: sound, calendar: calendar)
        }
        let available = capacity - datedRequests.count
        guard available > 0, !intervals.isEmpty else { return datedRequests }

        let intervalSlots = intervals.map { (reminder: $0, times: $0.rule.repeatingTimes) }
        guard intervalSlots.reduce(0, { $0 + $1.times.count }) <= available else {
            // Fit the closest interval occurrences into the remaining iOS slots.
            // The app re-fills this window whenever it becomes active.
            let upcoming = intervals.flatMap { reminder in
                reminder.rule.occurrences(after: cutoff(for: reminder, now: now), limit: available, calendar: calendar)
                    .map { DatedRequest(date: $0, id: "reminder.\(reminder.id)", title: reminder.title, body: reminder.rule.notificationSummary) }
            }
            return datedRequests + upcoming.sorted(by: byDate).prefix(available).map {
                makeDatedRequest($0, sound: sound, calendar: calendar)
            }
        }

        let intervalRequests = intervalSlots.flatMap { reminder, times in
            times.compactMap { time -> UNNotificationRequest? in
                let id = "reminder.\(reminder.id)"
                let skipThrough = cutoff(for: reminder, now: now)
                let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
                guard let next = trigger.nextTriggerDate() else { return nil }
                guard next > skipThrough else {
                    // Completing or snoozing one occurrence should not disable the other
                    // weekly slots. Schedule the next eligible occurrence for this slot.
                    guard let date = calendar.nextDate(after: skipThrough, matching: time, matchingPolicy: .strict)
                    else { return nil }
                    return makeDatedRequest(.init(date: date, id: id, title: reminder.title, body: reminder.rule.notificationSummary),
                                            sound: sound, calendar: calendar)
                }
                let slot = "\(time.weekday ?? 0).\(time.hour ?? 0).\(time.minute ?? 0)"
                return makeRequest(id: "\(id).weekly.\(slot)", title: reminder.title, body: reminder.rule.notificationSummary,
                                   sound: sound, trigger: trigger)
            }
        }
        return datedRequests + intervalRequests
    }

    private func cutoff(for reminder: Reminder, now: Date) -> Date {
        max(now, reminder.handledThrough ?? .distantPast, reminder.snoozedUntil ?? .distantPast)
    }

    private func byDate(_ first: DatedRequest, _ second: DatedRequest) -> Bool {
        first.date == second.date ? first.id < second.id : first.date < second.date
    }

    private func makeDatedRequest(_ item: DatedRequest, sound: Bool, calendar: Calendar) -> UNNotificationRequest {
        let seconds = ceil(item.date.timeIntervalSince1970)
        let date = Date(timeIntervalSince1970: seconds)
        var time = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        time.timeZone = calendar.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: false)
        return makeRequest(id: "\(item.id).\(Int(seconds)).\(calendar.timeZone.identifier)",
                           title: item.title, body: item.body, sound: sound, trigger: trigger)
    }

    private func makeRequest(id: String, title: String, body: String, sound: Bool,
                             trigger: UNCalendarNotificationTrigger) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if id.hasPrefix("reminder.") { content.categoryIdentifier = NotificationInteraction.reminderCategory }
        content.sound = sound ? UNNotificationSound(named: UNNotificationSoundName("TimerFinished.caf")) : nil
        return UNNotificationRequest(identifier: "\(identifierPrefix)\(id).\(sound)", content: content, trigger: trigger)
    }

    private struct DatedRequest {
        let date: Date
        let id: String
        let title: String
        let body: String
    }
}
