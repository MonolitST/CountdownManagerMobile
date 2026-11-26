import SwiftUI

struct ConceptSheet<Content: View>: View {
    @ScaledMetric(relativeTo: .body) private var heightScale = 1.0
    let title: String
    let height: CGFloat
    var done: (() -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(title)
                        .displayFont(26, relativeTo: .title2)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 8)
                    if let done {
                        Button(String(localized: "Done"), action: done)
                            .brandFont(15, weight: .semibold, relativeTo: .subheadline)
                            .foregroundStyle(Palette.accentText)
                            .frame(minHeight: 44)
                    }
                }
                VStack(alignment: .leading, spacing: 8) { content }
            }
            .frame(maxWidth: 480, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Palette.text)
        .tint(Palette.accentText)
        .presentationDetents([.height(height * heightScale), .large])
        .presentationDragIndicator(.visible)
        .modifier(ConceptSheetBackground())
    }
}

private struct ConceptSheetBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            content.presentationBackground(.regularMaterial)
        }
    }
}

struct ConceptSheetOption: View {
    let title: String
    var selected = false
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .brandFont(15, weight: selected ? .semibold : .regular, relativeTo: .subheadline)
                Spacer(minLength: 4)
                if selected {
                    Image(systemName: "checkmark").font(.subheadline.weight(.semibold))
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .foregroundStyle(selected ? Palette.accentText : Palette.text)
            .background(selected ? Palette.accent.opacity(0.12) : Palette.surface.opacity(0.87),
                        in: .rect(cornerRadius: 9))
            .contentShape(.rect(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct ConceptConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    var message: String? = nil
    let actionTitle: String
    var cancelTitle = String(localized: "Cancel")
    var destructive = false
    var cancel: () -> Void = {}
    let action: () -> Void

    var body: some View {
        ConceptSheet(title: title, height: message == nil ? 176 : 236) {
            if let message {
                Text(message)
                    .brandFont(14, relativeTo: .subheadline)
                    .foregroundStyle(Palette.secondary)
                    .padding(.bottom, 4)
            }
            ConceptSheetOption(title: actionTitle, role: destructive ? .destructive : nil) {
                action()
                dismiss()
            }
            ConceptSheetOption(title: cancelTitle, role: .cancel) {
                cancel()
                dismiss()
            }
        }
    }
}
