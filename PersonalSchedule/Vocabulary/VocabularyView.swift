import SwiftData
import SwiftUI

/// The 词 tab, as three shelves (ADR 0009): 难词 on top, because it is the do-today list; the HSK
/// Levels with 今日新词 in the middle, a place to see progress; and 农业词, a topic collection. Each
/// shelf has its own weight on purpose — they are different jobs, not three tabs of one list.
struct VocabularyView: View {
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var context

    /// Watched so the meter and the daily list follow what reading and 今日新词 change.
    @Query private var progressRows: [WordProgress]
    @Query private var lookupRows: [WordLookup]
    @Query private var topicRows: [TopicWordProgress]
    @Environment(AppRouter.self) private var router: AppRouter?

    /// One value covering both "a Word was met" and "a Word became Known", so a single tap runs
    /// `refresh()` once rather than twice.
    private var progressSignature: Int {
        var value = progressRows.count &* 31 &+ progressRows.count { $0.isKnown }
        value = value &* 31 &+ lookupRows.count
        value = value &* 31 &+ topicRows.count { $0.isKnown }
        return value
    }

    /// Worked out when the tab appears and after a Word is answered, rather than on every render:
    /// a Level counts Known Words against the whole 600 or 1,300.
    @State private var four = LevelProgress(level: .four, known: 0)
    @State private var five = LevelProgress(level: .five, known: 0)
    @State private var dailyWords: [HSKEntry] = []
    /// Whether the Served Level has nothing left to learn, which is what tells 今日新词 apart from
    /// a day when everything left is inside its thirty-day wait (ADR 0006).
    @State private var servedLevelIsComplete = false
    /// The Levels whose **Passed** stamp should land right now — a `Set`, not one optional value,
    /// because HSK 4 and HSK 5 can both cross Passed in the same `refresh()`: a single overwritten
    /// value would mark the first congratulated and then silently lose its stamp before SwiftUI ever
    /// rendered it. Each Level is added once and removed a couple of seconds later on its own.
    @State private var justPassedLevels: Set<HSKLevel> = []
    @State private var fourCells: [CollectionCell] = []
    @State private var fiveCells: [CollectionCell] = []
    @State private var topicCells: [CollectionCell] = []
    @State private var topicMeter = TopicMeter(known: 0, total: 0)
    @State private var stubborn: [VocabularyLibrary.StubbornWord] = []
    @State private var openedWord: LookedUpWord?

    private var isChinese: Bool { locale.language.languageCode == .chinese }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    title
                        .padding(.top, 14)

                    stubbornShelf
                    levelsShelf
                    topicShelf
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(BackgroundView())
            .toolbar(.hidden, for: .navigationBar)
            .task { refresh() }
            .onChange(of: progressSignature) { refresh() }
            // Only a 今日新词 row's own sound: a Word opened from this tab can outlive it (a pushed
            // StubbornWordsView, a Word sheet), and leaving must not silence those either.
            .onDisappear {
                if let current = SpeechPlayer.shared.currentText, dailyWords.map(\.word).contains(current) {
                    SpeechPlayer.shared.stop()
                }
            }
            .sheet(item: $openedWord) { looked in
                WordLookupSheet(word: looked.text)
                    .presentationDetents([.medium])
            }
        }
    }

    private func refresh() {
        let library = VocabularyLibrary(context: context)
        four = (try? library.level(.four)) ?? LevelProgress(level: .four, known: 0)
        five = (try? library.level(.five)) ?? LevelProgress(level: .five, known: 0)
        dailyWords = (try? library.dailyNewWords()) ?? []
        let collection = CollectionLibrary(context: context)
        fourCells = (try? collection.cells(for: .four, limit: 20)) ?? []
        fiveCells = (try? collection.cells(for: .five, limit: 20)) ?? []
        topicCells = Array(((try? collection.topicCells()) ?? []).prefix(20))
        topicMeter = (try? TopicLibrary(context: context).meter()) ?? TopicMeter(known: 0, total: 0)
        stubborn = (try? library.stubbornWords()) ?? []
        let served = VocabularyLibrary.servedLevel(four: four)
        let servedProgress = served == .four ? four : five
        servedLevelIsComplete = servedProgress.known >= servedProgress.total

        // The Level stamp waits for this tab (ticket 08): wherever a Word actually turned Known,
        // only here is Passed ever detected and marked congratulated, so passing while reading or
        // inside a Word sheet never interrupts either of those screens.
        //
        // Both Levels can cross Passed in the same refresh — reading one Article can bank enough
        // Words to finish HSK 4 and, via Served Level moving on, still leave HSK 5 already sitting
        // past four fifths from Words met along the way. Each is added to the set on its own rather
        // than assigned to a single value, so the second can never silently overwrite the first
        // before SwiftUI has rendered it.
        for progress in [four, five] where progress.isPassed {
            guard let alreadyCongratulated = try? library.hasCongratulated(progress.level),
                  !alreadyCongratulated
            else { continue }
            try? library.markCongratulated(progress.level)
            let level = progress.level
            justPassedLevels.insert(level)
            Task {
                try? await Task.sleep(for: .seconds(2))
                justPassedLevels.remove(level)
            }
        }
    }

    /// 词 in a 田字格 box, the same practice-book heading the other tabs use.
    @ViewBuilder
    private var title: some View {
        if isChinese {
            TianZiGeTitle(text: "词")
        } else {
            Text("词")
                .font(Theme.serif(34, .black))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Shelves

    /// The do-today shelf. Five at most; the whole list is one tap on. A number on a badge would be
    /// the queue ADR 0004 turned down, so there is none — an empty shelf says so in words.
    private var stubbornShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(verbatim: "难")
                    .font(Theme.serif(13, .black))
                    .foregroundStyle(Theme.onRed)
                    .frame(width: 22, height: 22)
                    .background(Theme.sealRed)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .accessibilityHidden(true)
                Text("难词")
                    .font(Theme.title)
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                NavigationLink {
                    StubbornWordsView()
                } label: {
                    HStack(spacing: 4) {
                        Text("全部")
                        Image(systemName: "chevron.right")
                    }
                    .font(Theme.label)
                    .tracking(1.4)
                    .foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 22)

            if stubborn.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("没有难词")
                        .font(Theme.serif(16))
                        .foregroundStyle(Theme.muted)
                    Text("在两篇及以上的文章里查过、还没记住的词会出现在这里。")
                        .font(Theme.meta)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .card()
            } else {
                VStack(spacing: 0) {
                    ForEach(stubborn.prefix(5), id: \.entry.word) { word in
                        StubbornWordRow(stubborn: word) {
                            openedWord = LookedUpWord(text: word.entry.word)
                        }
                    }
                }
                .card()
            }
        }
    }

    /// Progress shelf: one card per Level, each opening Progress at its section, and 今日新词 under
    /// them because it draws from the Served Level.
    private var levelsShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: "HSK")
                .font(Theme.title)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 26)
            LevelMeterView(
                four: four, five: five, justPassedLevels: justPassedLevels,
                fourCells: fourCells, fiveCells: fiveCells,
                onOpen: { router?.showProgress(at: $0) }
            )
            DailyNewWordsView(words: dailyWords, isServedLevelComplete: servedLevelIsComplete)
        }
    }

    /// The topic collection. Its card opens the Topic List itself, where words are marked and added;
    /// the grid for it is on Progress (the Level cards go there directly).
    private var topicShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("农业词")
                .font(Theme.title)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 26)
            NavigationLink {
                TopicListView()
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("已认识")
                            .font(Theme.serif(18))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(verbatim: "\(topicMeter.known) / \(topicMeter.total)")
                            .font(Theme.mono(12))
                            .foregroundStyle(Theme.muted)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                    }
                    CollectionSliver(cells: Array(topicCells.prefix(20)))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .card()
        }
    }
}

#Preview {
    VocabularyView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
