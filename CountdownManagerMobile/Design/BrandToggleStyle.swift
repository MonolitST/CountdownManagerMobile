import SwiftUI

struct BrandToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var maximumSpacerWidth: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: maximumSpacerWidth == nil ? nil : 10) {
                configuration.label
                if let maximumSpacerWidth {
                    Spacer(minLength: 0).frame(maxWidth: maximumSpacerWidth)
                } else {
                    Spacer()
                }
                Capsule()
                    .fill(configuration.isOn ? Palette.accent : Palette.outline.opacity(0.55))
                    .frame(width: 49, height: 28)
                    .overlay {
                        Circle().fill(configuration.isOn ? Palette.onAccent : Palette.surface)
                            .frame(width: 22, height: 22)
                            .offset(x: configuration.isOn ? 10.5 : -10.5)
                    }
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: configuration.isOn)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityRemoveTraits(.isButton)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? String(localized: "On") : String(localized: "Off"))
    }
}
