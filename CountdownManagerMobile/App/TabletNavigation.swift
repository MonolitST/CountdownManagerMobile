import SwiftUI

struct TabletNavigation: View {
    @Binding var selection: PlannerTab
    let sidebar: Bool
    var showsMark = true

    var body: some View {
        if sidebar {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 9) {
                    mark
                    Text(verbatim: "Countdown\nManager")
                        .brandFont(15, weight: .semibold, relativeTo: .subheadline)
                }
                .padding(.bottom, 12)
                tabs
                Spacer(minLength: 12)
                PlannerWeatherTile(sidebar: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 22)
            .background(Palette.inset.ignoresSafeArea())
        } else {
            HStack(spacing: 12) {
                if showsMark { mark }
                Spacer(minLength: 4)
                tabStrip
                Spacer(minLength: 4)
                if showsMark { Color.clear.frame(width: 36, height: 1).accessibilityHidden(true) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Palette.outline.opacity(0.3)).frame(height: 1)
                    .padding(.horizontal, 16)
                    .accessibilityHidden(true)
            }
        }
    }

    private var tabStrip: some View {
        HStack(spacing: 4) { tabs }
            .padding(4)
            .frame(maxWidth: 472)
            .card(Palette.surface, cornerRadius: 15)
            .overlay { RoundedRectangle(cornerRadius: 15).strokeBorder(Palette.outline, lineWidth: 0.7) }
    }

    private var tabs: some View {
        ForEach(PlannerTab.allCases) { tab in
            Button {
                selection = tab
            } label: {
                Label {
                    Text(tab.title).brandFont(15, weight: .medium, relativeTo: .subheadline)
                } icon: {
                    DesignIcon(tab.icon).foregroundStyle(Palette.accentText)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: sidebar ? .leading : .center)
                .card(selection == tab ? Palette.accent.opacity(0.12) : .clear, cornerRadius: 10)
                .contentShape(.rect(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(selection == tab ? .isSelected : [])
            .accessibilityIdentifier("tab.\(tab)")
        }
    }

    private var mark: some View {
        Image(.tabletAppMark)
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
            .clipShape(.rect(cornerRadius: 8))
            .accessibilityHidden(true)
    }
}
