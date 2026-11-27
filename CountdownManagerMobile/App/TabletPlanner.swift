import SwiftUI

struct TabletPlanner: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(\.calendar) private var calendar
    @Binding var selection: PlannerTab
    @Binding var path: [UUID]
    @Binding var showsNewPlan: Bool
    @Binding var focusPlan: Plan?
    @State private var editor: Editor?
    let today: Date
    let onOpenPlan: (UUID) -> Void

    private enum Editor: Hashable {
        case new
        case edit(UUID, PlanAttachmentTarget?)
    }

    var body: some View {
        GeometryReader { viewport in
            let wide = viewport.size.width >= 1000 && viewport.size.width > viewport.size.height
            let sidebarWidth = wide ? min(240, viewport.size.width * 0.179) : 0
            let contentWidth = viewport.size.width - sidebarWidth
            let listWidth = wide ? min(350, viewport.size.width * 0.261) : 0
            HStack(spacing: 0) {
                if wide {
                    TabletNavigation(selection: $selection, sidebar: true)
                        .frame(width: sidebarWidth)
                    rule
                }
                VStack(spacing: 0) {
                    if !wide {
                        TabletNavigation(selection: $selection, sidebar: false, showsMark: contentWidth >= 560)
                    }
                    ZStack {
                        plans(wide: wide, columnWidth: listWidth, splitDetail: contentWidth - listWidth >= 555)
                            .tabletTab(isActive: selection == .plans)
                        RemindersNavigation(today: today, onOpenPlan: onOpenPlan, tablet: true, wide: wide)
                            .tabletTab(isActive: selection == .reminders)
                        SettingsView(tablet: true, wide: wide, splitContent: contentWidth >= 580)
                            .tabletTab(isActive: selection == .settings)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: showsNewPlan, initial: true) { _, requested in
            guard requested else { return }
            showsNewPlan = false
            editor = .new
        }
        .onChange(of: path.last) { _, _ in editor = nil }
        .onChange(of: store.data.plans.map(\.id)) { _, ids in
            path.removeAll { !ids.contains($0) }
            if case let .edit(id, _) = editor, !ids.contains(id) { editor = nil }
        }
        .sheet(item: $focusPlan) { plan in
            FocusTimerView(plan: plan, tablet: true)
                .presentationSizing(.fitted)
                .presentationCornerRadius(23)
                .presentationBackground(Palette.surface)
        }
    }

    private func plans(wide: Bool, columnWidth: CGFloat, splitDetail: Bool) -> some View {
        let model = PlansViewModel(plans: store.data.plans, today: today, calendar: calendar)
        let selected = path.last.flatMap { id in store.data.plans.first { $0.id == id } }
            ?? (wide ? model.favorite ?? model.otherPlans.first : nil)
        return HStack(spacing: 0) {
            if wide || (editor == nil && selected == nil && !model.isEmpty) {
                TabletPlansList(model: model, today: today, selectedID: selected?.id, column: wide,
                                onAdd: { editor = .new }, onSelect: selectPlan)
                    .frame(width: wide ? columnWidth : nil)
                if wide { rule }
            }
            if wide || editor != nil || selected != nil || model.isEmpty {
                planDetail(selected, wide: wide, splitContent: splitDetail)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func planDetail(_ selected: Plan?, wide: Bool, splitContent: Bool) -> some View {
        if let editor {
            switch editor {
            case .new:
                PlanEditor(onFinish: finishEditing)
                    .id(editor)
            case let .edit(id, target):
                if let plan = store.data.plans.first(where: { $0.id == id }) {
                    PlanEditor(plan: plan, addingAttachmentTo: target, onFinish: finishEditing)
                        .id(editor)
                }
            }
        } else if let selected {
            PlanDetailsView(plan: selected, today: today, onOpenTimer: { focusPlan = selected },
                            tablet: true, splitContent: splitContent, onBack: wide ? nil : { path.removeAll() },
                            onEdit: { editor = .edit(selected.id, $0) })
                .id(selected.id)
        } else {
            ViewThatFits(in: .vertical) {
                emptyPlans
                    .padding(.bottom, 80)
                ScrollView { emptyPlans.padding(.vertical, 16) }
            }
            .padding(.horizontal, 16)
        }
    }

    private var emptyPlans: some View {
        EmptyListCard(icon: .tabCalendar, iconSize: 25, title: "No plans yet",
                      message: "Add an event and a checklist to get ready.", buttonTitle: "Create a plan",
                      tablet: true, onAdd: { editor = .new })
    }

    private var rule: some View {
        Rectangle().fill(Palette.outline.opacity(0.28)).frame(width: 1).accessibilityHidden(true)
    }

    private func selectPlan(_ id: UUID) {
        editor = nil
        path = [id]
    }

    private func finishEditing(_ savedID: UUID?) {
        editor = nil
        if let savedID { path = [savedID] }
    }
}

private extension View {
    func tabletTab(isActive: Bool) -> some View {
        opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
            .accessibilityHidden(!isActive)
    }
}
