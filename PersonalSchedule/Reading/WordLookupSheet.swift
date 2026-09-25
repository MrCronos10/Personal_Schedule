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

    /// This Word's row, and only it. Fetching every row to answer a question about one would grow
    /// toward 1,900 as the year went on, and would be a second copy of `VocabularyLibrary`'s lookup.
    @Query private var progress: [WordProgress]
    /// The Articles that earned this Word, oldest first. Filtered to the one Word for the same
    /// reason, and watched rather than fetched once so marking the Word Known here updates them.
    @Query private var sightings: [CleanSighting]

    init(word: String) {
        self.word = word
        _progress = Query(filter: #Predicate<WordProgress> { $0.word == word })
        _sightings = Query(
            filter: #Predicate<CleanSighting> { $0.word == word },
            sort: \.dayNumber
        )
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

                earnedIn
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

    /// Where this Word was earned: the Articles read to the end without tapping it.
    ///
    /// A Word with none says so rather than showing an empty space — nothing has gone wrong, there
    /// is simply no evidence yet. A **Lookup** takes these away with the count (ADR 0004), so this
    /// list can never name an Article that no longer counts.
    @ViewBuilder
    private var earnedIn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("读过的文章")
                .font(Theme.label)
                .tracking(1.4)
                .foregroundStyle(Theme.red)

            if sightings.isEmpty {
                Text("还没有读过的文章。")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(sightings) { sighting in
                    // The student's own title, never translated. An Article deleted out from under
                    // a sighting would leave it nameless; Articles are archived rather than deleted,
                    // so this is the belt-and-braces case, not an expected one.
                    Text(verbatim: sighting.article?.title ?? "—")
                        .font(Theme.serif(15))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("HSK 4") {
    WordLookupSheet(word: "厕所")
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}

#Preview("not measured") {
    WordLookupSheet(word: "很")
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
