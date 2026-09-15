import SwiftUI

/// A title where each character sits in its own 田字格 practice box.
struct TianZiGeTitle: View {
    let text: String
    var boxSize: CGFloat = 62

    var body: some View {
        HStack(spacing: -1.5) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                Text(String(character))
                    .font(Theme.serif(boxSize * 0.68, .black))
                    .foregroundStyle(Theme.ink)
                    .frame(width: boxSize, height: boxSize)
                    .background(DashedCross())
                    .overlay(Rectangle().stroke(Theme.red, lineWidth: 1.5))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct DashedCross: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let size = geometry.size
                path.move(to: CGPoint(x: 0, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                path.move(to: CGPoint(x: size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
            }
            .stroke(Theme.rule, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
    }
}

#Preview {
    TianZiGeTitle(text: "今天")
        .padding()
        .background(Theme.paper)
}
