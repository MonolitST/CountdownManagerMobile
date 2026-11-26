import SwiftUI

private struct BrandTypography: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight

    init(size: CGFloat, weight: Font.Weight, relativeTo style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight))
    }
}

extension View {
    func brandFont(_ size: CGFloat, weight: Font.Weight = .regular,
                   relativeTo style: Font.TextStyle = .body) -> some View {
        modifier(BrandTypography(size: size, weight: weight, relativeTo: style))
    }

    func displayFont(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> some View {
        font(.custom("PTSerif-Regular", size: size, relativeTo: style))
    }
}
