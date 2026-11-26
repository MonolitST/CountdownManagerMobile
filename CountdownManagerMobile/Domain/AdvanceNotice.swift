import Foundation

enum AdvanceNotice: String, Codable, CaseIterable, Identifiable, Sendable {
    case none, onDay, oneDay, oneWeek

    var id: Self { self }

    var title: String {
        switch self {
        case .none: String(localized: "No reminder")
        case .onDay: String(localized: "Remind me on the day")
        case .oneDay: String(localized: "Remind me one day before")
        case .oneWeek: String(localized: "Remind me one week before")
        }
    }

    var daysBefore: Int? {
        switch self {
        case .none: nil
        case .onDay: 0
        case .oneDay: 1
        case .oneWeek: 7
        }
    }
}
