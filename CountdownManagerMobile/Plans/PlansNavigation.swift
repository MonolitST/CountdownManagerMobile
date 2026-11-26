import SwiftUI

struct PlansNavigation: View {
    @Environment(PlannerViewModel.self) private var store
    let today: Date
    @Binding var path: [UUID]
    @Binding var showsNewPlan: Bool
    let onOpenTimer: (Plan) -> Void

    var body: some View {
        NavigationStack(path: $path) {
            PlansView(today: today, onAdd: { showsNewPlan = true }, onOpenPlan: { path.append($0) })
                .navigationDestination(for: UUID.self) { id in
                    if let plan = store.data.plans.first(where: { $0.id == id }) {
                        PlanDetailsView(plan: plan, today: today, onOpenTimer: { onOpenTimer(plan) })
                    } else {
                        ContentUnavailableView(String(localized: "Plan deleted"), systemImage: "calendar")
                    }
                }
                .toolbarVisibility(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showsNewPlan) {
            PlanEditor()
        }
        .onChange(of: store.data.plans.map(\.id)) { _, ids in
            path.removeAll { !ids.contains($0) }
        }
    }
}
