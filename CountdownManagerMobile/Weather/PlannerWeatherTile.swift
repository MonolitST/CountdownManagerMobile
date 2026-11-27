import SwiftUI

struct PlannerWeatherTile: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(WeatherStore.self) private var weather
    @State private var showsCityPicker = false
    var sidebar = false

    var body: some View {
        if store.data.settings.showsWeather {
            Group {
                if let place = weather.place(for: store.data.settings) {
                    WeatherTile(place: place, forecast: weather.forecast(for: place, demo: store.usesDemoContent),
                                failed: weather.forecastFailed(for: place), isDemo: store.usesDemoContent, sidebar: sidebar)
                } else {
                    WeatherSetupTile(isLocating: weather.location.isLocating,
                                     unavailable: weather.location.accessDenied || weather.location.failed) {
                        showsCityPicker = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showsCityPicker) { CityPicker() }
        }
    }
}
