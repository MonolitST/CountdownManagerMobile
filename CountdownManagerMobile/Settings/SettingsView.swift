import SwiftUI

struct SettingsView: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(WeatherStore.self) private var weather
    @Environment(\.openURL) private var openURL
    @State private var showsCityPicker = false
    @State private var picker: PreferencePicker?

    private enum PreferencePicker: String, Identifiable {
        case sound, focus, systemNotifications
        var id: Self { self }
    }

    var body: some View {
        let settings = store.data.settings
        ScreenScroll {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(title: String(localized: "Settings"))

                VStack(alignment: .leading, spacing: 0) {
                    Text(String(localized: "Appearance")).brandFont(13, relativeTo: .footnote)
                        .foregroundStyle(Palette.secondary)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.bottom, 7)
                    ForEach(AppearancePreference.allCases) { preference in
                        ThemeRow(preference: preference, selected: settings.appearance == preference) {
                            store.set(\.appearance, to: preference)
                        }
                        rule
                    }
                }
                VStack(spacing: 0) {
                    Toggle(String(localized: "Show weather"), isOn: setting(\.showsWeather))
                        .brandFont(16)
                        .toggleStyle(BrandToggleStyle())
                    Button {
                        showsCityPicker = true
                    } label: {
                        SettingsValueRow(title: String(localized: "City"), value: weather.place(for: settings)?.name ?? String(localized: "Choose a city"))
                    }
                    .buttonStyle(.plain)
                    rule
                }
                VStack(spacing: 0) {
                    Toggle(String(localized: "Notifications"), isOn: notificationSetting)
                        .brandFont(16)
                        .toggleStyle(BrandToggleStyle())
                    Button {
                        picker = .sound
                    } label: {
                        SettingsValueRow(title: String(localized: "Sound"), value: settings.notificationSound.title)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Sound"))
                    .accessibilityValue(settings.notificationSound.title)
                    if settings.notificationsEnabled, store.notifications.permission == false {
                        Button(String(localized: "Allow notifications in iOS Settings")) {
                            picker = .systemNotifications
                        }
                        .brandFont(13, relativeTo: .footnote)
                        .foregroundStyle(Palette.accentText)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    rule
                }
                Button {
                    picker = .focus
                } label: {
                    SettingsValueRow(title: String(localized: "Focus duration"), value: String(localized: "\(settings.focusMinutes) min"), prominent: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Focus duration"))
                .accessibilityValue(String(localized: "\(settings.focusMinutes) min"))
            }
        }
        .fullScreenCover(isPresented: $showsCityPicker) {
            CityPicker()
        }
        .sheet(item: $picker) { picker in
            switch picker {
            case .sound:
                ConceptSheet(title: String(localized: "Sound"), height: 176) {
                    ForEach(NotificationSound.allCases) { sound in
                        ConceptSheetOption(title: sound.title, selected: settings.notificationSound == sound) {
                            store.set(\.notificationSound, to: sound)
                            self.picker = nil
                        }
                    }
                }
            case .focus:
                ConceptSheet(title: String(localized: "Focus duration"), height: 284) {
                    ForEach(Settings.focusDurations, id: \.self) { minutes in
                        ConceptSheetOption(title: String(localized: "\(minutes) min"), selected: settings.focusMinutes == minutes) {
                            store.set(\.focusMinutes, to: minutes)
                            self.picker = nil
                        }
                    }
                }
            case .systemNotifications:
                ConceptConfirmationSheet(title: String(localized: "iOS notification settings"),
                                         message: String(localized: "In iOS Settings, open Countdown Manager and allow notifications."),
                                         actionTitle: String(localized: "Allow Notifications"), action: openNotificationSettings)
            }
        }
    }

    private var rule: some View {
        Rectangle().fill(Palette.outline).frame(height: 0.7).accessibilityHidden(true)
    }

    private var notificationSetting: Binding<Bool> {
        Binding(get: { store.data.settings.notificationsEnabled && store.notifications.permission != false },
                set: { enabled in
                    if enabled, store.notifications.permission == false {
                        picker = .systemNotifications
                    } else {
                        store.set(\.notificationsEnabled, to: enabled, requestPermission: enabled)
                    }
                })
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
    }

    private func setting<Value>(_ key: WritableKeyPath<Settings, Value>) -> Binding<Value> {
        Binding(get: { store.data.settings[keyPath: key] }, set: {
            store.set(key, to: $0)
        })
    }
}
