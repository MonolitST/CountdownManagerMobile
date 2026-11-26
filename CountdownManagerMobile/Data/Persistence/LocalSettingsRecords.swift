import Foundation
import GRDB

struct SettingsRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "settings"

    let id: Int
    let appearance: String
    let showsWeather: Bool
    let cityID: Int?
    let cityName: String?
    let cityLatitude: Double?
    let cityLongitude: Double?
    let cityAdmin1: String?
    let cityCountry: String?
    let weatherLocationMode: String?
    let notificationsEnabled: Bool
    let notificationSound: String
    let focusMinutes: Int

    init(_ settings: Settings) {
        id = 1
        appearance = settings.appearance.rawValue
        showsWeather = settings.showsWeather
        cityID = settings.city?.id
        cityName = settings.city?.name
        cityLatitude = settings.city?.latitude
        cityLongitude = settings.city?.longitude
        cityAdmin1 = settings.city?.admin1
        cityCountry = settings.city?.country
        weatherLocationMode = settings.weatherLocationMode?.rawValue
        notificationsEnabled = settings.notificationsEnabled
        notificationSound = settings.notificationSound.rawValue
        focusMinutes = settings.focusMinutes
    }

    func settings() throws -> Settings {
        let locationMode = weatherLocationMode.flatMap(WeatherLocationMode.init(rawValue:))
        guard let appearance = AppearancePreference(rawValue: appearance),
              let sound = NotificationSound(rawValue: notificationSound),
              weatherLocationMode == locationMode?.rawValue else {
            throw PlannerStorageError.invalidSettings
        }

        var city: WeatherCity?
        if let cityID, let cityName, let cityLatitude, let cityLongitude {
            city = WeatherCity(id: cityID, name: cityName, latitude: cityLatitude, longitude: cityLongitude,
                               admin1: cityAdmin1, country: cityCountry)
        }
        return Settings(appearance: appearance, showsWeather: showsWeather, city: city, weatherLocationMode: locationMode,
                        notificationsEnabled: notificationsEnabled, notificationSound: sound, focusMinutes: focusMinutes)
    }
}

struct FocusSessionRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "focus_session"

    let id: Int
    let planID: UUID
    let planTitle: String
    let minutes: Int
    let endsAt: Double

    init(_ session: FocusSession) {
        id = 1
        planID = session.planID
        planTitle = session.planTitle
        minutes = session.minutes
        endsAt = session.endsAt.timeIntervalSinceReferenceDate
    }

    var session: FocusSession {
        FocusSession(planID: planID, planTitle: planTitle, minutes: minutes,
                     endsAt: Date(timeIntervalSinceReferenceDate: endsAt))
    }
}
