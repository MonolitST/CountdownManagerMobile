struct Settings: Codable, Equatable, Sendable {
    var appearance: AppearancePreference = .system
    var showsWeather = true
    var city: WeatherCity?
    var weatherLocationMode: WeatherLocationMode?
    var notificationsEnabled = true
    var notificationSound: NotificationSound = .soft
    var focusMinutes = 25

    var weatherMode: WeatherLocationMode {
        weatherLocationMode ?? (city == nil ? .automatic : .manual)
    }

    static let focusDurations = [5, 15, 25, 50]
}
