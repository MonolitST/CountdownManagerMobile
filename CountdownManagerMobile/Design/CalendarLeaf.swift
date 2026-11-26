import SwiftUI

struct CalendarLeaf: View {
    let date: Date
    var size: Size = .normal

    enum Size {
        case compact, normal, large

        var width: CGFloat { self == .compact ? 42 : self == .normal ? 58 : 64 }
        var height: CGFloat { self == .compact ? 56 : 68 }
        var monthHeight: CGFloat { self == .compact ? 19 : 22 }
        var numberSize: CGFloat { self == .compact ? 25 : 34 }
    }

    var body: some View {
        let month = date.formatted(.dateTime.month(.abbreviated).locale(AppDate.locale))
            .trimmingCharacters(in: .punctuationCharacters).uppercased()
        let day = date.formatted(.dateTime.day().locale(AppDate.locale))

        VStack(spacing: 0) {
            Text(month)
                .font(.system(size: size == .compact ? 9 : 10, weight: .bold))
                .foregroundStyle(Palette.onAccent)
                .frame(maxWidth: .infinity, minHeight: size.monthHeight)
                .background(Palette.accent)
            Text(day)
                .font(.custom("PTSerif-Regular", fixedSize: size.numberSize))
                .foregroundStyle(Palette.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: size.width, height: size.height)
        .background(Palette.surface)
        .clipShape(.rect(cornerRadius: 5))
        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Palette.outline, lineWidth: 1))
        .accessibilityHidden(true)
    }
}
