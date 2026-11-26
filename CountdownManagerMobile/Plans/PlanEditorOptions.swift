import SwiftUI

struct PlanEditorOptions: View {
    @Binding var draft: Plan
    var focusedItem: FocusState<UUID?>.Binding
    let sectionSpacing: CGFloat
    let attachmentEditor: PlanAttachmentEditorViewModel
    let fileURL: (PlanAttachment) -> URL?
    let addAttachment: (PlanAttachmentTarget) -> Void
    @State private var showsNotice = false

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing - (draft.checklist.isEmpty ? 8 : 10)) {
            Toggle(isOn: $draft.isFavorite) {
                HStack(spacing: 10) {
                    DesignIcon(.favoriteLarge).foregroundStyle(Palette.accentText)
                    Text(String(localized: "Add to favorites")).brandFont(15, relativeTo: .subheadline)
                }
            }
            .toggleStyle(BrandToggleStyle(maximumSpacerWidth: 80))

            checklistAndReminder
        }
        .sheet(isPresented: $showsNotice) {
            ConceptSheet(title: String(localized: "Plan reminder"), height: 284) {
                ForEach(AdvanceNotice.allCases) { notice in
                    ConceptSheetOption(title: notice.title, selected: draft.advanceNotice == notice) {
                        draft.advanceNotice = notice
                        showsNotice = false
                    }
                }
            }
        }
    }

    private var checklistAndReminder: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach($draft.checklist) { $item in
                let attachments = attachmentEditor.attachments.filter { $0.checklistItemID == item.id }
                HStack(spacing: 9) {
                    TextField(String(localized: "Checklist item"), text: $item.title,
                              prompt: Text("Checklist item").foregroundStyle(Palette.secondary))
                        .brandFont(14, relativeTo: .subheadline)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 40)
                        .card(cornerRadius: 10)
                        .focused(focusedItem, equals: item.id)
                        .accessibilityIdentifier("plan.checklist.title")
                    ChecklistAttachmentButton(count: attachments.count, itemTitle: item.title) {
                        addAttachment(.checklistItem(item.id))
                    }
                    .disabled(attachmentEditor.isImporting)
                    Button(role: .destructive) {
                        attachmentEditor.removeAttachments(for: item.id)
                        draft.checklist.removeAll { $0.id == item.id }
                    } label: {
                        DesignIcon(.checklistRemove).foregroundStyle(Palette.accentText)
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Delete checklist item"))
                    .disabled(attachmentEditor.isImporting)
                }
                if !attachments.isEmpty {
                    if item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Enter a checklist item title to save its attachments.")
                            .brandFont(12, relativeTo: .caption)
                            .foregroundStyle(Palette.secondary)
                    }
                    attachmentList(attachments)
                }
            }
            if draft.checklist.count < Plan.checklistLimit {
                Button(action: addItem) {
                    Label {
                        Text(String(localized: "Add checklist item")).brandFont(15, weight: .semibold, relativeTo: .subheadline)
                    } icon: { DesignIcon(.addSmall) }
                    .foregroundStyle(Palette.accentText)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .card(Palette.inset, cornerRadius: 12)
                    .contentShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                let planAttachments = attachmentEditor.attachments.filter { $0.checklistItemID == nil }
                if !planAttachments.isEmpty { attachmentList(planAttachments) }
                PlanAttachmentAddButton { addAttachment(.plan) }
                    .disabled(attachmentEditor.isImporting)
                if attachmentEditor.isImporting {
                    ProgressView("Importing attachments…")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
            }
            .padding(.vertical, 4)

            Button {
                showsNotice = true
            } label: {
                HStack(spacing: 8) {
                    DesignIcon(.bell)
                    Text(draft.advanceNotice.title).brandFont(14, relativeTo: .subheadline)
                    DesignIcon(.chevron)
                }
                .foregroundStyle(Palette.secondary)
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Plan reminder"))
            .accessibilityValue(draft.advanceNotice.title)
        }
    }

    private func attachmentList(_ attachments: [PlanAttachment]) -> some View {
        PlanAttachmentList(attachments: attachments, fileURL: fileURL, onRemove: attachmentEditor.remove)
    }

    private func addItem() {
        let item = ChecklistItem()
        draft.checklist.append(item)
        focusedItem.wrappedValue = item.id
    }
}
