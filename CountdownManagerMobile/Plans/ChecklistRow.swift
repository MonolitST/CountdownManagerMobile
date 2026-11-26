import SwiftUI

struct ChecklistRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let item: ChecklistItem
    var minHeight: CGFloat = 44
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 10) {
                Circle()
                    .fill(item.isDone ? Palette.secondary : .clear)
                    .overlay { Circle().strokeBorder(Palette.secondary, lineWidth: 0.8) }
                    .frame(width: 20, height: 20)
                    .overlay {
                        if item.isDone {
                            DesignIcon(.checklistCheck)
                                .foregroundStyle(Palette.background)
                                .transition(.scale(scale: 0.65).combined(with: .opacity))
                        }
                    }
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: item.isDone)
                    .accessibilityHidden(true)
                Text(item.title)
                    .brandFont(14, relativeTo: .subheadline)
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? Palette.secondary : Palette.text)
            }
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .contentShape(Rectangle().inset(by: min(0, (minHeight - 44) / 2)))
        }
        .buttonStyle(.plain)
        .accessibilityValue(item.isDone ? String(localized: "Completed") : String(localized: "Not completed"))
    }
}
