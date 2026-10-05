import SwiftUI

extension Path {
    /// A grid of vertical and horizontal lines spaced `spacing` apart, shifted by `offset`, covering
    /// `size`. The one place the ground textures (`PaperGridBackground`, `LacquerBackground`) build
    /// their line skeleton, so the edge behaviour lives in a single spot.
    static func grid(spacing: CGFloat, offset: CGFloat = 0, in size: CGSize) -> Path {
        var path = Path()
        var x: CGFloat = 0
        while x <= size.width {
            let px = x + offset
            path.move(to: CGPoint(x: px, y: 0))
            path.addLine(to: CGPoint(x: px, y: size.height))
            x += spacing
        }
        var y: CGFloat = 0
        while y <= size.height {
            let py = y + offset
            path.move(to: CGPoint(x: 0, y: py))
            path.addLine(to: CGPoint(x: size.width, y: py))
            y += spacing
        }
        return path
    }
}
