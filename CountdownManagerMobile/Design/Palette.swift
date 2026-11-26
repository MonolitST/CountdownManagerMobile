import SwiftUI

enum Palette {
    static let background = Color(.background)
    static let surface = Color(.surface)
    static let inset = Color(.timerSurface)
    static let outline = Color(.border)
    static let text = Color(.textPrimary)
    static let secondary = Color(.textSecondary)
    static let accent = Color.accentColor
    static let accentText = Color(.textAccent)
    static let onAccent = Color(.onAccent)
    static let success = Color(.success)
}

extension AppearancePreference {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
