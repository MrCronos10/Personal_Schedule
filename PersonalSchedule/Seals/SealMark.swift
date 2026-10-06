import SwiftUI

/// One earned seal: a red square with its characters in brush, stamped at a slight tilt. A rare seal
/// is ringed in brass. When `animated`, it lands the way the 读完 stamp does: from a little larger,
/// 250 ms, then still. Reduce Motion fades it in instead.
struct SealMark: View {
    let seal: Seal
    var size: CGFloat = 60
    var animated = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var landed: Bool

    init(seal: Seal, size: CGFloat = 60, animated: Bool = false) {
        self.seal = seal
        self.size = size
        self.animated = animated
        _landed = State(initialValue: !animated)
    }

    private var fontSize: CGFloat {
        switch seal.glyph.count {
        case 1, 2: size * 0.42
        default: size * 0.31
        }
    }

    var body: some View {
        ZStack {
            if seal.isRare {
                Circle()
                    .stroke(Theme.brass, lineWidth: 3)
                    .frame(width: size * 1.28, height: size * 1.28)
            }
            Text(verbatim: seal.glyph)
                .font(Theme.brush(fontSize))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(Theme.onRed)
                .frame(width: size, height: size)
                .background(Theme.red)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.09))
                .rotationEffect(.degrees(seal.tilt))
        }
        .frame(width: size * 1.3, height: size * 1.3)
        .scaleEffect(reduceMotion || landed ? 1 : 1.3)
        .opacity(landed ? 1 : 0)
        .accessibilityHidden(true)
        // Reduce Motion keeps the fade and drops the scale (the `scaleEffect` above ignores `landed`).
        .onAppear {
            guard animated else { return }
            withAnimation(.easeOut(duration: 0.25)) { landed = true }
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        SealMark(seal: .firstRead)
        SealMark(seal: .fiftyArticles)
        SealMark(seal: .passedLevel)
    }
    .padding(24)
    .background(Theme.lacquer)
}
