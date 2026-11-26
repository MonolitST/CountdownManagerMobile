import SwiftUI

struct FieldLabel<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).brandFont(13, relativeTo: .footnote)
                .foregroundStyle(Palette.secondary)
                .accessibilityHidden(true)
            content
        }
    }
}
