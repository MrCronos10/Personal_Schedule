import SwiftUI

/// A swipe deck of Words, one card at a time: swipe right for 认识, left for 不认识, tap to flip
/// between the Word and its meaning.
///
/// It holds no rule of its own. Whoever shows it says what an answer does, so more than one screen
/// can share the deck without sharing a rule.
struct WordSwipeDeck: View {
    /// The two answers a card can be given.
    enum Answer { case known, notKnown }

    let words: [HSKEntry]
    /// The line shown once every card has been answered.
    let finishedLine: LocalizedStringKey
    /// Handles an answer and says whether it was handled, so the card may advance. A card only flies
    /// off when it was; otherwise it springs back. An answer that writes nothing on purpose still
    /// returns `true`; `false` means a write was meant and failed.
    let record: (HSKEntry, Answer) -> Bool

    /// The session's own fixed list, seeded once. Answering a Word changes what the caller's list would
    /// hold, so indexing the live `words` would skip cards; the deck works from this snapshot and
    /// finishes when it is spent.
    @State private var queue: [HSKEntry] = []
    @State private var index = 0
    @State private var drag: CGSize = .zero
    @State private var flipped = false
    /// True during a card's fly-off, so a second swipe or action can't answer the same Word twice.
    @State private var isAnimating = false
    /// Bumped on every 认识, to fire the one success haptic a Word becoming Known gets elsewhere.
    @State private var knownCount = 0

    /// How far a card must travel before the swipe counts as an answer.
    private let threshold: CGFloat = 110

    var body: some View {
        Group {
            if queue.isEmpty || index >= queue.count {
                Text(finishedLine)
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
            } else {
                deck
            }
        }
        .onAppear { if queue.isEmpty { queue = words } }
        .sensoryFeedback(.success, trigger: knownCount)
    }

    private var deck: some View {
        ZStack {
            // The next Word peeks behind the top one, so the deck reads as a stack — but shows only its
            // character, never its meaning, or every card after the first would give its answer away.
            if index + 1 < queue.count {
                card(queue[index + 1], isTop: false)
                    .scaleEffect(0.96)
                    .offset(y: 10)
                    .opacity(0.5)
            }
            card(queue[index], isTop: true)
                .offset(drag)
                .rotationEffect(.degrees(Double(drag.width / 22)))
                .gesture(
                    DragGesture()
                        .onChanged { if !isAnimating { drag = $0.translation } }
                        .onEnded { ended($0.translation.width) }
                )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: index)
    }

    private func card(_ entry: HSKEntry, isTop: Bool) -> some View {
        VStack(spacing: 12) {
            // The character and its meaning are one VoiceOver element carrying the answer actions and
            // (since the flip can't be seen) the meaning as its value; the speaker stays its own
            // element so it can still be used to hear the Word.
            VStack(spacing: 12) {
                Text(verbatim: entry.word)
                    .font(Theme.serif(34, .black))
                    .foregroundStyle(Theme.ink)
                // Only the top card, once flipped, shows the meaning.
                if isTop {
                    if flipped {
                        // Pinyin and English are the bundled content, not screen text: never translated.
                        Text(verbatim: "\(entry.pinyin) · \(entry.english)")
                            .font(Theme.body)
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("点一下看意思")
                            .font(Theme.meta)
                            .foregroundStyle(Theme.muted)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityHidden(!isTop)
            .accessibilityLabel(Text(verbatim: entry.word))
            .accessibilityValue(Text(verbatim: "\(entry.pinyin) · \(entry.english)"))
            .accessibilityAction(named: Text("认识")) { if isTop { answer(known: true) } }
            .accessibilityAction(named: Text("不认识")) { if isTop { answer(known: false) } }

            if isTop {
                SpeakerButton(text: entry.word)
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        // The hint appears on the side the card is pushed toward: 认识 right, 不认识 left.
        .overlay(alignment: .topTrailing) { hint("认识", Theme.bamboo, show: isTop && drag.width > 24) }
        .overlay(alignment: .topLeading) { hint("不认识", Theme.muted, show: isTop && drag.width < -24) }
        .contentShape(Rectangle())
        .onTapGesture { if isTop && !isAnimating { withAnimation(.easeOut(duration: 0.15)) { flipped.toggle() } } }
    }

    /// The 认识 / 不认识 label that fades in on the side the card is being pushed toward.
    private func hint(_ text: LocalizedStringKey, _ ink: Color, show: Bool) -> some View {
        Text(text)
            .font(Theme.label)
            .tracking(1.4)
            .foregroundStyle(ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(ink))
            .padding(14)
            .opacity(show ? 1 : 0)
    }

    private func ended(_ width: CGFloat) {
        guard !isAnimating else { return }
        if width > threshold {
            answer(known: true)
        } else if width < -threshold {
            answer(known: false)
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { drag = .zero }
        }
    }

    /// Record the answer through the caller, then advance. Guarded against a double answer during
    /// the fly-off, and only advances if it was really written — a card that flies off with nothing
    /// recorded is the silent failure 读完 avoids.
    private func answer(known: Bool) {
        guard !isAnimating, index < queue.count else { return }
        guard record(queue[index], known ? .known : .notKnown) else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { drag = .zero }
            return
        }
        isAnimating = true
        if known { knownCount += 1 }
        withAnimation(.easeOut(duration: 0.2)) {
            drag = CGSize(width: known ? 600 : -600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            index += 1
            drag = .zero
            flipped = false
            isAnimating = false
        }
    }
}
