import SwiftUI

struct SettingsView: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(WeatherStore.self) private var weather
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showsCityPicker = false
    @State private var picker: PreferencePicker?
    var tablet = false
    var wide = false
    var splitContent = false

    private enum PreferencePicker: String, Identifiable {
        case sound, focus, systemNotifications
        var id: Self { self }
    }

    var body: some View {
        let settings = store.data.settings
        ScreenScroll(topPadding: tablet ? 26 : 10, contentWidth: tablet ? (wide ? 920 : 722) : 530,
                     horizontalPadding: tablet ? 30 : 23) {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(title: String(localized: "Settings"), titleSize: tablet ? 36 : 31)
                if tablet {
                    if splitContent && !dynamicTypeSize.isAccessibilitySize {
                        HStack(alignment: .top, spacing: 22) {
                            appearanceAndWeather.frame(minWidth: 240, maxWidth: .infinity)
                            notificationsAndFocus.frame(minWidth: 240, maxWidth: .infinity)
                        }
                    } else {
                        VStack(spacing: 16) {
                            appearanceAndWeather
                            notificationsAndFocus
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionTitle("Appearance").padding(.bottom, 7)
                        ForEach(AppearancePreference.allCases) { preference in
                            ThemeRow(preference: preference, selected: settings.appearance == preference) {
                                store.set(\.appearance, to: preference)
                            }
                            rule
                        }
                    }
                    weatherControls(settings)
                    notificationControls(settings)
                    focusControl(settings)
                }
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

    private var appearanceAndWeather: some View {
        let settings = store.data.settings
        return VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Appearance")
            settingsCard {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Theme").brandFont(14, relativeTo: .subheadline)
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: 6) { themeButtons }
                    } else {
                        HStack(spacing: 6) { themeButtons }
                    }
                }
                .padding(12)
                rule
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    SettingsValueRow(title: String(localized: "Language"),
                                     value: AppDate.languageCode == "ru" ? "Русский" : "English")
                }
                .buttonStyle(.plain)
                .accessibilityHint(String(localized: "Opens system settings"))
            }
            sectionTitle("Weather")
            settingsCard { weatherControls(settings) }
        }
    }

    private var notificationsAndFocus: some View {
        let settings = store.data.settings
        return VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Notifications")
            settingsCard { notificationControls(settings) }
            sectionTitle("Time to get ready")
            settingsCard { focusControl(settings) }
        }
    }

    private var themeButtons: some View {
        ForEach(AppearancePreference.allCases) { preference in
            let selected = store.data.settings.appearance == preference
            Button {
                store.set(\.appearance, to: preference)
            } label: {
                Text(preference.title)
                    .brandFont(14, weight: selected ? .semibold : .regular, relativeTo: .subheadline)
                    .foregroundStyle(selected ? Palette.accentText : Palette.text)
                    .padding(.horizontal, 7)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .card(selected ? Palette.accent.opacity(0.12) : Palette.inset, cornerRadius: 10)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(selected ? .isSelected : [])
        }
    }

    private func weatherControls(_ settings: Settings) -> some View {
        VStack(spacing: 0) {
            Toggle(String(localized: "Show weather"), isOn: setting(\.showsWeather))
                .brandFont(16)
                .toggleStyle(BrandToggleStyle())
            if tablet { rule }
            Button {
                showsCityPicker = true
            } label: {
                SettingsValueRow(title: String(localized: "City"), value: weather.place(for: settings)?.name ?? String(localized: "Choose a city"))
            }
            .buttonStyle(.plain)
            if !tablet { rule }
        }
    }

    private func notificationControls(_ settings: Settings) -> some View {
        VStack(spacing: 0) {
            Toggle(tablet ? String(localized: "Notifications enabled") : String(localized: "Notifications"), isOn: notificationSetting)
                .brandFont(16)
                .toggleStyle(BrandToggleStyle())
            if tablet { rule }
            Button {
                picker = .sound
            } label: {
                SettingsValueRow(title: String(localized: "Sound"), value: settings.notificationSound.title)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Sound"))
            .accessibilityValue(settings.notificationSound.title)
            if settings.notificationsEnabled, store.notifications.permission == false {
                Button(String(localized: "Allow notifications in iOS Settings")) { picker = .systemNotifications }
                    .brandFont(13, weight: .semibold, relativeTo: .footnote)
                    .foregroundStyle(Palette.accentText)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            if !tablet { rule }
        }
    }

    private func focusControl(_ settings: Settings) -> some View {
        Button {
            picker = .focus
        } label: {
            SettingsValueRow(title: String(localized: "Focus duration"), value: String(localized: "\(settings.focusMinutes) min"), prominent: !tablet)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Focus duration"))
        .accessibilityValue(String(localized: "\(settings.focusMinutes) min"))
    }

    private func sectionTitle(_ title: LocalizedStringResource) -> some View {
        Text(title).brandFont(13, weight: .semibold, relativeTo: .footnote)
            .foregroundStyle(Palette.secondary)
            .accessibilityAddTraits(.isHeader)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0, content: content)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .card(Palette.surface)
            .overlay {
                RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.outline, lineWidth: 0.7)
                    .allowsHitTesting(false)
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
