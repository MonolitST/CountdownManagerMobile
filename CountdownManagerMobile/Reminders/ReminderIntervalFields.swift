import SwiftUI

struct ReminderIntervalFields: View {
    @Binding var draft: ReminderDraft
    @State private var editingTime: TimeBoundary?
    @State private var showsInterval = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum TimeBoundary: String, Identifiable {
        case start, end
        var id: Self { self }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Every")).brandFont(14, relativeTo: .subheadline)
                    .foregroundStyle(Palette.secondary)
                Spacer()
                Button {
                    showsInterval = true
                } label: {
                    HStack(spacing: 8) {
                        Text(draft.minutes, format: .number.grouping(.never))
                            .displayFont(30, relativeTo: .title2)
                        Text(String(localized: "minutes")).brandFont(14, relativeTo: .subheadline)
                            .foregroundStyle(Palette.secondary)
                    }
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Reminder interval"))
                .accessibilityValue(String(localized: "\(draft.minutes) min"))
            }
            FieldLabel(title: String(localized: "Repeat on")) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 68 : 44),
                                              spacing: 4)], spacing: 5) {
                    ForEach(Weekday.allCases) { day in
                        Button(day.abbreviation) { toggle(day) }
                            .buttonStyle(OptionButtonStyle(selected: draft.weekdays.contains(day), showsOutlineWhenUnselected: false))
                            .accessibilityLabel(day.title)
                            .accessibilityAddTraits(draft.weekdays.contains(day) ? .isSelected : [])
                    }
                }
            }
            FieldLabel(title: String(localized: "Active hours")) {
                HStack(spacing: 10) {
                    timeButton(.start, time: draft.startsAt, label: String(localized: "Start time"))
                    timeButton(.end, time: draft.endsAt, label: String(localized: "End time"))
                }
            }
        }
        .sheet(item: $editingTime) { boundary in
            TimeSelectionSheet(minutes: boundary == .start ? $draft.startsAt : $draft.endsAt,
                               title: boundary == .start ? String(localized: "Start time") : String(localized: "End time"),
                               presets: boundary == .start ? [480, 540, 600] : [1020, 1140, 1260])
        }
        .sheet(isPresented: $showsInterval) {
            ReminderIntervalSheet(minutes: $draft.minutes)
        }
    }

    private func timeButton(_ boundary: TimeBoundary, time: Int, label: String) -> some View {
        Button {
            editingTime = boundary
        } label: {
            Text(AppDate.clock(minutes: time))
                .brandFont(15, weight: .semibold, relativeTo: .subheadline)
                .frame(maxWidth: .infinity, minHeight: 44)
                .fieldSurface()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(AppDate.clock(minutes: time))
    }

    private func toggle(_ day: Weekday) {
        if draft.weekdays.contains(day) {
            draft.weekdays.remove(day)
        } else {
            draft.weekdays.insert(day)
        }
    }
}

private struct ReminderIntervalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var minutes: Int
    @State private var isCustom = false
    @State private var customMinutes: Int?

    var body: some View {
        ConceptSheet(title: String(localized: "Reminder interval"), height: isCustom ? 220 : 332) {
            if isCustom {
                TextField(String(localized: "Minutes between reminders"), value: $customMinutes, format: .number.grouping(.never))
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .fieldSurface()
                if let customMinutes, !(1...720).contains(customMinutes) {
                    Text("Enter an interval from 1 to 720 minutes.")
                        .brandFont(13, relativeTo: .footnote)
                        .foregroundStyle(Palette.accentText)
                }
                Button(String(localized: "Done")) {
                    if let customMinutes { select(customMinutes) }
                }
                .buttonStyle(BrandButtonStyle(compact: true))
                .disabled(customMinutes.map { !(1...720).contains($0) } ?? true)
            } else {
                ForEach([15, 30, 60, 120], id: \.self) { preset in
                    ConceptSheetOption(title: String(localized: "\(preset) min"), selected: minutes == preset) {
                        select(preset)
                    }
                }
                ConceptSheetOption(title: String(localized: "Custom interval…")) {
                    customMinutes = minutes
                    isCustom = true
                }
            }
        }
    }

    private func select(_ interval: Int) {
        minutes = interval
        dismiss()
    }
}
