import SwiftUI

struct ScreenNavigation<Trailing: View>: View {
    var backLabel: String
    var goBack: () -> Void
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            Button(action: goBack) {
                Label {
                    Text(backLabel).brandFont(14, relativeTo: .subheadline)
                } icon: {
                    DesignIcon(.back)
                }
                .foregroundStyle(Palette.accentText)
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            Spacer()
            trailing
        }
    }
}

extension ScreenNavigation where Trailing == EmptyView {
    init(backLabel: String, goBack: @escaping () -> Void) {
        self.init(backLabel: backLabel, goBack: goBack, trailing: EmptyView.init)
    }
}
