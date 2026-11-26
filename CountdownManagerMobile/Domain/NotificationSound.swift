import Foundation

enum NotificationSound: String, Codable, CaseIterable, Identifiable, Sendable {
    case soft, silent

    var id: Self { self }
    var title: String { self == .soft ? String(localized: "Soft chime") : String(localized: "Silent") }
}
