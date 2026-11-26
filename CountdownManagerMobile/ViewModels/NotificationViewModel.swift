import Foundation
import Observation

@MainActor
@Observable
final class NotificationViewModel {
    private(set) var permission: Bool?
    private(set) var showsIntroduction = false

    @ObservationIgnored private let scheduler = NotificationScheduler()
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private var notificationsEnabled = false

    func synchronize(_ schedule: NotificationSchedule, requestPermission: Bool, introducesPermission: Bool,
                     onError: @escaping (String) -> Void) {
        notificationsEnabled = schedule.isEnabled
        let previous = syncTask
        syncTask = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            do {
                if requestPermission, introducesPermission, schedule.isEnabled,
                   await scheduler.authorizationStatus() == .notDetermined {
                    if notificationsEnabled { showsIntroduction = true }
                    permission = nil
                } else {
                    permission = try await scheduler.sync(schedule, requestPermission: requestPermission)
                }
            } catch {
                onError(String(localized: "Couldn’t update notifications. Try again."))
            }
        }
    }

    func dismissIntroduction() -> Bool {
        guard showsIntroduction else { return false }
        showsIntroduction = false
        return true
    }

    func waitForSync() async {
        await syncTask?.value
    }
}
