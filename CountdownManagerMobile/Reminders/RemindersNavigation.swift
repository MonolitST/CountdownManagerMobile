import SwiftUI

struct RemindersNavigation: View {
    @State private var showsNewReminder = false
    @State private var editing: Reminder?
    let today: Date
    let onOpenPlan: (UUID) -> Void

    var body: some View {
        RemindersView(today: today, onAdd: { showsNewReminder = true }, onEdit: { editing = $0 }, onOpenPlan: onOpenPlan)
            .fullScreenCover(isPresented: $showsNewReminder) {
                ReminderEditor()
            }
            .fullScreenCover(item: $editing) { reminder in
                ReminderEditor(reminder: reminder)
            }
    }
}
