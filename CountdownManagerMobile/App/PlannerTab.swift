import SwiftUI

enum PlannerTab: Hashable, CaseIterable, Identifiable {
    case plans, reminders, settings

    var id: Self { self }

    var title: String {
        switch self {
        case .plans: String(localized: "Plans")
        case .reminders: String(localized: "Reminders")
        case .settings: String(localized: "Settings")
        }
    }

    var icon: ImageResource {
        switch self {
        case .plans: .tabCalendar
        case .reminders: .tabBell
        case .settings: .tabSettings
        }
    }
}
