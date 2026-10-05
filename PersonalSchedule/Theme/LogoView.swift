import SwiftUI

/// The app's mark: 读 (to read), brush-written in a red 田字格, the same drawing as the app icon. A
/// small seal-red 日 chop (from 日课) sits in the bottom-right. At small sizes the dashed cross and the
/// chop drop away, leaving just 读 in its box.
struct LogoView: View {
    var size: CGFloat = 96

    /// Above this the dashed cross and the 日 chop show; at or below it they drop (brief: "At ≤ 40 pt
    /// drop the dashed cross and the chop").
    static func showsDetails(at size: CGFloat) -> Bool { size > 40 }

    private var showsDetails: Bool { Self.showsDetails(at: size) }

    var body: some View {
        ZStack {
            Theme.paper
            Canvas { context, canvas in
                let inset = canvas.width * 0.094
                let box = CGRect(x: inset, y: inset, width: canvas.width - inset * 2, height: canvas.height - inset * 2)
                if showsDetails {
                    var cross = Path()
                    cross.move(to: CGPoint(x: box.minX, y: box.midY))
                    cross.addLine(to: CGPoint(x: box.maxX, y: box.midY))
                    cross.move(to: CGPoint(x: box.midX, y: box.minY))
                    cross.addLine(to: CGPoint(x: box.midX, y: box.maxY))
                    let dash = canvas.width * 0.03
                    context.stroke(cross, with: .color(Theme.red.opacity(0.45)),
                                   style: StrokeStyle(lineWidth: canvas.width * 0.008, dash: [dash, dash]))
                }
                context.stroke(Path(box), with: .color(Theme.red), lineWidth: canvas.width * 0.022)
            }
            // Brush-written 读, filling ~70% of the cell. Night mode: lantern-cream on night ink.
            Text(verbatim: "读")
                .font(Theme.brush(size * 0.72))
                .foregroundStyle(Theme.ink)
            if showsDetails {
                chop
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "读"))
    }

    /// The 日 chop (from 日课): a seal-red square, brush 日 in cream, slightly rotated, bottom-right.
    private var chop: some View {
        let chopSize = size * 0.18
        return Text(verbatim: "日")
            .font(Theme.brush(chopSize * 0.72))
            .foregroundStyle(Theme.onRed)
            .frame(width: chopSize, height: chopSize)
            .background(Theme.sealRed)
            .clipShape(RoundedRectangle(cornerRadius: chopSize * 0.16))
            .rotationEffect(.degrees(-6))
            .offset(x: size * 0.32, y: size * 0.32)
    }
}

#Preview {
    VStack(spacing: 24) {
        LogoView(size: 160)
        LogoView(size: 32) // small: no cross, no chop
    }
}
