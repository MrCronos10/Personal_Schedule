import SwiftData
import SwiftUI

/// The 词 tab: the Level meter, 今日新词, and the doors to 难词 and 农业词 — everything about words,
/// apart from the Articles they are met in (those stay on 阅读). ADR 0009.
struct VocabularyView: View {
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var context

    /// Watched so the meter and the daily list follow what reading and 今日新词 change.
    @Query private var progressRows: [WordProgress]

    /// One value covering both "a Word was met" and "a Word became Known", so a single tap runs
    /// `refresh()` once rather than twice.
    private var progressSignature: Int {
        progressRows.count &* 31 &+ progressRows.count { $0.isKnown }
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

    private var isChinese: Bool { locale.language.languageCode == .chinese }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    title
                        .padding(.top, 14)

                    LevelMeterView(four: four, five: five, justPassedLevels: justPassedLevels)
                        .padding(.top, 16)

                    DailyNewWordsView(words: dailyWords, isServedLevelComplete: servedLevelIsComplete)
                        .padding(.top, 10)

                    HStack(spacing: 20) {
                        stubbornWordsLink
                        topicListLink
                    }
                    .padding(.top, 14)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Theme.paper)
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

    /// The **Topic List** entry point: 农业词 sits beside 难词 rather than at the tab bar's root.
    /// iPhones show only four tabs plus a "More" bucket, so a sixth top-level tab (as ticket 11
    /// first placed it) hid 设置 behind "More" and the Reading Coach's API key with it (ADR 0007
    /// update). The Topic List is a word list, so it belongs where the HSK word lists already are.
    private var topicListLink: some View {
        NavigationLink {
            TopicListView()
        } label: {
            HStack(spacing: 4) {
                Text("农业词")
                Image(systemName: "chevron.right")
            }
            .font(Theme.label)
            .tracking(1.4)
            .foregroundStyle(Theme.muted)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VocabularyView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
