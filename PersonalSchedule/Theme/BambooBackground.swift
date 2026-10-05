import SwiftUI

/// The 词 ground: bamboo paper with a few faint bamboo stems and leaves in the top-right. Flat shapes,
/// no gradients. `docs/design-v2/brief.md` (Screen grounds). Ticket 06 places it on 词; here it is a
/// standalone, previewable primitive.
struct BambooBackground: View {
    /// Foliage sits at 14–18% green so it reads as texture, never UI.
    static let stemOpacity: Double = 0.16
    static let leafOpacity: Double = 0.14

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Theme.bambooPaper
            Canvas { context, size in
                // Green switched by scheme so Canvas draws the right value in each mode.
                let green = Color(hex: scheme == .dark ? Theme.Token.bamboo.dark : Theme.Token.bamboo.light)
                let stem = GraphicsContext.Shading.color(green.opacity(Self.stemOpacity))
                let leaf = GraphicsContext.Shading.color(green.opacity(Self.leafOpacity))

                // Two stems leaning in from the top-right corner.
                for (x, lean) in [(size.width - 44, 10.0), (size.width - 20, -6.0)] {
                    var stemPath = Path(
                        roundedRect: CGRect(x: x, y: -24, width: 5, height: 180),
                        cornerSize: CGSize(width: 2.5, height: 2.5)
                    )
                    stemPath = stemPath.applying(
                        .init(translationX: x + 2.5, y: 0)
                            .rotated(by: lean * .pi / 180)
                            .translatedBy(x: -(x + 2.5), y: 0)
                    )
                    context.fill(stemPath, with: stem)
                }

                // A few leaves as small ellipses near the stems.
                for (dx, dy, w, h) in [(30.0, 36.0, 34.0, 12.0), (54.0, 18.0, 28.0, 10.0), (14.0, 70.0, 30.0, 11.0)] {
                    let rect = CGRect(x: size.width - dx, y: dy, width: w, height: h)
                    context.fill(Path(ellipseIn: rect), with: leaf)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview {
    BambooBackground()
}
