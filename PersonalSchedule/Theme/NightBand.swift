import SwiftUI

/// The 进度 ground: an ink header band with rounded bottom corners sitting over the 田字格 paper.
/// Flat shapes, no gradients. `docs/design-v2/brief.md` (Screen grounds). Ticket 07 (Progress) places
/// it and sets its height; here it is a standalone, previewable primitive with a default height.
struct NightBand: View {
    static let cornerRadius: CGFloat = 20
    static let defaultHeaderHeight: CGFloat = 150

    var headerHeight: CGFloat = NightBand.defaultHeaderHeight

    var body: some View {
        ZStack(alignment: .top) {
            PaperGridBackground()
            UnevenRoundedRectangle(
                bottomLeadingRadius: Self.cornerRadius,
                bottomTrailingRadius: Self.cornerRadius
            )
            .fill(Theme.nightBand)
            .frame(height: headerHeight)
            .ignoresSafeArea(edges: .top)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    NightBand()
}
