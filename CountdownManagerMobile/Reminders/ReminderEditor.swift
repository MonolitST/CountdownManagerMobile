import SwiftUI

struct ReminderEditor: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ReminderDraft
    @State private var showsDate = false
    @State private var confirmsDeletion = false
    private let original: Reminder?
    private let tablet: Bool

    init(reminder: Reminder? = nil, tablet: Bool = false) {
        original = reminder
        self.tablet = tablet
        _draft = State(initialValue: ReminderDraft(reminder: reminder))
    }

    var body: some View {
        ScreenScroll(topPadding: tablet ? 20 : 3, contentWidth: tablet ? 380 : 530,
                     horizontalPadding: tablet ? 20 : 23) {
            VStack(alignment: .leading, spacing: 16) {
                if !tablet { EditorCloseButton() }
                Text(original == nil ? String(localized: "New reminder") : String(localized: "Edit reminder"))
                    .displayFont(28)
                    .accessibilityAddTraits(.isHeader)
                FieldLabel(title: String(localized: "What to remember")) {
                    TextField(String(localized: "What to remember"), text: $draft.title, prompt: Text(String(localized: "E.g. Time to stretch")))
                        .textInputAutocapitalization(.sentences)
                        .brandFont(16)
                        .padding(12)
                        .frame(minHeight: 50)
                        .fieldSurface()
                        .accessibilityIdentifier("reminder.title")
                }
                FieldLabel(title: String(localized: "When")) {
                    HStack(spacing: 10) {
                        ForEach(ReminderDraft.Mode.allCases) { mode in
                            Button(mode.title) { draft.mode = mode }
                                .buttonStyle(OptionButtonStyle(selected: draft.mode == mode, showsOutlineWhenUnselected: false))
                                .card(Palette.surface, cornerRadius: 11)
                                .accessibilityAddTraits(draft.mode == mode ? .isSelected : [])
                        }
                    }
                }
                if draft.mode == .interval {
                    ReminderIntervalFields(draft: $draft)
                } else {
                    Button {
                        showsDate = true
                    } label: {
                        Text("\(AppDate.full(draft.time)) · \(AppDate.clock(draft.time))")
                            .brandFont(16)
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                            .card(cornerRadius: 12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Date and time"))
                    .accessibilityValue("\(AppDate.full(draft.time)) · \(AppDate.clock(draft.time))")
                }
                if let message = draft.validationMessage(at: .now, original: original) {
                    Text(message).brandFont(13, relativeTo: .footnote)
                        .foregroundStyle(Palette.accentText)
                }
                Toggle(isOn: $draft.notifies) {
                    Label {
                        Text(String(localized: "Sound and notification")).brandFont(15, relativeTo: .subheadline)
                    } icon: { DesignIcon(.volume) }
                }
                .toggleStyle(BrandToggleStyle())
                if original != nil {
                    Button(String(localized: "Delete reminder"), role: .destructive) { confirmsDeletion = true }
                        .foregroundStyle(Palette.accentText)
                        .frame(minHeight: 44)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .foregroundStyle(Palette.text)
        .tint(Palette.accentText)
        .preferredColorScheme(store.data.settings.appearance.colorScheme)
        .sheet(isPresented: $showsDate) {
            DateSelectionSheet(value: $draft.time, title: String(localized: "Date and time"),
                               range: min(draft.time, .now)..., components: [.date, .hourAndMinute])
        }
        .sheet(isPresented: $confirmsDeletion) {
            ConceptConfirmationSheet(title: String(localized: "Delete this reminder?"),
                                     actionTitle: String(localized: "Delete"), destructive: true) {
                if let original, store.deleteReminder(original.id) { dismiss() }
            }
        }
    }

    private var saveTitle: String {
        original == nil ? String(localized: "Create reminder") : String(localized: "Save reminder")
    }

    private var invalid: Bool {
        draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || draft.validationMessage(at: .now, original: original) != nil
    }

    @ViewBuilder
    private var footer: some View {
        if tablet {
            HStack(spacing: 14) {
                Button("Cancel", role: .cancel) { dismiss() }
                    .brandFont(14, weight: .semibold, relativeTo: .subheadline)
                    .foregroundStyle(Palette.accentText)
                    .frame(minHeight: 44)
                Spacer(minLength: 0)
                Button(saveTitle, action: save)
                    .buttonStyle(BrandButtonStyle(compact: true))
                    .frame(maxWidth: 218)
                    .disabled(invalid)
            }
            .frame(maxWidth: 380)
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(Palette.background)
        } else {
            FormFooter(title: saveTitle, disabled: invalid, action: save)
        }
    }

    private func save() {
        guard draft.validationMessage(at: .now, original: original) == nil else { return }
        if store.save(draft.reminder(updatedFrom: original)) { dismiss() }
    }
}
