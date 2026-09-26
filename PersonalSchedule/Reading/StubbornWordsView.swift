import SwiftData
import SwiftUI

/// 难词: the **Words** the student's own history says keep beating them, read back from **Lookups**
/// that have been recorded since ticket 15 and shown nowhere until this screen.
///
/// Nothing here is due. No count on the tab that opens this, no nag, no "review these" button: a
/// Word leaves the moment it turns **Known**, and a day this screen is never opened leaves nothing
/// behind, the same as everywhere else in reading (ADR 0004).
struct StubbornWordsView: View {
    @Environment(\.modelContext) private var context
    /// Watched so the list follows a Lookup made anywhere, or a Word turning Known anywhere — not
    /// fetched once, since the whole point is a Word leaving the moment it stops being stubborn.
    @Query private var progressRows: [WordProgress]
    @Query private var lookupRows: [WordLookup]

    @State private var words: [VocabularyLibrary.StubbornWord] = []
    /// Reuses `ArticleReaderView`'s `LookedUpWord` rather than a second `Identifiable` wrapper for
    /// the same job — no Article just cleared anything here, so `clearedArticles` stays empty.
    @State private var openedWord: LookedUpWord?

    /// Changes on a new Lookup, a Word turning Known, or a row appearing at all — the three things
    /// `stubbornWords()` can answer differently about. The same hashed-count trick `ReadingView`
    /// already uses, so one signature change runs `refresh()` once rather than watching each field.
    private var signature: Int {
        lookupRows.count &* 97 &+ progressRows.count &* 31 &+ progressRows.count { $0.isKnown }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if words.isEmpty {
                    emptyState
                        .card()
                } else {
                    VStack(spacing: 0) {
                        ForEach(words, id: \.entry.word) { stubborn in
                            row(stubborn)
                        }
                    }
                    .card()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Theme.paper)
        .navigationTitle(Text("难词"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { refresh() }
        .onChange(of: signature) { refresh() }
        .sheet(item: $openedWord) { looked in
            WordLookupSheet(word: looked.text)
                .presentationDetents([.medium])
        }
    }

    private func refresh() {
        words = (try? VocabularyLibrary(context: context).stubbornWords()) ?? []
    }

    private func row(_ stubborn: VocabularyLibrary.StubbornWord) -> some View {
        Button {
            openedWord = LookedUpWord(text: stubborn.entry.word)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: stubborn.entry.word)
                        .font(Theme.serif(19))
                        .foregroundStyle(Theme.ink)
                    // Pinyin and English come from the bundled list: the content, never translated.
                    Text(verbatim: "\(stubborn.entry.pinyin) · \(stubborn.entry.english)")
                        .font(Theme.meta)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(stubborn.articleCount) 篇文章里查过")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.muted)
            }
            .padding(.vertical, 11)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.rule).frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// No Stubborn Words is good news, not a blank screen — the quiet voice the rest of the app uses.
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("没有难词")
                .font(Theme.serif(16))
                .foregroundStyle(Theme.muted)
            Text("在两篇及以上的文章里查过、还没记住的词会出现在这里。")
                .font(Theme.meta)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("some stubborn words") {
    let container = try! ScheduleStore.makeContainer(inMemory: true)
    let context = ModelContext(container)
    let articles = ArticleLibrary(context: context)
    let vocabulary = VocabularyLibrary(context: context)
    let first = try! articles.add(text: "第一篇\n正文")
    let second = try! articles.add(text: "第二篇\n正文")
    try! vocabulary.lookUp("厕所", in: first)
    try! vocabulary.lookUp("厕所", in: second)
    return NavigationStack { StubbornWordsView() }
        .modelContainer(container)
}

#Preview("empty") {
    NavigationStack { StubbornWordsView() }
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
