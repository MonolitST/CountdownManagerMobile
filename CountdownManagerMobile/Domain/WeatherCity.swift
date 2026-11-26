import Foundation

struct WeatherCity: Codable, Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let admin1: String?
    let country: String?

    var displayName: String { id == 524901 ? String(localized: "Moscow") : name }

    var region: String {
        if id == 524901 { return String(localized: "Russia") }
        return [admin1, country].compactMap { $0 }.filter { $0 != name }.joined(separator: ", ")
    }

    static var moscow: Self { Self(id: 524901, name: String(localized: "Moscow"), latitude: 55.7522, longitude: 37.6156,
                             admin1: nil, country: String(localized: "Russia")) }
}
