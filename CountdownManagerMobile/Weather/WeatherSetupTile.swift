import SwiftUI

struct WeatherSetupTile: View {
    let isLocating: Bool
    let unavailable: Bool
    let onChoose: () -> Void

    var body: some View {
        Button(action: onChoose) {
            HStack(spacing: 10) {
                DesignIcon(.weather).foregroundStyle(Palette.accentText)
                VStack(alignment: .leading, spacing: 3) {
                    if isLocating {
                        Text("Finding your city…")
                    } else if unavailable {
                        Text("Location unavailable")
                    } else {
                        Text("Choose a city")
                    }
                    Text("Tap to set a city.")
                        .font(.caption)
                        .foregroundStyle(Palette.secondary)
                }
                Spacer(minLength: 0)
                if isLocating {
                    ProgressView().accessibilityHidden(true)
                } else {
                    DesignIcon(.chevron).foregroundStyle(Palette.secondary)
                }
            }
            .padding(10)
            .frame(minHeight: 44)
            .card(Palette.inset, cornerRadius: 12)
            .contentShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("weather.choose")
    }
}
