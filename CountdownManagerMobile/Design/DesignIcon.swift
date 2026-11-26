import SwiftUI

struct DesignIcon: View {
    let asset: ImageResource

    init(_ asset: ImageResource) { self.asset = asset }

    var body: some View {
        Image(asset).accessibilityHidden(true)
    }
}
