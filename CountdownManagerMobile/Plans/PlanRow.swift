import SwiftUI

struct PlanRow: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(\.calendar) private var calendar
    let plan: Plan
    let today: Date
    let onOpen: () -> Void

    var body: some View {
        let offset = AppDate.dayOffset(to: plan.day, from: today, calendar: calendar)
        Button(action: onOpen) {
            HStack(spacing: 13) {
                CalendarLeaf(date: plan.day, size: .compact)
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title).brandFont(14, weight: .semibold, relativeTo: .subheadline)
                    Text("\(AppDate.short(plan.day)) · \(AppDate.relative(offset))")
                        .brandFont(11, relativeTo: .caption2)
                        .foregroundStyle(offset == 0 ? Palette.success : Palette.secondary)
                }
                Spacer(minLength: 0)
                DesignIcon(.chevron).foregroundStyle(Palette.secondary)
                    .padding(.trailing, 12)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(cornerRadius: 12)
            .contentShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(String(localized: "Make favorite"), systemImage: "star") { store.toggleFavorite(plan) }
        }
    }
}
