import SwiftUI

/// The 今天 Dawn ground: cream with three layered hills and a low red sun, behind the header only.
/// Flat shapes, no gradients. `docs/design-v2/brief.md` (Screen grounds). Ticket 03 (Today) places it;
/// here it is a standalone, previewable primitive.
struct DawnHeader: View {
    /// The header is 250 pt tall; the rest of 今天 sits on flat `Theme.paper` below it.
    static let height: CGFloat = 250

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.paper
            // A low red sun over the far hills.
            GeometryReader { geo in
                Circle()
                    .fill(Theme.red)
                    .frame(width: 64, height: 64)
                    .position(x: geo.size.width - 72, y: Self.height * 0.40)
            }
            // Three layered hills, far (lightest, tallest) to near (darkest, lowest).
            Hill().fill(Theme.dawnHill1).frame(height: 104)
            Hill().fill(Theme.dawnHill2).frame(height: 80).offset(y: 14)
            Hill().fill(Theme.dawnHill3).frame(height: 56).offset(y: 26)
        }
        .frame(height: Self.height)
        .clipped()
        .accessibilityHidden(true)
    }
}

/// A single hill: a wide, low dome anchored to the bottom of its frame.
private struct Hill: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    DawnHeader()
}
