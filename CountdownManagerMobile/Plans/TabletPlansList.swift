import SwiftUI

struct TabletPlansList: View {
    @Environment(PlannerViewModel.self) private var store
    @State private var planToDelete: Plan?
    let model: PlansViewModel
    let today: Date
    let selectedID: UUID?
    let column: Bool
    let onAdd: () -> Void
    let onSelect: (UUID) -> Void

    var body: some View {
        List {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(title: String(localized: "My plans"), date: nil,
                             addLabel: String(localized: "New plan"), onAdd: onAdd,
                             extendedAction: !column, titleSize: column ? 28 : 36)
                Text(AppDate.heading(today))
                    .brandFont(13, relativeTo: .caption)
                    .foregroundStyle(Palette.secondary)
                if !column { PlannerWeatherTile() }
            }
            .padding(.top, 19)
            .padding(.bottom, 12)
            .tabletListRow(bottom: 4)

            if let favorite = model.favorite {
                heading("Favorite")
                PlanRow(plan: favorite, today: today, onOpen: { onSelect(favorite.id) },
                        tablet: true, selected: selectedID == favorite.id, column: column)
                    .tabletListRow()
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) { deleteButton(favorite) }
            }
            if !model.otherPlans.isEmpty {
                heading(model.favorite == nil ? "Plans" : "Other plans")
                    .padding(.top, 6)
                ForEach(model.otherPlans) { plan in
                    PlanRow(plan: plan, today: today, onOpen: { onSelect(plan.id) },
                            tablet: true, selected: selectedID == plan.id, column: column)
                        .tabletListRow()
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) { deleteButton(plan) }
                }
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .contentMargins(.horizontal, column ? 16 : 22, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: column ? .infinity : 766)
        .frame(maxWidth: .infinity)
        .background((column ? Palette.surface : Palette.background).ignoresSafeArea())
        .sheet(item: $planToDelete) { plan in
            ConceptConfirmationSheet(title: String(localized: "Delete this plan?"),
                                     actionTitle: String(localized: "Delete"), destructive: true) {
                _ = store.deletePlan(plan.id)
            }
        }
    }

    private func heading(_ title: LocalizedStringResource) -> some View {
        Text(title).brandFont(14, weight: .semibold, relativeTo: .subheadline)
            .foregroundStyle(Palette.secondary)
            .accessibilityAddTraits(.isHeader)
            .tabletListRow(bottom: 6)
    }

    private func deleteButton(_ plan: Plan) -> some View {
        Button(String(localized: "Delete"), systemImage: "trash", role: .destructive) { planToDelete = plan }
    }
}

private extension View {
    func tabletListRow(bottom: CGFloat = 8) -> some View {
        listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: bottom, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
