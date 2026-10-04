import SwiftUI

/// The app's mark: 读 (to read) in a red 田字格, the same drawing as the app icon.
struct LogoView: View {
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            Theme.paper
            Canvas { context, canvas in
                let inset = canvas.width * 0.094
                let box = CGRect(x: inset, y: inset, width: canvas.width - inset * 2, height: canvas.height - inset * 2)
                var cross = Path()
                cross.move(to: CGPoint(x: box.minX, y: box.midY))
                cross.addLine(to: CGPoint(x: box.maxX, y: box.midY))
                cross.move(to: CGPoint(x: box.midX, y: box.minY))
                cross.addLine(to: CGPoint(x: box.midX, y: box.maxY))
                let dash = canvas.width * 0.03
                context.stroke(cross, with: .color(Theme.red.opacity(0.45)),
                               style: StrokeStyle(lineWidth: canvas.width * 0.008, dash: [dash, dash]))
                context.stroke(Path(box), with: .color(Theme.red), lineWidth: canvas.width * 0.022)
            }
            Text(verbatim: "读")
                .font(Theme.serif(size * 0.58, .black))
                .foregroundStyle(Theme.ink)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "读"))
    }
}

#Preview {
    LogoView(size: 160)
}
