import SwiftUI

@main
struct CountdownManagerApp: App {
    @UIApplicationDelegateAdaptor(PlannerAppDelegate.self) private var appDelegate
    @State private var weather = WeatherStore()

    var body: some Scene {
        WindowGroup {
            FirstRunView()
                .environment(appDelegate.store)
                .environment(weather)
                .environment(appDelegate.notificationPresentation)
        }
    }
}
