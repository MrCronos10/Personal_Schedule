import SwiftData
import SwiftUI

/// The 阅读 tab: the student's **Articles**, newest first, with a **+** to import one.
///
/// The Level meter (ticket 18) and 今日新词 (ticket 19) belong above the list. The space is left
/// empty for them rather than filled with a placeholder.
struct ReadingView: View {
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var context

    @Query(ArticleLibrary.readingDescriptor) private var reading: [Article]
    @Query(ArticleLibrary.archivedDescriptor) private var archived: [Article]
    /// Watched so the meter, the daily list, and every Article row's **Readability** follow what
    /// reading and 今日新词 change.
    @Query private var progressRows: [WordProgress]

    /// Handed to each row rather than looked up per row: one pass over what is Known, not one query
    /// per Article in the list.
    private var knownWords: Set<String> {
        Set(progressRows.filter(\.isKnown).map(\.word))
    }

    /// One value covering both "a Word was met" and "a Word became Known", so a single tap runs
    /// `refresh()` once rather than twice.
    private var progressSignature: Int {
        progressRows.count &* 31 &+ progressRows.count { $0.isKnown }
    }

    @State private var isImporting = false
    @State private var isShowingArchived = false
    /// Worked out when the tab appears and after a Word is answered, rather than on every render:
    /// a Level counts Known Words against the whole 600 or 1,300.
    @State private var four = LevelProgress(level: .four, known: 0)
    @State private var five = LevelProgress(level: .five, known: 0)
    @State private var dailyWords: [HSKEntry] = []
    /// Whether the Served Level has nothing left to learn, which is what tells 今日新词 apart from
    /// a day when everything left is inside its thirty-day wait (ADR 0006).
    @State private var servedLevelIsComplete = false

    private var isChinese: Bool { locale.language.languageCode == .chinese }

    var body: some View {
        NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("\(reading.count) 篇文章")
                        .font(.system(size: 13))
                        .tracking(1)
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    Button { isImporting = true } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(RedButtonStyle())
                    .accessibilityLabel(Text("导入文章"))
                }
                .padding(.top, 12)

                title
                    .padding(.top, 14)

                LevelMeterView(four: four, five: five)
                    .padding(.top, 16)

                DailyNewWordsView(words: dailyWords, isServedLevelComplete: servedLevelIsComplete)
                    .padding(.top, 10)

                stubbornWordsLink
                    .padding(.top, 14)

                SectionCaption(title: "我的文章")

                if reading.isEmpty {
                    emptyReadingList
                        .card()
                        .padding(.top, 10)
                } else {
                    VStack(spacing: 0) {
                        ForEach(reading) { article in
                            ArticleRow(article: article, knownWords: knownWords) {
                                try? ArticleLibrary(context: context).archive(article)
                            }
                        }
                    }
                    .card()
                    .padding(.top, 10)
                }

                archivedSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.paper)
        .toolbar(.hidden, for: .navigationBar)
        .task { refresh() }
        .onChange(of: progressSignature) { refresh() }
        // Only a 今日新词 row's own sound: a Word or Article opened from this tab can outlive it
        // (a pushed StubbornWordsView, a Word sheet), and leaving must not silence those either.
        .onDisappear {
            if let current = SpeechPlayer.shared.currentText, dailyWords.map(\.word).contains(current) {
                SpeechPlayer.shared.stop()
            }
        }
        .sheet(isPresented: $isImporting) {
            ArticleImportView()
        }
        .navigationDestination(for: Article.self) { article in
            ArticleReaderView(article: article)
        }
        }
    }

    private func refresh() {
        let library = VocabularyLibrary(context: context)
        four = (try? library.level(.four)) ?? LevelProgress(level: .four, known: 0)
        five = (try? library.level(.five)) ?? LevelProgress(level: .five, known: 0)
        dailyWords = (try? library.dailyNewWords()) ?? []
        let served = VocabularyLibrary.servedLevel(four: four)
        let servedProgress = served == .four ? four : five
        servedLevelIsComplete = servedProgress.known >= servedProgress.total
    }

    /// 阅读 in 田字格 boxes, the same practice-book heading 今天 and 进度 use.
    @ViewBuilder
    private var title: some View {
        if isChinese {
            TianZiGeTitle(text: "阅读")
        } else {
            Text("阅读")
                .font(Theme.serif(34, .black))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// Always here, whether or not anything is on it: 难词 with nothing on it is good news, and the
    /// entry point saying so is what makes that visible rather than hidden. No count, no badge — a
    /// number here would be the queue ADR 0004 turned down.
    private var stubbornWordsLink: some View {
        NavigationLink {
            StubbornWordsView()
        } label: {
            HStack(spacing: 4) {
                Text("难词")
                Image(systemName: "chevron.right")
            }
            .font(Theme.label)
            .tracking(1.4)
            .foregroundStyle(Theme.muted)
        }
        .buttonStyle(.plain)
    }

    /// The quiet voice the Daily Checklist already uses: a sentence and a way forward.
    private var emptyReadingList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("还没有文章")
                .font(Theme.serif(16))
                .foregroundStyle(Theme.muted)
            Text("把你遇到的中文贴进来：微信文章、菜单、路牌都行。")
                .font(Theme.meta)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var archivedSection: some View {
        if !archived.isEmpty || isShowingArchived {
            Button {
                isShowingArchived.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text("已归档")
                    Image(systemName: isShowingArchived ? "chevron.up" : "chevron.down")
                }
                .font(Theme.label)
                .tracking(1.4)
                .foregroundStyle(Theme.muted)
            }
            .buttonStyle(.plain)
            .padding(.top, 22)

            if isShowingArchived {
                Group {
                    if archived.isEmpty {
                        Text("没有已归档的文章")
                            .font(Theme.serif(16))
                            .foregroundStyle(Theme.muted)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(archived) { article in
                                ArticleRow(article: article, knownWords: knownWords, isArchived: true) {
                                    try? ArticleLibrary(context: context).restore(article)
                                }
                            }
                        }
                    }
                }
                .card()
                .padding(.top, 10)
            }
        }
    }
}

/// One Article in the reading list. Tapping it opens the reader; 归档 keeps its own tap.
struct ArticleRow: View {
    @Environment(\.locale) private var locale

    let article: Article
    /// Handed in from the list rather than queried per row: one pass over **Known** Words for the
    /// whole list, not one query per Article.
    let knownWords: Set<String>
    var isArchived: Bool = false
    let onArchiveAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Only the text column is the link. A Button inside a NavigationLink's label is not
            // hit-tested separately outside a List, so nesting 归档 in there would archive nothing
            // and push the reader instead.
            if isArchived {
                textColumn
            } else {
                NavigationLink(value: article) { textColumn }
                    .buttonStyle(.plain)
            }

            Button(isArchived ? "恢复" : "归档", action: onArchiveAction)
                .buttonStyle(MiniButtonStyle())
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
    }

    private var textColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
                // The student's own writing, and the title taken from it: never translated.
                Text(verbatim: article.title)
                    .font(Theme.serif(18))
                    .foregroundStyle(isArchived ? Theme.muted : Theme.ink)
                HStack(spacing: 0) {
                    if let source = article.source {
                        Text(verbatim: source)
                        Text(verbatim: " · ")
                    }
                    Text(verbatim: importedDayText)
                    // Readability: information, never a gate (ADR 0005). Nothing here orders,
                    // greys, badges or hides an Article — it only says what share is already Known,
                    // the same way LevelMeterView already words a share.
                    if let readability = article.readability(known: knownWords) {
                        Text(verbatim: " · \(Int(readability * 100))%")
                    }
                }
                .font(Theme.meta)
                .foregroundStyle(Theme.muted)
                Text(verbatim: preview)
                    .font(Theme.meta)
                    .foregroundStyle(Theme.muted.opacity(0.75))
                    .lineLimit(2)
                // What this reading proved, for as long as the Article is kept. An Article never
                // finished has no result and shows nothing here rather than a row of zeros.
                if let result = article.bankedResult {
                    BankedResultLine(result: result)
                        .padding(.top, 2)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var importedDayText: String {
        article.importedDay.date().formatted(.dateTime.month().day().locale(locale))
    }

    /// The opening of the article, with the line the title came from taken off, so the list doesn't
    /// read the same words twice.
    private var preview: String {
        let lines = article.text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return lines.dropFirst().joined(separator: " ")
    }
}

#Preview {
    ReadingView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
