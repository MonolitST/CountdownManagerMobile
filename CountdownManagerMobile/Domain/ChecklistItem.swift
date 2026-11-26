import Foundation

struct ChecklistItem: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    var title = ""
    var isDone = false
}
