import Foundation

struct WeatherForecast: Decodable, Equatable, Sendable {
    let current: Current
    let daily: Daily

    struct Current: Decodable, Equatable, Sendable {
        let temperature2m: Double
        let weatherCode: Int

        private enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
        }

        var condition: String {
            switch weatherCode {
            case 0: String(localized: "clear")
            case 1, 2: String(localized: "partly cloudy")
            case 3: String(localized: "cloudy")
            case 45, 48: String(localized: "fog")
            case 51...57: String(localized: "drizzle")
            case 61...67, 80...82: String(localized: "rain")
            case 71...77, 85, 86: String(localized: "snow")
            case 95...99: String(localized: "thunderstorms")
            default: String(localized: "current conditions")
            }
        }

        var symbol: String {
            switch weatherCode {
            case 0: "sun.max"
            case 3: "cloud"
            case 45, 48: "cloud.fog"
            case 51...67, 80...82: "cloud.rain"
            case 71...77, 85, 86: "cloud.snow"
            case 95...99: "cloud.bolt.rain"
            default: "cloud.sun"
            }
        }
    }

    struct Daily: Decodable, Equatable, Sendable {
        let temperature2mMin: [Double?]
        let temperature2mMax: [Double?]

        private enum CodingKeys: String, CodingKey {
            case temperature2mMin = "temperature_2m_min"
            case temperature2mMax = "temperature_2m_max"
        }
    }

    static let demo = Self(current: .init(temperature2m: 12, weatherCode: 3),
                           daily: .init(temperature2mMin: [7], temperature2mMax: [14]))
}
