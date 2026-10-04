import SwiftUI

/// Paper with a faint repeating 田字格 behind it: the ground for the screens the student reads and
/// learns on (Reading, Vocabulary, Progress). Chrome screens stay flat `Theme.paper`.
struct BackgroundView: View {
    static let cellSize: CGFloat = 88

    /// Grid red at 5% on cream, lantern cream at 4% on night ink: texture, never UI.
    static func gridOpacity(for scheme: ColorScheme) -> Double {
        scheme == .dark ? 0.04 : 0.05
    }

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { context, size in
            let cell = Self.cellSize
            let line = scheme == .dark ? Theme.Palette.lanternCream : Theme.Palette.gridRed
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
    BackgroundView()
}
