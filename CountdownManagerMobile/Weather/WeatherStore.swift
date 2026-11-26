import Foundation
import Observation

@MainActor
@Observable
final class WeatherStore {
    let location = WeatherLocationService()

    private var forecast: WeatherForecast?
    private var fetchedFor: WeatherPlace?
    private var failed = false
    @ObservationIgnored private var fetchedAt: Date?

    func place(for settings: Settings) -> WeatherPlace? {
        if settings.weatherMode == .automatic, let place = location.place { return place }
        return settings.city.map(WeatherPlace.init(city:))
    }

    func forecast(for place: WeatherPlace, demo: Bool) -> WeatherForecast? {
        if demo { return .demo }
        return fetchedFor == place ? forecast : nil
    }

    func forecastFailed(for place: WeatherPlace) -> Bool {
        fetchedFor == place && failed
    }

    func refresh(for place: WeatherPlace) async {
        guard !Task.isCancelled else { return }
        if fetchedFor == place, let fetchedAt, Date.now.timeIntervalSince(fetchedAt) < 900 { return }
        if fetchedFor != place {
            forecast = nil
            failed = false
            fetchedAt = nil
        }
        fetchedFor = place

        do {
            let response = try await WeatherService.forecast(for: place)
            guard !Task.isCancelled, fetchedFor == place else { return }
            forecast = response
            failed = false
            fetchedAt = .now
        } catch {
            guard !Task.isCancelled, fetchedFor == place else { return }
            failed = true
        }
    }
}
