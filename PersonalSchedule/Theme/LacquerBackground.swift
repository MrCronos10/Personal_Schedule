import SwiftUI

/// The 印章册 ground: a flat lacquer field with a faint cream tile grid — the one dark screen in light
/// mode (lacquer is the same in both). Flat shapes, no gradients. `docs/design-v2/brief.md` (Screen
/// grounds). Ticket 08 places it on the Seal Book; here it is a standalone, previewable primitive.
struct LacquerBackground: View {
    static let tileSize: CGFloat = 64
    /// Cream tile lines sit at 5% so they read as lacquer grain, never UI.
    static let tileOpacity: Double = 0.05

    var body: some View {
        Canvas { context, size in
            let cream = Color(hex: Theme.Token.paper.light) // cream in both modes, on the lacquer field
            let shading = GraphicsContext.Shading.color(cream.opacity(Self.tileOpacity))
            let lines = Path.grid(spacing: Self.tileSize, in: size)
            context.stroke(lines, with: shading, lineWidth: 1)
        }
        .background(Theme.lacquer)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview {
    LacquerBackground()
}
