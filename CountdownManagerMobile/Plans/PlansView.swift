import SwiftUI

struct PlansView: View {
    @Environment(PlannerViewModel.self) private var store
    @State private var planToDelete: Plan?
    @Environment(\.calendar) private var calendar
    let today: Date
    let onAdd: () -> Void
    let onOpenPlan: (UUID) -> Void

    var body: some View {
        let model = PlansViewModel(plans: store.data.plans, today: today, calendar: calendar)

        Group {
            if model.isEmpty {
                ScreenScroll(fillsViewport: true) {
                    EmptyListLayout {
                        header
                        EmptyListCard(
                            icon: .emptyCalendar,
                            title: "No plans yet",
                            message: "Add an event\nand a checklist to get ready.",
                            buttonTitle: "Create a plan",
                            onAdd: onAdd
                        )
                    }
                }
            } else {
                planList(favorite: model.favorite, otherPlans: model.otherPlans)
            }
        }
        .sheet(item: $planToDelete) { plan in
            ConceptConfirmationSheet(title: String(localized: "Delete this plan?"),
                                     actionTitle: String(localized: "Delete"), destructive: true) {
                _ = store.deletePlan(plan.id)
            }
        }
    }

    private func planList(favorite: Plan?, otherPlans: [Plan]) -> some View {
        List {
            listRow(spacing: 14) {
                header.padding(.top, 10)
            }
            if let favorite {
                listRow(spacing: 14, plan: favorite) {
                    FeaturedPlanCard(plan: favorite, today: today) { onOpenPlan(favorite.id) }
                }
            }
            if !otherPlans.isEmpty {
                listRow {
                    HStack {
                        Text(favorite == nil ? String(localized: "Plans") : String(localized: "Other plans"))
                            .brandFont(13, weight: .semibold, relativeTo: .footnote)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Text(otherPlans.count, format: .number)
                            .brandFont(12, relativeTo: .caption)
                            .foregroundStyle(Palette.secondary)
                    }
                }
                ForEach(otherPlans) { plan in
                    listRow(plan: plan) {
                        PlanRow(plan: plan, today: today) { onOpenPlan(plan.id) }
                    }
                }
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .contentMargins(.horizontal, 23, for: .scrollContent)
        .contentMargins(.bottom, 10, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: 576)
        .frame(maxWidth: .infinity)
        .background(Palette.background.ignoresSafeArea())
    }

    private func listRow<Content: View>(spacing: CGFloat = 8, plan: Plan? = nil,
                                       @ViewBuilder content: () -> Content) -> some View {
        content()
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: spacing, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if let plan {
                    Button(String(localized: "Delete"), systemImage: "trash") { planToDelete = plan }
                        .tint(Palette.accent)
                }
            }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScreenHeader(title: String(localized: "My plans"), date: today, addLabel: String(localized: "New plan"), onAdd: onAdd)
            PlannerWeatherTile()
        }
    }
}
