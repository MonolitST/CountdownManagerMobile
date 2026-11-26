import SwiftUI

struct TimeSelectionSheet: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @State private var showsCustomTime = false
    @Binding var minutes: Int
    let title: String
    let presets: [Int]

    private var selection: Binding<Date> {
        Binding(get: {
            let day = calendar.startOfDay(for: .now)
            return calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day) ?? day
        }, set: {
            let parts = calendar.dateComponents([.hour, .minute], from: $0)
            minutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        })
    }

    var body: some View {
        ConceptSheet(title: title, height: showsCustomTime ? 312 : 284, done: showsCustomTime ? { dismiss() } : nil) {
            if showsCustomTime {
                DatePicker(title, selection: selection, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(presets, id: \.self) { preset in
                    ConceptSheetOption(title: AppDate.clock(minutes: preset), selected: minutes == preset) {
                        minutes = preset
                        dismiss()
                    }
                }
                ConceptSheetOption(title: String(localized: "Custom time…")) { showsCustomTime = true }
            }
        }
    }
}
