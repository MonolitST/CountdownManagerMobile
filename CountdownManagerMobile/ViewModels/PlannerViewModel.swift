import Foundation
import Observation

@MainActor
@Observable
final class PlannerViewModel {
    private(set) var data = PlannerData()
    var errorMessage: String?

    @ObservationIgnored let notifications = NotificationViewModel()
    @ObservationIgnored private let liveActivity = FocusLiveActivity()
    @ObservationIgnored private let repository: (any PlannerRepository)?
    @ObservationIgnored private let demo: Bool
    @ObservationIgnored private let demoFiles: PlanAttachmentFileStore?

    init(openRepository: () throws -> any PlannerRepository) {
        demo = ProcessInfo.processInfo.arguments.contains("-demo-content")
        if demo {
            self.repository = nil
            demoFiles = PlanAttachmentFileStore(directory: URL.temporaryDirectory.appending(path: UUID().uuidString))
            data = PlannerData.demo(at: displayNow)
        } else {
            demoFiles = nil
            do {
                let repository = try openRepository()
                let saved = try repository.load()
                self.repository = repository
                data = saved
            } catch {
                self.repository = nil
                errorMessage = String(localized: "Couldn’t read saved data. Your file is still on this device.")
            }
        }
    }

    var displayNow: Date {
        guard demo else { return .now }
        return CalendarDay.calendar.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: 15, minute: 45)) ?? .now
    }

    var usesDemoContent: Bool { demo }

    func save(_ plan: Plan, importing files: [UUID: URL] = [:]) -> Bool {
        var updated = data
        updated.save(plan: plan)
        return commit(updated, requestPermission: plan.noticeDate(calendar: CalendarDay.calendar).map { $0 > .now } ?? false,
                      importing: files)
    }

    func fileURL(for attachment: PlanAttachment) -> URL? {
        repository?.fileURL(for: attachment) ?? demoFiles?.fileURL(for: attachment)
    }

    func refreshAfterSharing() -> UUID? {
        guard let update = try? repository?.consumeSharedUpdate() else { return nil }
        data = update.data
        return update.planID
    }

    func toggleFavorite(_ plan: Plan) {
        var plan = plan
        plan.isFavorite.toggle()
        _ = save(plan)
    }

    func toggleItem(_ itemID: UUID, in planID: UUID) {
        var updated = data
        guard updated.toggleChecklistItem(itemID, in: planID) else { return }
        _ = commit(updated)
    }

    func deletePlan(_ id: UUID) -> Bool {
        var updated = data
        updated.deletePlan(id)
        return commit(updated)
    }

    func save(_ reminder: Reminder) -> Bool {
        var updated = data
        updated.save(reminder: reminder)
        return commit(updated, requestPermission: reminder.notifies)
    }

    func finish(_ reminder: Reminder, occurrence: Date, snoozing: Bool) {
        var updated = data
        guard updated.finishReminder(reminder.id, occurrence: occurrence, now: displayNow,
                                     snoozing: snoozing) else { return }
        _ = commit(updated)
    }

    private func pendingReminder(for interaction: NotificationInteraction) -> Reminder? {
        guard case let .reminder(id) = interaction.destination,
              let reminder = data.reminders.first(where: { $0.id == id }),
              reminder.matchesNotification(at: interaction.date) else { return nil }
        return reminder
    }

    func completeNotification(_ interaction: NotificationInteraction) async {
        guard let reminder = pendingReminder(for: interaction) else { return }
        finish(reminder, occurrence: interaction.date, snoozing: interaction.action == .snooze)
        await notifications.waitForSync()
    }

    func deleteReminder(_ id: UUID) -> Bool {
        var updated = data
        updated.reminders.removeAll { $0.id == id }
        return commit(updated)
    }

    func set<Value>(_ key: WritableKeyPath<Settings, Value>, to value: Value,
                    requestPermission: Bool = false) {
        var updated = data
        updated.settings[keyPath: key] = value
        _ = commit(updated, requestPermission: requestPermission)
    }

    func respondToNotificationIntroduction(allow: Bool) {
        guard notifications.dismissIntroduction() else { return }
        if allow {
            updateNotifications(requestPermission: true, introducesPermission: false)
        } else {
            set(\.notificationsEnabled, to: false)
        }
    }

    func startFocus(for plan: Plan, minutes: Int) {
        var updated = data
        updated.focus = FocusSession(planID: plan.id, planTitle: plan.title, minutes: minutes,
                                     endsAt: .now.addingTimeInterval(Double(minutes * 60)))
        _ = commit(updated, requestPermission: true)
    }

    func clearFocus() {
        var updated = data
        updated.focus = nil
        _ = commit(updated)
    }

    func pauseFocus(for planID: UUID) {
        let now = Date.now
        guard var session = data.focus, session.planID == planID, session.isRunning(at: now) else { return }
        session.pausedSeconds = session.secondsRemaining(at: now)
        var updated = data
        updated.focus = session
        _ = commit(updated)
    }

    func resumeFocus(for planID: UUID) {
        guard let session = data.focus, session.planID == planID, let seconds = session.pausedSeconds else { return }
        var updated = data
        updated.focus = FocusSession(planID: planID, planTitle: session.planTitle, minutes: session.minutes,
                                     endsAt: .now.addingTimeInterval(Double(seconds)))
        _ = commit(updated)
    }

    func restoreFocusLiveActivity() {
        guard demo || repository != nil else { return }
        liveActivity.sync(data.focus, appearance: data.settings.appearance)
    }

    func refreshNotifications(requestPermission: Bool = false) {
        updateNotifications(requestPermission: requestPermission, introducesPermission: true)
    }

    private func updateNotifications(requestPermission: Bool, introducesPermission: Bool) {
        guard !demo, repository != nil else { return }
        notifications.synchronize(NotificationSchedule(data), requestPermission: requestPermission,
                                  introducesPermission: introducesPermission) { [weak self] message in
            self?.errorMessage = message
        }
    }

    func selectWeatherCity(_ city: WeatherCity) -> Bool {
        var updated = data
        updated.settings.city = city
        updated.settings.weatherLocationMode = .manual
        return commit(updated)
    }

    func selectAutomaticWeatherLocation() -> Bool {
        var updated = data
        updated.settings.weatherLocationMode = .automatic
        return commit(updated)
    }

    private func commit(_ updated: PlannerData, requestPermission: Bool = false, importing files: [UUID: URL] = [:]) -> Bool {
        guard demo || repository != nil else {
            errorMessage = String(localized: "Saved data is unavailable. Your changes weren’t saved.")
            return false
        }
        if updated == data {
            if requestPermission { refreshNotifications(requestPermission: true) }
            return true
        }
        do {
            if let repository {
                try repository.save(updated, replacing: data, importing: files)
            } else if let demoFiles {
                _ = try demoFiles.install(updated.attachmentsAdded(since: data), from: files)
                demoFiles.remove(ids: data.attachmentsAdded(since: updated).filter(\.isFile).map(\.id))
            }
            let shouldUpdateNotifications = requestPermission || NotificationSchedule(data) != NotificationSchedule(updated)
            let previousFocus = data.focus
            let shouldUpdateActivity = previousFocus != updated.focus || data.settings.appearance != updated.settings.appearance
            data = updated
            if shouldUpdateActivity {
                liveActivity.sync(updated.focus, appearance: updated.settings.appearance,
                                  start: previousFocus?.endsAt != updated.focus?.endsAt
                                    || previousFocus?.pausedSeconds != updated.focus?.pausedSeconds)
            }
            if shouldUpdateNotifications { refreshNotifications(requestPermission: requestPermission) }
            return true
        } catch {
            errorMessage = String(localized: "Couldn’t save changes. Try again.")
            return false
        }
    }
}
