import SwiftUI

struct PlannerRoot: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(WeatherStore.self) private var weather
    @Environment(NotificationPresentation.self) private var notificationPresentation
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection = PlannerTab.plans
    @State private var today = Date.now
    @State private var planPath: [UUID] = []
    @State private var focusPlan: Plan?
    @Binding var showsNewPlan: Bool
    @Binding var pendingFocusPlanID: UUID?

    var body: some View {
        let locationContext = locationRefresh
        let forecastContext = weatherRefresh
        TabView(selection: $selection) {
            Tab(PlannerTab.plans.title, image: "TabCalendar", value: .plans) {
                PlansNavigation(today: today, path: $planPath, showsNewPlan: $showsNewPlan,
                                onOpenTimer: { focusPlan = $0 })
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(PlannerTab.reminders.title, image: "TabBell", value: .reminders) {
                RemindersNavigation(today: today, onOpenPlan: { openPlan($0, showsTimer: false) })
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(PlannerTab.settings.title, image: "TabSettings", value: .settings) {
                SettingsView()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .tabViewStyle(.tabBarOnly)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PlannerTabBar(selection: $selection)
        }
        .background(Palette.background.ignoresSafeArea())
        .foregroundStyle(Palette.text)
        .tint(Palette.accentText)
        .preferredColorScheme(store.data.settings.appearance.colorScheme)
        .environment(\.locale, AppDate.locale)
        .environment(\.calendar, CalendarDay.calendar)
        .onChange(of: notificationPresentation.pending, initial: true) { _, pending in
            guard let pending else { return }
            notificationPresentation.pending = nil
            openNotification(pending)
        }
        .onChange(of: pendingFocusPlanID, initial: true) { _, id in
            guard let id else { return }
            pendingFocusPlanID = nil
            openPlan(id, showsTimer: true)
        }
        .fullScreenCover(item: $focusPlan) { plan in
            FocusTimerView(plan: plan)
        }
        .modifier(NotificationIntroduction())
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            today = store.displayNow
            if let planID = store.refreshAfterSharing() { openPlan(planID, showsTimer: false) }
            store.refreshNotifications()
            store.restoreFocusLiveActivity()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(30)) } catch { break }
                today = store.displayNow
            }
        }
        .task(id: locationContext) {
            guard !Task.isCancelled else { return }
            weather.location.configure(automatic: locationContext.automatic, active: locationContext.active)
        }
        .task(id: forecastContext) {
            guard !Task.isCancelled, !store.usesDemoContent, forecastContext.active, let place = forecastContext.place else { return }
            while !Task.isCancelled {
                await weather.refresh(for: place)
                do {
                    try await Task.sleep(for: .seconds(weather.forecastFailed(for: place) ? 60 : 900))
                } catch {
                    break
                }
            }
        }
        .alert("Countdown Manager", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button(String(localized: "Close"), role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private func openNotification(_ interaction: NotificationInteraction) {
        switch interaction.destination {
        case let .plan(id):
            openPlan(id, showsTimer: false)
        case let .focus(id):
            openPlan(id, showsTimer: true)
        case .reminder:
            focusPlan = nil
            selection = .reminders
        }
    }

    private func openPlan(_ id: UUID, showsTimer: Bool) {
        selection = .plans
        guard let plan = store.data.plans.first(where: { $0.id == id }) else { return }
        planPath = [id]
        if !showsTimer {
            focusPlan = nil
        } else if focusPlan?.id != plan.id {
            focusPlan = plan
        }
    }
    private var locationRefresh: LocationRefresh {
        let settings = store.data.settings
        return LocationRefresh(active: scenePhase == .active,
                               automatic: settings.showsWeather && settings.weatherMode == .automatic
                                 && !store.usesDemoContent)
    }

    private var weatherRefresh: WeatherRefresh {
        let settings = store.data.settings
        return WeatherRefresh(active: scenePhase == .active, place: settings.showsWeather ? weather.place(for: settings) : nil)
    }

    private struct LocationRefresh: Equatable {
        let active: Bool
        let automatic: Bool
    }

    private struct WeatherRefresh: Equatable {
        let active: Bool
        let place: WeatherPlace?
    }
}
