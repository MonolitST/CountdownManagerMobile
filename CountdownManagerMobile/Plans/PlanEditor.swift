import SwiftUI

struct PlanEditor: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @State private var draft: Plan
    @State private var attachmentEditor: PlanAttachmentEditorViewModel
    @State private var originalAttachmentIDs: Set<UUID>
    @State private var attachmentChooser: PlanAttachmentTarget?
    @State private var showsDate = false
    @State private var confirmsDeletion = false
    @FocusState private var focusedItem: UUID?
    private let original: Plan?
    private let onFinish: ((UUID?) -> Void)?

    init(plan: Plan? = nil, addingAttachmentTo target: PlanAttachmentTarget? = nil,
         onFinish: ((UUID?) -> Void)? = nil) {
        original = plan
        self.onFinish = onFinish
        _draft = State(initialValue: plan ?? Plan())
        _attachmentEditor = State(initialValue: PlanAttachmentEditorViewModel(attachments: plan?.attachments ?? []))
        _originalAttachmentIDs = State(initialValue: Set(plan?.attachments.map(\.id) ?? []))
        _attachmentChooser = State(initialValue: target)
    }

    var body: some View {
        ScreenScroll(topPadding: tablet ? 18 : 3, contentWidth: tablet ? 680 : 530,
                     horizontalPadding: tablet ? 30 : 23) {
            VStack(alignment: .leading, spacing: sectionSpacing) {
                if tablet {
                    ScreenNavigation(backLabel: String(localized: "Back"), goBack: { finish() })
                } else {
                    EditorCloseButton()
                }
                ScreenHeader(title: original == nil ? String(localized: "New plan") : String(localized: "Edit plan"),
                             titleSize: tablet ? 36 : 31)
                if tablet {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 14) {
                            titleField.frame(minWidth: 205, maxWidth: .infinity)
                            dateField.frame(width: 220)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            titleField
                            dateField
                        }
                    }
                } else {
                    titleField
                    dateField
                }
                VStack(alignment: .leading, spacing: sectionSpacing - 8) {
                    FieldLabel(title: String(localized: "Note · optional")) {
                        TextField(String(localized: "Note"), text: $draft.note,
                                  prompt: Text("A note about this plan").foregroundStyle(Palette.secondary), axis: .vertical)
                            .lineLimit(original == nil ? 3...6 : 2...6)
                            .brandFont(16)
                            .padding(12)
                            .frame(minHeight: original == nil ? 82 : 65, alignment: .topLeading)
                            .fieldSurface()
                        if draft.note.count > noteLimit {
                            Text(String(localized: "\(draft.note.count) of \(noteLimit) characters"))
                                .brandFont(12, relativeTo: .caption)
                                .foregroundStyle(Palette.accentText)
                        }
                    }
                    PlanEditorOptions(draft: $draft, focusedItem: $focusedItem, sectionSpacing: sectionSpacing,
                                      attachmentEditor: attachmentEditor, fileURL: attachmentURL, tablet: tablet) {
                        focusedItem = nil
                        attachmentChooser = $0
                    }
                }
                if original != nil {
                    Button(String(localized: "Delete plan"), role: .destructive) { confirmsDeletion = true }
                        .brandFont(14, weight: .semibold, relativeTo: .subheadline)
                        .foregroundStyle(Palette.accentText)
                        .frame(minHeight: 44, alignment: .leading)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FormFooter(title: String(localized: "Save plan"),
                       disabled: draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || draft.note.count > noteLimit || attachmentEditor.isImporting || hasUntitledAttachmentItem,
                       tablet: tablet, action: save)
        }
        .foregroundStyle(Palette.text)
        .tint(Palette.accentText)
        .preferredColorScheme(store.data.settings.appearance.colorScheme)
        .sheet(isPresented: $showsDate) {
            let today = calendar.startOfDay(for: .now)
            DateSelectionSheet(value: $draft.day, title: String(localized: "Date"), range: min(original?.day ?? today, today)...)
        }
        .sheet(isPresented: $confirmsDeletion) {
            ConceptConfirmationSheet(title: String(localized: "Delete this plan?"),
                                     actionTitle: String(localized: "Delete"), destructive: true) {
                if store.deletePlan(draft.id) { dismiss() }
            }
        }
        .sheet(item: $attachmentChooser) { target in
            let title = target.checklistItemID.map { id in
                guard let item = draft.checklist.first(where: { $0.id == id }) else {
                    return String(localized: "Checklist item")
                }
                let trimmed = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? String(localized: "Checklist item") : trimmed
            }
            PlanAttachmentPickerSheet(checklistTitle: title, tablet: tablet) { result in
                switch result {
                case let .photos(photos): attachmentEditor.addPhotos(photos, to: target)
                case let .files(files): attachmentEditor.addFiles(files, to: target)
                case let .link(url, title): attachmentEditor.addLink(url, title: title, to: target)
                }
            }
        }
        .alert("Attachments", isPresented: Binding(
            get: { attachmentEditor.errorMessage != nil },
            set: { if !$0 { attachmentEditor.errorMessage = nil } }
        )) {
            Button("Close", role: .cancel) {}
        } message: {
            Text(attachmentEditor.errorMessage ?? "")
        }
    }

    private var tablet: Bool { onFinish != nil }

    private var titleField: some View {
        FieldLabel(title: String(localized: "Title")) {
            TextField(String(localized: "Title"), text: $draft.title,
                      prompt: Text("E.g. Trip to Suzdal").foregroundStyle(Palette.secondary))
                .textInputAutocapitalization(.sentences)
                .brandFont(16)
                .padding(12)
                .frame(minHeight: 50)
                .fieldSurface()
                .accessibilityIdentifier("plan.title")
        }
    }

    private var dateField: some View {
        FieldLabel(title: String(localized: "Date")) {
            Button {
                showsDate = true
            } label: {
                Text(AppDate.full(draft.day))
                    .brandFont(16)
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                    .padding(.horizontal, 12)
                    .fieldSurface()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Date"))
            .accessibilityValue(AppDate.full(draft.day))
        }
    }

    private func finish(_ savedID: UUID? = nil) {
        if let onFinish { onFinish(savedID) } else { dismiss() }
    }

    private var noteLimit: Int { max(Plan.noteLimit, original?.note.count ?? 0) }

    private var sectionSpacing: CGFloat {
        if original != nil { return 10 }
        return draft.checklist.isEmpty ? 18 : 14
    }

    private var hasUntitledAttachmentItem: Bool {
        let attachedItems = Set(attachmentEditor.attachments.compactMap(\.checklistItemID))
        return draft.checklist.contains {
            attachedItems.contains($0.id) && $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func attachmentURL(_ attachment: PlanAttachment) -> URL? {
        attachmentEditor.imports[attachment.id] ?? store.fileURL(for: attachment)
    }

    private func save() {
        guard !attachmentEditor.isImporting, !hasUntitledAttachmentItem else { return }
        draft.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        for index in draft.checklist.indices {
            draft.checklist[index].title = draft.checklist[index].title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        draft.checklist.removeAll { $0.title.isEmpty }
        let saved = store.data.plans.first { $0.id == draft.id }
        let newlyShared = saved?.attachments.filter { !originalAttachmentIDs.contains($0.id) } ?? []
        draft.attachments = attachmentEditor.attachments + newlyShared
        draft.day = calendar.startOfDay(for: draft.day)
        if store.save(draft, importing: attachmentEditor.imports) {
            finish(draft.id)
        } else {
            attachmentEditor.errorMessage = store.errorMessage
            store.errorMessage = nil
        }
    }
}
