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

    /// Seeded from `progress` once the sheet appears, then edited locally: a **Word Note** saves as
    /// it is typed, and re-seeding it from a live query on every keystroke would fight the cursor.
    @State private var noteDraft = ""

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
            // Placed by the word itself rather than only by the pinyin below it, so an unmeasured
            // word — a name, a number, anything outside HSK 4/5 — can still be heard: hearing
            // something is not a measurement (ADR 0005), and this is the one line every word has.
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(verbatim: word)
                    .font(Theme.serif(40, .black))
                    .foregroundStyle(Theme.ink)
                SpeakerButton(text: word)
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.red)
            }

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

                wordNoteField
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
        // Seeded once per Word, not on every re-render: `progress` is a live @Query, and re-seeding
        // the draft from it on every keystroke's own save would fight the cursor mid-type.
        .task(id: word) { noteDraft = progress.first?.noteText ?? "" }
        // Only stops this Word's own sound: an Article can be narrating underneath this sheet, and
        // dismissing the sheet must not silence it.
        .onDisappear { SpeechPlayer.shared.stop(ifPlaying: word) }
    }

    /// A memory trick for this Word, saved as it is typed. It belongs to the Word, not to a day, so
    /// it is never shown in the **Notes List** — that screen is about **Completions**.
    private var wordNoteField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("记忆点")
                .font(Theme.label)
                .tracking(1.4)
                .foregroundStyle(Theme.red)
            TextField("怎么记住这个词…", text: $noteDraft, axis: .vertical)
                .font(Theme.body)
                .lineLimit(2...4)
                .onChange(of: noteDraft) { _, newValue in
                    // `.task(id: word)` seeds this same field from the stored Note, which is itself
                    // a change `onChange` sees — without this guard, opening a Word that already has
                    // one would write it straight back on every single tap, having changed nothing.
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmed != (progress.first?.noteText ?? "") else { return }
                    try? VocabularyLibrary(context: context).setNote(newValue, for: word)
                }
        }
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
