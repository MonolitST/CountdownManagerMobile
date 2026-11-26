import ActivityKit
import Foundation

@MainActor
final class FocusLiveActivity {
    private var updateTask: Task<Void, Never>?
    private var expirationTask: Task<Void, Never>?

    func sync(_ session: FocusSession?, appearance: AppearancePreference, start: Bool = false) {
        let previousUpdate = updateTask
        expirationTask?.cancel()
        updateTask = Task {
            await previousUpdate?.value
            await Self.updateActivities(for: session, appearance: appearance, start: start)
        }
        guard let session else { return }
        let remaining = session.endsAt.timeIntervalSinceNow
        guard remaining > 0 else { return }
        expirationTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(remaining))
            } catch { return }
            self?.sync(session, appearance: appearance)
        }
    }

    private nonisolated static func updateActivities(for session: FocusSession?, appearance: AppearancePreference,
                                                    start: Bool) async {
        let running = session.flatMap { $0.endsAt > .now ? $0 : nil }
        let activities = Activity<FocusActivityAttributes>.activities
        let current = activities.first {
            $0.attributes.planID == running?.planID && $0.content.state.endsAt == running?.endsAt
        }
        for activity in activities where activity.id != current?.id {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        guard let running, running.endsAt > .now else {
            await current?.end(nil, dismissalPolicy: .immediate)
            return
        }
        let darkAppearance: Bool?
        switch appearance {
        case .system: darkAppearance = nil
        case .light: darkAppearance = false
        case .dark: darkAppearance = true
        }
        let state = FocusActivityAttributes.ContentState(
            planTitle: String(running.planTitle.prefix(150)),
            startsAt: running.endsAt.addingTimeInterval(-Double(running.minutes) * 60),
            endsAt: running.endsAt,
            darkAppearance: darkAppearance,
            languageCode: AppDate.languageCode
        )
        let content = ActivityContent(state: state, staleDate: running.endsAt)
        if let current {
            if current.content.state != state { await current.update(content) }
        } else if start, ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                _ = try Activity.request(attributes: FocusActivityAttributes(planID: running.planID),
                                         content: content, pushType: nil)
            } catch {
                // The timer and its local notification still run when iOS declines the activity.
            }
        }
    }
}
