import Foundation

struct FocusSession: Codable, Equatable, Sendable {
    let planID: UUID
    let planTitle: String
    let minutes: Int
    let endsAt: Date

    func secondsRemaining(at date: Date) -> Int {
        max(0, Int(ceil(endsAt.timeIntervalSince(date))))
    }
}
