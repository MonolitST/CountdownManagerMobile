import ActivityKit
import Foundation

struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let planTitle: String
        let startsAt: Date
        let endsAt: Date
        let darkAppearance: Bool?
        let languageCode: String?

        var locale: Locale {
            languageCode.map(Locale.init(identifier:)) ?? .autoupdatingCurrent
        }
    }

    let planID: UUID

    var timerURL: URL? {
        URL(string: "countdownmanager://focus/\(planID.uuidString)")
    }

    static func planID(from url: URL) -> UUID? {
        guard url.scheme == "countdownmanager", url.host == "focus",
              url.pathComponents.count == 2 else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}
