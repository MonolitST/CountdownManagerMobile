import SwiftUI

struct PlannerTabBar: View {
    @Binding var selection: PlannerTab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionIndicator

    var body: some View {
        HStack(spacing: 4) {
            ForEach(PlannerTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 2) {
                        DesignIcon(tab.icon)
                        Text(tab.title).brandFont(10, relativeTo: .caption2)
                    }
                    .foregroundStyle(selection == tab ? Palette.accentText : Palette.secondary)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background {
                        if selection == tab {
                            Capsule()
                                .fill(Palette.accent.opacity(0.12))
                                .matchedGeometryEffect(id: "selection", in: selectionIndicator)
                        }
                    }
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
                .accessibilityIdentifier("tab.\(tab)")
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.24), value: selection)
        .padding(6)
        .frame(maxWidth: 530)
        .conceptGlass(in: Capsule())
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .accessibilityElement(children: .contain)
    }
}
