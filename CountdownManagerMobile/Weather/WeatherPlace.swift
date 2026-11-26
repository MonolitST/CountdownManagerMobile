import Foundation

struct WeatherPlace: Equatable, Sendable {
    let name: String
    let latitude: Double
    let longitude: Double

    init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }

    init(city: WeatherCity) {
        self.init(name: city.displayName, latitude: city.latitude, longitude: city.longitude)
    }
}
