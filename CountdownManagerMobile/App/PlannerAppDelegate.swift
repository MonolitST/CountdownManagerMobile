import UIKit
import UserNotifications
import Observation

@MainActor
@Observable
final class NotificationPresentation {
    var pending: NotificationInteraction?
    var isFocusTimerPresented = false
}

final class PlannerAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let store = PlannerViewModel(openRepository: SQLitePlannerRepository.local)
    let notificationPresentation = NotificationPresentation()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let actions: [UNNotificationAction] = [
            .init(identifier: NotificationInteraction.Action.done.identifier, title: String(localized: "Done")),
            .init(identifier: NotificationInteraction.Action.snooze.identifier, title: String(localized: "Snooze 10 min")),
            .init(identifier: NotificationInteraction.Action.openReminders.identifier,
                  title: String(localized: "Open Reminders"), options: [.foreground])
        ]
        center.setNotificationCategories([.init(identifier: NotificationInteraction.reminderCategory,
                                                actions: actions, intentIdentifiers: [])])
        return true
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completion: @escaping @Sendable () -> Void) {
        let interaction = Self.notificationInteraction(for: response)
        Task { @MainActor in
            // UIKit restores the scene as part of completing a notification response.
            defer { completion() }
            if let interaction { await handle(interaction) }
        }
    }

    private nonisolated static func notificationInteraction(for response: UNNotificationResponse) -> NotificationInteraction? {
        let request = response.notification.request
        guard let destination = NotificationDestination(identifier: request.identifier) else { return nil }
        let action: NotificationInteraction.Action
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier: action = .open
        case NotificationInteraction.Action.openReminders.identifier: action = .openReminders
        case NotificationInteraction.Action.done.identifier: action = .done
        case NotificationInteraction.Action.snooze.identifier: action = .snooze
        default: return nil
        }
        let trigger = request.trigger as? UNCalendarNotificationTrigger
        let scheduledDate = trigger.flatMap { $0.repeats ? nil : CalendarDay.calendar.date(from: $0.dateComponents) }
        return NotificationInteraction(destination: destination, date: scheduledDate ?? response.notification.date, action: action)
    }

    private func handle(_ interaction: NotificationInteraction) async {
        switch interaction.action {
        case .done, .snooze: await store.completeNotification(interaction)
        case .open, .openReminders: notificationPresentation.pending = interaction
        }
    }
}
