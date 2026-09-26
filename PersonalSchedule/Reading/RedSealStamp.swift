import SwiftUI

/// The stamp that marks a moment already earned: a **Word** turning **Known**, or a **Level** turning
/// **Passed**. Reuses the visual language of the 完 seal on a ticked day — Theme.red, a rounded
/// square, a paper-coloured border, a slight rotation — but lands briefly rather than staying, since
/// this marks a moment rather than a permanent state.
///
/// Not a badge and not a streak (ADR 0004): nothing here is due, nothing accrues, and this view holds
/// no record of its own — whoever shows it is responsible for showing it only once.
struct RedSealStamp: View {
    let character: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    var body: some View {
        Text(verbatim: character)
            .font(Theme.serif(19, .black))
            .foregroundStyle(Theme.paper)
            .frame(width: 36, height: 36)
            .background(Theme.red)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .inset(by: 2.5)
                    .stroke(Theme.paper, lineWidth: 1.5)
            )
            .rotationEffect(.degrees(-8))
            .scaleEffect(isShown ? 1 : 0.4)
            .opacity(isShown ? 1 : 0)
            .accessibilityHidden(true)
            .onAppear {
                // Reduce Motion is honoured by skipping the animation, not by skipping the stamp: it
                // still appears, just without the landing motion.
                if reduceMotion {
                    isShown = true
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        isShown = true
                    }
                }
            }
    }
}

#Preview("landing") {
    RedSealStamp(character: "记")
        .padding(40)
}
