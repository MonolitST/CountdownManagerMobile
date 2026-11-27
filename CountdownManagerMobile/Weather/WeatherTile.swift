import SwiftUI

struct WeatherTile: View {
    let place: WeatherPlace
    let forecast: WeatherForecast?
    let failed: Bool
    var isDemo = false
    var sidebar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 10) {
                Group {
                    if let forecast, forecast.current.weatherCode != 3 {
                        Image(systemName: forecast.current.symbol).font(.title3)
                    } else {
                        DesignIcon(.weather)
                    }
                }
                .frame(width: 27, height: 27)
                .foregroundStyle(Palette.accentText)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(sidebar ? place.name : forecast.map { "\(place.name) · \(condition($0.current.condition))" } ?? place.name)
                        .brandFont(13, weight: .medium, relativeTo: .footnote)
                    Text(sidebar ? forecast.map { condition($0.current.condition) } ?? summary : summary)
                        .brandFont(11, relativeTo: .caption2)
                        .foregroundStyle(Palette.secondary)
                }
                Spacer(minLength: 0)
                if let forecast {
                    Text(degrees(forecast.current.temperature2m))
                        .brandFont(sidebar ? 21 : 26, weight: .light, relativeTo: .title2)
                        .accessibilityLabel("\(Int(forecast.current.temperature2m.rounded())) degrees Celsius")
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("weather.forecast")
            if forecast != nil, !isDemo {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { attributionLinks }
                        .fixedSize(horizontal: true, vertical: false)
                    VStack(alignment: .leading, spacing: 6) { attributionLinks }
                }
                .font(.caption2)
                .foregroundStyle(Palette.accentText)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .card(sidebar ? Palette.background : Palette.inset, cornerRadius: 12)
    }

    private var attributionLinks: some View {
        Group {
            if let provider = URL(string: "https://open-meteo.com/"),
               let license = URL(string: "https://creativecommons.org/licenses/by/4.0/") {
                Link("Weather data by Open-Meteo", destination: provider)
                Link("CC BY 4.0 license", destination: license)
            }
        }
    }

    private var summary: String {
        guard let forecast else { return failed ? String(localized: "Forecast unavailable") : String(localized: "Loading forecast…") }
        guard let minimum = forecast.daily.temperature2mMin.first ?? nil,
              let maximum = forecast.daily.temperature2mMax.first ?? nil else { return String(localized: "Current temperature") }
        return String(localized: "Today: \(degrees(minimum)) to \(degrees(maximum))")
    }

    private func condition(_ value: String) -> String {
        guard AppDate.languageCode == "en" else { return value }
        return value.prefix(1).uppercased(with: AppDate.locale) + value.dropFirst()
    }

    private func degrees(_ number: Double) -> String {
        Int(number.rounded()).formatted(.number.grouping(.never)) + "°"
    }
}
