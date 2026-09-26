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

    private var served: HSKLevel { VocabularyLibrary.servedLevel(four: four) }

    var body: some View {
        VStack(spacing: 14) {
            row(four)
            row(five)
        }
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
                Spacer()
                Text(verbatim: "\(progress.known) / \(progress.total)")
                    .font(Theme.meta)
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
    }
}

/// 今日新词: ten unmet Words of the **Served Level**, offered once a day.
///
/// No streak, no count of what is due, no mark for a day skipped. A day not opened leaves nothing
/// behind (ADR 0004).
struct DailyNewWordsView: View {
    @Environment(\.modelContext) private var context

    let words: [HSKEntry]
    /// Whether every Word of the **Served Level** is **Known**. It separates the two empty states:
    /// nothing left to learn, or nothing offerable today because what is left is inside its
    /// thirty-day wait (ADR 0006). Saying "都见过了" for the second would be untrue.
    var isServedLevelComplete: Bool = false
    /// Words answered in this sitting, so the rows settle instead of vanishing under the finger.
    @State private var answered: [String: Bool] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("今日新词")
                .font(Theme.label)
                .tracking(1.4)
                .foregroundStyle(Theme.red)
                .padding(.bottom, 8)

            if words.isEmpty {
                // No count of what is waiting and no date it comes back: a Set Aside Word is never
                // due, and a number here would be the queue ADR 0004 turned down.
                Text(isServedLevelComplete ? "这一级的词都见过了" : "今天没有新词")
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.muted)
            } else if words.allSatisfy({ answered[$0.word] != nil }) {
                Text("今天的新词看完了")
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.muted)
            } else {
                ForEach(words, id: \.word) { entry in
                    row(entry)
                }
            }
        }
        .card()
    }

    @ViewBuilder
    private func row(_ entry: HSKEntry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: entry.word)
                    .font(Theme.serif(19))
                    .foregroundStyle(Theme.ink)
                // Pinyin and English come from the bundled list: they are the content, not screen
                // text, so they are never translated.
                Text(verbatim: "\(entry.pinyin) · \(entry.english)")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Before deciding 认识 or 不认识 is exactly the moment a student most needs to hear an
            // unfamiliar Word, not after.
            SpeakerButton(text: entry.word)
                .foregroundStyle(Theme.muted)

            if let known = answered[entry.word] {
                Chip(
                    text: known ? "认识" : "不认识",
                    ink: known ? Theme.onDone : Theme.muted,
                    ground: known ? Theme.done : Theme.cardHigh
                )
            } else {
                HStack(spacing: 6) {
                    Button("不认识") {
                        // Settle the row only if it was really written: a row that says 不认识 with
                        // nothing recorded is the silent failure 读完 goes out of its way to avoid.
                        if (try? VocabularyLibrary(context: context)
                            .setAside(entry.word)) != nil {
                            answered[entry.word] = false
                        }
                    }
                    .buttonStyle(MiniButtonStyle())
                    Button("认识") {
                        if (try? VocabularyLibrary(context: context).markKnown(entry.word)) != nil {
                            answered[entry.word] = true
                        }
                    }
                    .buttonStyle(MiniButtonStyle())
                }
            }
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
    }
}
