import SwiftUI

struct PlanDetailsView: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsEditor = false
    @State private var editorAttachmentTarget: PlanAttachmentTarget?
    let plan: Plan
    let today: Date
    let onOpenTimer: () -> Void

    var body: some View {
        ScreenScroll(topPadding: 3) {
            VStack(alignment: .leading, spacing: 16) {
                ScreenNavigation(backLabel: String(localized: "Plans"), goBack: { dismiss() }) {
                    Button {
                        openEditor()
                    } label: {
                        DesignIcon(.edit)
                            .foregroundStyle(Palette.accentText)
                            .frame(width: 44, height: 44)
                            .contentShape(.circle)
                    }
                    .buttonStyle(.plain)
                    .conceptGlass(in: Circle(), interactive: true)
                    .accessibilityLabel(String(localized: "Edit plan"))
                }
                VStack(spacing: 7) {
                    CalendarLeaf(date: plan.day, size: .large)
                        .rotationEffect(.degrees(-3))
                        .padding(.bottom, 4)
                    Text(plan.title).displayFont(28)
                        .accessibilityAddTraits(.isHeader)
                    Text(AppDate.full(plan.day))
                        .brandFont(13, relativeTo: .footnote)
                        .foregroundStyle(Palette.secondary)
                    Text(AppDate.relative(AppDate.dayOffset(to: plan.day, from: today, calendar: calendar)))
                        .displayFont(24, relativeTo: .title2)
                        .foregroundStyle(Palette.accentText)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

                if !plan.note.isEmpty {
                    rule
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Note")).brandFont(13, relativeTo: .footnote)
                            .foregroundStyle(Palette.secondary)
                        Text(plan.note).brandFont(15, relativeTo: .subheadline)
                    }
                }

                if !plan.checklist.isEmpty {
                    rule
                    VStack(alignment: .leading, spacing: 1) {
                        HStack {
                            Text(String(localized: "Preparation")).brandFont(13, weight: .semibold, relativeTo: .footnote)
                                .accessibilityAddTraits(.isHeader)
                            Spacer()
                            Text(String(localized: "\(plan.completedCount) of \(plan.checklist.count)"))
                                .brandFont(11, relativeTo: .caption2)
                                .foregroundStyle(Palette.secondary)
                                .contentTransition(.numericText(value: Double(plan.completedCount)))
                                .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: plan.completedCount)
                        }
                        .padding(.bottom, 4)
                        ForEach(plan.checklist) { item in
                            let attachments = plan.attachments.filter { $0.checklistItemID == item.id }
                            HStack(spacing: 6) {
                                ChecklistRow(item: item) { store.toggleItem(item.id, in: plan.id) }
                                ChecklistAttachmentButton(count: attachments.count, itemTitle: item.title) {
                                    openEditor(addingAttachmentTo: .checklistItem(item.id))
                                }
                            }
                            if !attachments.isEmpty {
                                PlanAttachmentList(attachments: attachments, fileURL: store.fileURL)
                                    .padding(.leading, 30)
                                    .padding(.bottom, 5)
                            }
                        }
                    }
                }
                attachmentsSection
                Button(action: onOpenTimer) {
                    HStack(spacing: 10) {
                        DesignIcon(.timer).foregroundStyle(Palette.accentText)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "A little time to get ready")).brandFont(13, weight: .semibold, relativeTo: .footnote)
                            Text(timerCaption).brandFont(11, relativeTo: .caption2)
                                .foregroundStyle(Palette.secondary)
                        }
                        Spacer(minLength: 4)
                        DesignIcon(.eventPlay).foregroundStyle(Palette.accentText)
                    }
                    .padding(13)
                    .frame(minHeight: 66)
                    .card(Palette.inset, cornerRadius: 12)
                    .contentShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("plan.timer")
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showsEditor) {
            PlanEditor(plan: plan, addingAttachmentTo: editorAttachmentTarget)
        }
    }

    private var attachmentsSection: some View {
        let attachments = plan.attachments.filter { $0.checklistItemID == nil }
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Attachments")
                    .brandFont(15, weight: .semibold, relativeTo: .subheadline)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 4)
                if !attachments.isEmpty {
                    PlanAttachmentAddButton(compact: true) { openEditor(addingAttachmentTo: .plan) }
                }
            }
            if attachments.isEmpty {
                PlanAttachmentAddButton { openEditor(addingAttachmentTo: .plan) }
            } else {
                PlanAttachmentList(attachments: attachments, fileURL: store.fileURL)
            }
        }
    }

    private func openEditor(addingAttachmentTo target: PlanAttachmentTarget? = nil) {
        editorAttachmentTarget = target
        showsEditor = true
    }

    private var rule: some View {
        Rectangle().fill(Palette.outline).frame(height: 0.7).accessibilityHidden(true)
    }

    private var timerCaption: String {
        if let session = store.data.focus, session.planID == plan.id, session.endsAt > today {
            return String(localized: "Return to timer")
        }
        return String(localized: "Focus for \(store.data.settings.focusMinutes) min")
    }
}
