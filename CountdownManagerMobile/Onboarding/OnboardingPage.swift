import Foundation

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case plans, reminders, timer

    var id: Self { self }
    var next: Self? { Self(rawValue: rawValue + 1) }

    var title: LocalizedStringResource {
        switch self {
        case .plans: "Plans with\nchecklists"
        case .reminders: "Reminders at\nthe right time"
        case .timer: "Keep your timer\nin view"
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .plans: "Choose a date, track the countdown, and check things off as you get ready."
        case .reminders: "Set a one-time reminder or choose which days and hours it repeats."
        case .timer: "Live Activity shows the countdown on your Lock Screen and in Dynamic Island."
        }
    }
}
