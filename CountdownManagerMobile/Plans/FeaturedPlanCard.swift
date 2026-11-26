import SwiftUI

struct FeaturedPlanCard: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(\.calendar) private var calendar
    let plan: Plan
    let today: Date
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "Favorite plan"))
                    .brandFont(12, relativeTo: .caption)
                    .foregroundStyle(Palette.secondary)
                Spacer()
                Button {
                    store.toggleFavorite(plan)
                } label: {
                    DesignIcon(.favorite)
                        .foregroundStyle(Palette.accentText)
                        .frame(width: 44, height: 28)
                        .contentShape(Rectangle().inset(by: -8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Remove from favorites"))
            }
            Button(action: onOpen) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(plan.title).displayFont(24, relativeTo: .title2)
                        Text(AppDate.full(plan.day))
                            .brandFont(12, relativeTo: .caption)
                            .foregroundStyle(Palette.secondary)
                        Text(AppDate.relative(AppDate.dayOffset(to: plan.day, from: today, calendar: calendar)))
                            .displayFont(23, relativeTo: .title3)
                            .foregroundStyle(Palette.accentText)
                        if !plan.note.isEmpty {
                            Text(plan.note)
                                .brandFont(13, relativeTo: .footnote)
                        }
                    }
                    Spacer(minLength: 8)
                    CalendarLeaf(date: plan.day).rotationEffect(.degrees(3))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            ForEach(plan.checklist.prefix(2)) { item in
                ChecklistRow(item: item, minHeight: 34) {
                    store.toggleItem(item.id, in: plan.id)
                }
            }
        }
        .padding(16)
        .card()
        .accessibilityIdentifier("plans.favorite")
    }
}
