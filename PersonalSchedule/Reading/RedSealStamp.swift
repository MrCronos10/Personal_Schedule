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

private struct OneShotSuccessHaptic: ViewModifier {
    let shouldFire: Bool
    /// Only ever goes false → true, once, for the lifetime of this view — never back to false, even
    /// after `shouldFire` itself later returns to false. `.sensoryFeedback(trigger:)` plays on every
    /// change of its trigger, so binding it straight to `shouldFire` would fire a second buzz the
    /// moment a temporary "just happened" flag (a stamp shown, then cleared after a timeout) resets —
    /// doubling what was meant to be one light haptic for one moment.
    @State private var hasFired = false

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(.success, trigger: hasFired)
            // Both are needed, for the two different shapes a caller can be in. A view that persists
            // across the transition (a Level's own row, always on screen) sees it via `.onChange`,
            // which never fires for a value already true when the view first appears. A view that is
            // instead freshly mounted at the exact moment `shouldFire` is already true (a stamp
            // inserted into the tree the moment it should show) needs `.onAppear` to catch that case,
            // since there is no earlier value for `.onChange` to compare against.
            .onAppear {
                if shouldFire { hasFired = true }
            }
            .onChange(of: shouldFire) { _, newValue in
                if newValue { hasFired = true }
            }
    }
}

extension View {
    /// Plays a light success haptic exactly once, the first time `shouldFire` becomes true — see
    /// `RedSealStamp`, which this is meant to accompany: a stamp landing, not a badge, so the haptic
    /// that marks it landing should happen exactly as many times as the stamp itself lands.
    func oneShotSuccessHaptic(when shouldFire: Bool) -> some View {
        modifier(OneShotSuccessHaptic(shouldFire: shouldFire))
    }
}
