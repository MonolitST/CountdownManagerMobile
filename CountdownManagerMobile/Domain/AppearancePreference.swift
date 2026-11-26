import Foundation

enum AppearancePreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: String(localized: "System")
        case .light: String(localized: "Light")
        case .dark: String(localized: "Dark")
        }
    }
}
