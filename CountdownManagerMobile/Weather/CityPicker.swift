import SwiftUI

struct CityPicker: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(WeatherStore.self) private var weather
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var search = CitySearch()

    var body: some View {
        @Bindable var search = search
        let term = search.term
        ScreenScroll(topPadding: 8) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ScreenHeader(title: String(localized: "City"))
                    Spacer(minLength: 12)
                    Button { dismiss() } label: {
                        Text("Close")
                            .brandFont(14, weight: .semibold, relativeTo: .subheadline)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.accentText)
                    .conceptGlass(in: Capsule(), interactive: true)
                }

                HStack(spacing: 8) {
                    TextField("City name", text: $search.query)
                        .brandFont(15, relativeTo: .subheadline)
                        .textContentType(.addressCity)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("weather.city.search")
                    if !search.query.isEmpty {
                        Button { search.query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Palette.secondary)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Clear search"))
                    }
                }
                .padding(.leading, 14)
                .padding(.trailing, 4)
                .frame(minHeight: 46)
                .card(Palette.inset, cornerRadius: 12)

                Text(term.count < 2 ? String(localized: "Manual search") : String(localized: "Search results"))
                    .brandFont(13, weight: .semibold, relativeTo: .footnote)
                    .foregroundStyle(Palette.secondary)
                    .accessibilityAddTraits(.isHeader)

                if term.count < 2 {
                    automaticRow
                    if isAutomatic, weather.location.accessDenied {
                        Button("Open iOS Settings", action: openLocationSettings)
                            .frame(minHeight: 44)
                        Text("Allow location access in iOS Settings or choose a city manually.")
                            .brandFont(13, relativeTo: .footnote)
                            .foregroundStyle(Palette.secondary)
                    }
                    if let city = store.data.settings.city { cityRow(city) }
                    Text("Enter a name and choose a city from the results.")
                        .brandFont(13, relativeTo: .footnote)
                        .foregroundStyle(Palette.secondary)
                } else {
                    results
                }

                if let url = URL(string: "https://open-meteo.com/") {
                    Link("Weather and city data by Open-Meteo", destination: url)
                        .brandFont(11, relativeTo: .caption2)
                        .foregroundStyle(Palette.secondary)
                        .padding(.vertical, 3)
                }
            }
        }
        .foregroundStyle(Palette.text)
        .tint(Palette.accentText)
        .preferredColorScheme(store.data.settings.appearance.colorScheme)
        .task(id: term) { await search.loadMatches(for: term) }
    }

    private var isAutomatic: Bool { store.data.settings.weatherMode == .automatic }

    @ViewBuilder
    private var results: some View {
        switch search.phase {
        case .idle, .searching:
            ProgressView("Searching for cities…")
        case .failed:
            Text("Couldn’t load cities. Check your connection.")
                .brandFont(13, relativeTo: .footnote)
                .foregroundStyle(Palette.secondary)
        case let .results(cities):
            if cities.isEmpty {
                ContentUnavailableView.search(text: search.term)
            } else {
                ForEach(cities) { city in cityRow(city) }
            }
        }
    }

    private var automaticRow: some View {
        Button(action: useCurrentLocation) {
            choice(String(localized: "Detect automatically"), subtitle: automaticSubtitle, selected: isAutomatic)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isAutomatic ? .isSelected : [])
        .accessibilityIdentifier("weather.location.automatic")
    }

    private var automaticSubtitle: String {
        if isAutomatic {
            if let city = weather.location.place?.name { return city }
            if weather.location.isLocating { return String(localized: "Finding your city…") }
            if weather.location.failed { return String(localized: "Location unavailable") }
        }
        return String(localized: "Use your current location")
    }

    private func cityRow(_ city: WeatherCity) -> some View {
        let selected = !isAutomatic && city.id == store.data.settings.city?.id
        return Button {
            if store.selectWeatherCity(city) { dismiss() }
        } label: {
            choice(city.displayName, subtitle: city.region, selected: selected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func choice(_ title: String, subtitle: String, selected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).brandFont(16)
                if !subtitle.isEmpty {
                    Text(subtitle).brandFont(13, relativeTo: .footnote)
                        .foregroundStyle(Palette.secondary)
                }
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accentText)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 64)
        .card(cornerRadius: 12)
        .contentShape(.rect(cornerRadius: 12))
    }

    private func useCurrentLocation() {
        if store.selectAutomaticWeatherLocation(), store.data.settings.showsWeather, !store.usesDemoContent {
            weather.location.useCurrentLocation()
        }
    }

    private func openLocationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}
