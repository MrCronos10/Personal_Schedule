import SwiftUI

/// Paper with a faint repeating 田字格 behind it: the ground for the screens the student reads and
/// learns on (Reading, Vocabulary, Progress). Chrome screens stay flat `Theme.paper`.
///
/// The named 田字格 ground of the v2 grounds family; `docs/design-v2/brief.md` (Screen grounds).
struct PaperGridBackground: View {
    static let cellSize: CGFloat = 88

    /// Grid red at 6% on cream, lantern cream at 4% on night ink: texture, never UI.
    /// (The brief's v2 faintness; v1 shipped 5%. Final faintness is judged on the phone.)
    static func gridOpacity(for scheme: ColorScheme) -> Double {
        scheme == .dark ? 0.04 : 0.06
    }

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { context, size in
            let cell = Self.cellSize
            // The 田字格 line reads its own token, switched here by scheme so Canvas draws the right
            // value in each mode (gridRed on cream, lantern cream on night ink).
            let line = Color(hex: scheme == .dark ? Theme.Token.gridLine.dark : Theme.Token.gridLine.light)
            let shading = GraphicsContext.Shading.color(line.opacity(Self.gridOpacity(for: scheme)))
            // Solid cells, with a dashed cross through each (the 田字格 guide lines).
            let solid = Path.grid(spacing: cell, in: size)
            let dashed = Path.grid(spacing: cell, offset: cell / 2, in: size)
            context.stroke(solid, with: shading, lineWidth: 1)
            context.stroke(dashed, with: shading, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .background(Theme.paper)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview {
    PaperGridBackground()
}
