import SwiftUI

struct NotificationIntroduction: ViewModifier {
    @Environment(PlannerViewModel.self) private var store
    @Environment(NotificationPresentation.self) private var presentation
    var onFocusTimer = false

    func body(content: Content) -> some View {
        content
            .onAppear { if onFocusTimer { presentation.isFocusTimerPresented = true } }
            .onDisappear { if onFocusTimer { presentation.isFocusTimerPresented = false } }
            .sheet(isPresented: Binding(
                get: { store.notifications.showsIntroduction && presentation.isFocusTimerPresented == onFocusTimer },
                set: { if !$0 { store.respondToNotificationIntroduction(allow: false) } }
            )) {
                ConceptConfirmationSheet(title: String(localized: "Allow notifications?"),
                                         message: String(localized: "Countdown Manager can send reminders, alerts for upcoming events, and timer alerts."),
                                         actionTitle: String(localized: "Allow"), cancelTitle: String(localized: "Don’t Allow"),
                                         cancel: { store.respondToNotificationIntroduction(allow: false) }) {
                    store.respondToNotificationIntroduction(allow: true)
                }
            }
    }
}
