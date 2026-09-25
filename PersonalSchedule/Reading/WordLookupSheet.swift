import SwiftData
import SwiftUI

/// What a tapped word means: the word, its pinyin, its English.
///
/// A word the app doesn't measure — HSK 1-3, a name, a number — gets a quiet line rather than an
/// error. Nothing has gone wrong; there is simply nothing recorded for it (ADR 0005).
struct WordLookupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let word: String
    /// The Articles the **Lookup** that opened this sheet just cleared, if any. Handed in rather
    /// than queried: the Lookup deletes them before this sheet can draw.
    let clearedArticles: [String]

    /// This Word's row, and only it. Fetching every row to answer a question about one would grow
    /// toward 1,900 as the year went on, and would be a second copy of `VocabularyLibrary`'s lookup.
    @Query private var progress: [WordProgress]

    init(word: String, clearedArticles: [String] = []) {
        self.word = word
        self.clearedArticles = clearedArticles
        _progress = Query(filter: #Predicate<WordProgress> { $0.word == word })
    }

    private var entry: HSKEntry? { HSKWordList.entry(for: word) }

    private var isKnown: Bool { progress.first?.isKnown ?? false }

    var body: some View {
        // A long gloss at a large Dynamic Type size would otherwise push 我认识这个词 past the bottom
        // of the sheet, where it can't be reached and the Word can never be marked Known.
        ScrollView {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: word)
                .font(Theme.serif(40, .black))
                .foregroundStyle(Theme.ink)

            if let entry {
                Text(verbatim: entry.pinyin)
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.red)
                    .padding(.top, 6)
                // The English is the content, not screen text, so it is never translated.
                Text(verbatim: entry.english)
                    .font(Theme.body)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)

                clearedByThisLookup
                    .padding(.top, 18)

                Spacer(minLength: 16)

                if isKnown {
                    Button("其实不认识") {
                        try? VocabularyLibrary(context: context).markNotKnown(word)
                        dismiss()
                    }
                    .buttonStyle(MiniButtonStyle())
                } else {
                    Button("我认识这个词") {
                        try? VocabularyLibrary(context: context).markKnown(word)
                        dismiss()
                    }
                    .buttonStyle(MiniButtonStyle())
                }
            } else {
                Text("这个词不在 HSK 4-5 里，不计入掌握。")
                    .font(Theme.body)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                Spacer(minLength: 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(24)
        }
        .background(Theme.paper)
    }

    /// What this tap cost: the Articles whose **Clean Sightings** the **Lookup** just cleared, which
    /// have to be read again before the Word can be **Known** (ADR 0004).
    ///
    /// Said quietly and only when something was actually cleared. This is the one place the student
    /// finds out that asking for help has a price, and the app does not scold them for asking: the
    /// line says what to do next, not what they did wrong. A Word with nothing behind it — much the
    /// commonest tap — shows nothing here at all, because there is nothing to say.
    @ViewBuilder
    private var clearedByThisLookup: some View {
        if !clearedArticles.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("这些文章要重新读")
                    .font(Theme.label)
                    .tracking(1.4)
                    .foregroundStyle(Theme.muted)

                ForEach(clearedArticles, id: \.self) { title in
                    // The student's own title, never translated.
                    Text(verbatim: title)
                        .font(Theme.serif(15))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("cleared two Articles") {
    WordLookupSheet(word: "厕所", clearedArticles: ["茶馆菜单", "微信：杭州的秋天"])
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}

#Preview("HSK 4") {
    WordLookupSheet(word: "厕所")
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}

#Preview("not measured") {
    WordLookupSheet(word: "很")
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
