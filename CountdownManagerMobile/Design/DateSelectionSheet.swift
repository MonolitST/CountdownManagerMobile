import SwiftUI

struct DateSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @State private var referenceDate = Date.now
    @State private var showsCustomDate = false
    @Binding var value: Date
    let title: String
    let range: PartialRangeFrom<Date>
    var components: DatePickerComponents = .date

    var body: some View {
        if components == .date {
            ConceptSheet(title: title, height: 384, done: { dismiss() }) {
                DatePicker(title, selection: $value, in: range, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            }
        } else {
            ConceptSheet(title: title, height: showsCustomDate ? 312 : 284, done: { dismiss() }) {
                if showsCustomDate {
                    DatePicker(title, selection: $value, in: range, displayedComponents: components)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(presets, id: \.self) { date in
                        ConceptSheetOption(title: "\(AppDate.abbreviated(date)) · \(AppDate.clock(date, calendar: calendar))",
                                           selected: calendar.isDate(date, equalTo: value, toGranularity: .minute)) {
                            value = date
                            dismiss()
                        }
                    }
                    ConceptSheetOption(title: String(localized: "Custom date and time…")) { showsCustomDate = true }
                }
            }
        }
    }

    private var presets: [Date] {
        let startOfHour = calendar.dateInterval(of: .hour, for: referenceDate)?.start ?? referenceDate
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: startOfHour)
        let evening = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: referenceDate)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate)
            .flatMap { calendar.date(bySettingHour: 9, minute: 0, second: 0, of: $0) }
        return Set([nextHour, evening, tomorrow].compactMap { $0 })
            .filter { $0 > referenceDate && range.contains($0) }
            .sorted()
    }
}
