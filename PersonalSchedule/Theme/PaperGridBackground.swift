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
            var solid = Path()
            var dashed = Path()
            var x: CGFloat = 0
            while x <= size.width {
                solid.move(to: CGPoint(x: x, y: 0))
                solid.addLine(to: CGPoint(x: x, y: size.height))
                dashed.move(to: CGPoint(x: x + cell / 2, y: 0))
                dashed.addLine(to: CGPoint(x: x + cell / 2, y: size.height))
                x += cell
            }
            var y: CGFloat = 0
            while y <= size.height {
                solid.move(to: CGPoint(x: 0, y: y))
                solid.addLine(to: CGPoint(x: size.width, y: y))
                dashed.move(to: CGPoint(x: 0, y: y + cell / 2))
                dashed.addLine(to: CGPoint(x: size.width, y: y + cell / 2))
                y += cell
            }
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
