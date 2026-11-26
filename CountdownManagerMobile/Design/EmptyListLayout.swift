import SwiftUI

struct EmptyListLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let contentProposal = ProposedViewSize(width: proposal.width, height: nil)
        let header = subviews[0].sizeThatFits(contentProposal)
        let card = subviews[1].sizeThatFits(contentProposal)
        let top = cardTop(headerHeight: header.height, viewportHeight: proposal.height)
        return CGSize(
            width: proposal.width ?? max(header.width, card.width),
            height: max(proposal.height ?? 0, top + card.height)
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let contentProposal = ProposedViewSize(width: bounds.width, height: nil)
        let headerHeight = subviews[0].sizeThatFits(contentProposal).height
        let top = cardTop(headerHeight: headerHeight, viewportHeight: proposal.height)
        subviews[0].place(at: bounds.origin, anchor: .topLeading, proposal: contentProposal)
        subviews[1].place(at: CGPoint(x: bounds.minX, y: bounds.minY + top), anchor: .topLeading, proposal: contentProposal)
    }

    private func cardTop(headerHeight: CGFloat, viewportHeight: CGFloat?) -> CGFloat {
        // Both tabs share the design's viewport anchor. Taller headers still get room to scroll.
        max((viewportHeight ?? 0) * 0.37, headerHeight + 20)
    }
}
