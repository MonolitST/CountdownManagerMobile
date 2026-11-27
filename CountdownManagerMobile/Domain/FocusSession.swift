import Foundation

struct FocusSession: Codable, Equatable, Sendable {
    let planID: UUID
    let planTitle: String
    let minutes: Int
    let endsAt: Date
    var pausedSeconds: Int? = nil

    func isRunning(at date: Date) -> Bool {
        pausedSeconds == nil && endsAt > date
    }

    func secondsRemaining(at date: Date) -> Int {
        pausedSeconds ?? max(0, Int(ceil(endsAt.timeIntervalSince(date))))
    }
}
