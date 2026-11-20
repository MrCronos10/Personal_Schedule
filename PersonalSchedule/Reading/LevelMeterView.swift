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

/// 今日新词's own use of the swipe deck: 认识 and 不认识 are the existing `markKnown` / `setAside`.
private struct DailyNewWordsDeck: View {
    @Environment(\.modelContext) private var context
    let words: [HSKEntry]

    var body: some View {
        WordSwipeDeck(words: words) {
            Text("今天的新词看完了")
                .font(Theme.serif(16))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
        } record: { entry, answer in
            let library = VocabularyLibrary(context: context)
            switch answer {
            case .known: return (try? library.markKnown(entry.word)) != nil
            case .notKnown: return (try? library.setAside(entry.word)) != nil
            }
        }
    }
}
