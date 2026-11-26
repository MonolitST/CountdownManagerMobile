import SwiftUI

struct FirstRunView: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(NotificationPresentation.self) private var notificationPresentation
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var hasPlayedSplash = false
    @State private var openedExternalDestination = false
    @State private var showsNewPlan = false
    @State private var pendingFocusPlanID: UUID?

    var body: some View {
        Group {
            if openedExternalDestination || store.usesDemoContent || (hasPlayedSplash && hasCompletedOnboarding) {
                PlannerRoot(showsNewPlan: $showsNewPlan, pendingFocusPlanID: $pendingFocusPlanID)
            } else if hasPlayedSplash {
                OnboardingView(onCreatePlan: {
                    showsNewPlan = true
                    hasCompletedOnboarding = true
                }, onSkip: {
                    hasCompletedOnboarding = true
                })
            } else {
                LaunchSplash { hasPlayedSplash = true }
            }
        }
        .preferredColorScheme(store.data.settings.appearance.colorScheme)
        .onOpenURL { url in
            guard let id = FocusActivityAttributes.planID(from: url),
                  store.data.plans.contains(where: { $0.id == id }) else { return }
            pendingFocusPlanID = id
            openedExternalDestination = true
        }
        .onChange(of: notificationPresentation.pending, initial: true) { _, pending in
            if pending != nil { openedExternalDestination = true }
        }
    }
}
