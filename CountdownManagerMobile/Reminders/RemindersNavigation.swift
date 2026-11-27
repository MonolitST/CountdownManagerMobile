import SwiftUI

struct RemindersNavigation: View {
    @State private var showsNewReminder = false
    @State private var editing: Reminder?
    let today: Date
    let onOpenPlan: (UUID) -> Void
    var tablet = false
    var wide = false

    @ViewBuilder
    var body: some View {
        if tablet {
            reminders
                .sheet(isPresented: $showsNewReminder) { tabletEditor() }
                .sheet(item: $editing) { tabletEditor($0) }
        } else {
            reminders
                .fullScreenCover(isPresented: $showsNewReminder) { ReminderEditor() }
                .fullScreenCover(item: $editing) { ReminderEditor(reminder: $0) }
        }
    }

    private var reminders: some View {
        RemindersView(today: today, onAdd: { showsNewReminder = true }, onEdit: { editing = $0 },
                      onOpenPlan: onOpenPlan, tablet: tablet, wide: wide)
    }

    private func tabletEditor(_ reminder: Reminder? = nil) -> some View {
        ReminderEditor(reminder: reminder, tablet: true)
            .presentationDetents([.height(615), .large])
            .presentationCornerRadius(23)
    }
}
