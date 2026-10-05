import SwiftData
import SwiftUI

/// The year's headline number: how many **Words** of each **Level** are **Known**.
///
/// Counted against the whole **Word List**, so it only ever goes up. **Passed** at four fifths, and
/// passing decides one thing — which Level **Daily New Words** come from. No Article is ever locked
/// (ADR 0005).
struct LevelMeterView: View {
    let four: LevelProgress
    let five: LevelProgress
    /// The Levels whose **Passed** stamp should land right now (ticket 08). Both can be present at
    /// once — HSK 4 and HSK 5 can cross Passed in the same `refresh()` — and each is a moment, not a
    /// standing state: `VocabularyView` removes a Level a couple of seconds after adding it.
    var justPassedLevels: Set<HSKLevel> = []
    /// The Collection Grid cells of each Level, for the sliver under the bar.
    var fourCells: [CollectionCell] = []
    var fiveCells: [CollectionCell] = []
    /// Tapping a card opens Progress at that Level's section.
    var onOpen: (CollectionSection) -> Void = { _ in }

    private var served: HSKLevel { VocabularyLibrary.servedLevel(four: four) }

    var body: some View {
        VStack(spacing: 10) {
            levelCard(four, cells: fourCells, section: .four)
            levelCard(five, cells: fiveCells, section: .five)
        }
    }

    private func levelCard(_ progress: LevelProgress, cells: [CollectionCell], section: CollectionSection) -> some View {
        Button { onOpen(section) } label: {
            VStack(alignment: .leading, spacing: 10) {
                row(progress)
                // The first twenty cells of the Level's grid section, in list order.
                CollectionSliver(cells: Array(cells.prefix(20)))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .card()
    }

    @ViewBuilder
    private func row(_ progress: LevelProgress) -> some View {
        let isServed = progress.level == served || progress.known > 0
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // The list's name, not an exam. See Goal in CONTEXT.md.
                Text(verbatim: progress.level == .four ? "HSK 4" : "HSK 5")
                    .font(Theme.serif(18))
                    .foregroundStyle(Theme.ink)
                if progress.isPassed {
                    Chip(text: "已过", ink: Theme.onDone, ground: Theme.done)
                }
                if justPassedLevels.contains(progress.level) {
                    RedSealStamp(character: "过")
                }
                Spacer()
                Text(verbatim: "\(progress.known) / \(progress.total)")
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.muted)
                Text(verbatim: "· \(Int(progress.share * 100))%")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.muted)
            }

            // The same red ink on paper the 进度 tab uses. No new colour, no new component.
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Theme.rule.opacity(0.5))
                    Rectangle()
                        .fill(Theme.red)
                        .frame(width: max(0, geometry.size.width * progress.share))
                }
            }
            .frame(height: 6)
            .clipShape(RoundedRectangle(cornerRadius: 3))

            // Not a lock, and no lock icon: the Level that isn't served yet still counts every Word
            // of it that turns up in something the student reads.
            if progress.level != served && !progress.isPassed {
                Text("HSK 4 掌握八成后开始")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.muted)
            }
        }
        .opacity(isServed || progress.level == served ? 1 : 0.55)
        // On the row itself, which always exists for this Level, rather than on the stamp — the
        // stamp is only ever freshly mounted the moment it appears, and a trigger attached to a
        // freshly-mounted view isn't guaranteed to see its initial value as a change. One-shot,
        // because `justPassedLevels` removes the Level again after its couple of seconds on screen,
        // and a plain `.sensoryFeedback` bound to that would buzz a second time on the way out.
        .oneShotSuccessHaptic(when: justPassedLevels.contains(progress.level))
    }
}

/// 今日新词: ten unmet Words of the **Served Level**, offered once a day as a swipe deck — swipe right
/// for 认识, left for 不认识, tap to flip between the Word and its meaning.
///
/// No streak, no count of what is due, no mark for a day skipped. A day not opened leaves nothing
/// behind (ADR 0004). The deck only ever calls the existing 认识 / 不认识 rules (`markKnown` /
/// `setAside`); it adds no new one.
struct DailyNewWordsView: View {
    let words: [HSKEntry]
    /// Whether every Word of the **Served Level** is **Known**. It separates the two empty states:
    /// nothing left to learn, or nothing offerable today because what is left is inside its
    /// thirty-day wait (ADR 0006). Saying "都见过了" for the second would be untrue.
    var isServedLevelComplete: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日新词")
                .font(Theme.label)
                .tracking(1.4)
                .foregroundStyle(Theme.red)

            if words.isEmpty {
                // No count of what is waiting and no date it comes back: a Set Aside Word is never
                // due, and a number here would be the queue ADR 0004 turned down.
                Text(isServedLevelComplete ? "这一级的词都见过了" : "今天没有新词")
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
            } else {
                DailyNewWordsDeck(words: words)
            }
        }
    }
}

/// The swipe deck itself: one card at a time off the top of the day's Words.
private struct DailyNewWordsDeck: View {
    @Environment(\.modelContext) private var context
    let words: [HSKEntry]

    /// The session's own fixed list, seeded once. Answering a Word changes what `dailyNewWords` would
    /// return, so indexing the live `words` would skip cards; the deck works from this snapshot and
    /// finishes when it is spent.
    @State private var queue: [HSKEntry] = []
    @State private var index = 0
    @State private var drag: CGSize = .zero
    @State private var flipped = false
    /// True during a card's fly-off, so a second swipe or action can't answer the same Word twice.
    @State private var isAnimating = false
    /// Bumped on every 认识, to fire the one success haptic a mastery moment gets elsewhere.
    @State private var knownCount = 0

    /// How far a card must travel before the swipe counts as an answer.
    private let threshold: CGFloat = 110

    var body: some View {
        Group {
            if queue.isEmpty || index >= queue.count {
                Text("今天的新词看完了")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: queue[index].word))
        // The meaning is read here, since a VoiceOver user can't do the visual flip to see it.
        .accessibilityValue(Text(verbatim: "\(queue[index].pinyin) · \(queue[index].english)"))
        // Swipe is inaccessible on its own, so VoiceOver answers through named actions.
        .accessibilityAction(named: Text("认识")) { answer(known: true) }
        .accessibilityAction(named: Text("不认识")) { answer(known: false) }
    }

    private func card(_ entry: HSKEntry, isTop: Bool) -> some View {
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
                SpeakerButton(text: entry.word)
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(alignment: .topLeading) { hint("认识", Theme.bamboo, show: isTop && drag.width > 24) }
        .overlay(alignment: .topTrailing) { hint("不认识", Theme.muted, show: isTop && drag.width < -24) }
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

    /// Record the answer with the existing rule, then advance. Guarded against a double answer during
    /// the fly-off, and only advances if it was really written — a card that flies off with nothing
    /// recorded is the silent failure 读完 avoids.
    private func answer(known: Bool) {
        guard !isAnimating, index < queue.count else { return }
        let entry = queue[index]
        let library = VocabularyLibrary(context: context)
        let wrote = known
            ? ((try? library.markKnown(entry.word)) != nil)
            : ((try? library.setAside(entry.word)) != nil)
        guard wrote else {
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
