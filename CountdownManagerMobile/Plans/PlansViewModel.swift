import Foundation

struct PlansViewModel {
    let favorite: Plan?
    let otherPlans: [Plan]

    var isEmpty: Bool { favorite == nil && otherPlans.isEmpty }

    init(plans: [Plan], today: Date, calendar: Calendar) {
        let startOfToday = calendar.startOfDay(for: today)
        let sorted = plans.sorted { first, second in
            let firstDay = first.day
            let secondDay = second.day
            let firstIsPast = firstDay < startOfToday
            let secondIsPast = secondDay < startOfToday
            if firstIsPast != secondIsPast { return !firstIsPast }
            if firstDay != secondDay { return firstIsPast ? firstDay > secondDay : firstDay < secondDay }
            return first.title.localizedStandardCompare(second.title) == .orderedAscending
        }
        favorite = sorted.first(where: \.isFavorite)
        otherPlans = sorted.filter { !$0.isFavorite }
    }
}
