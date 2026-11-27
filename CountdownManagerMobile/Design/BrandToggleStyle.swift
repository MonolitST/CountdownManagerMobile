import SwiftUI

struct BrandToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var maximumSpacerWidth: CGFloat? = nil
    var leadingSwitch = false

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: maximumSpacerWidth == nil ? nil : 10) {
                if leadingSwitch { switchBody(configuration.isOn) }
                configuration.label
                if !leadingSwitch {
                    if let maximumSpacerWidth {
                        Spacer(minLength: 0).frame(maxWidth: maximumSpacerWidth)
                    } else {
                        Spacer()
                    }
                    switchBody(configuration.isOn)
                }
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

    private func switchBody(_ enabled: Bool) -> some View {
        Capsule()
            .fill(enabled ? Palette.accent : Palette.outline.opacity(0.55))
            .frame(width: leadingSwitch ? 42 : 49, height: leadingSwitch ? 24 : 28)
            .overlay {
                Circle().fill(enabled ? Palette.onAccent : Palette.surface)
                    .frame(width: leadingSwitch ? 18 : 22, height: leadingSwitch ? 18 : 22)
                    .offset(x: (enabled ? 1 : -1) * (leadingSwitch ? 9 : 10.5))
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: enabled)
            .accessibilityHidden(true)
    }
}
