import SwiftData
import SwiftUI

/// Reading one **Article**. The text is shown as it was written, with HSK 4/5 **Words** underlined,
/// and tapping any word says what it means.
///
/// This is the one screen in the app made for reading, so it gets the room: no chips, no meta, no
/// controls in the way of the text.
struct ArticleReaderView: View {
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    let article: Article

    @Query(DayPlan.descriptor) private var candidateActions: [Action]
    @Query(CompletionLibrary.allDescriptor) private var allCompletions: [Completion]

    /// Only the **Known** Words: the screen needs them to leave their underline off, and nothing
    /// else. Fetching every row would grow toward 1,900 as the year went on.
    @Query(filter: #Predicate<WordProgress> { $0.isKnown }) private var knownProgress: [WordProgress]

    @State private var lookedUpWord: LookedUpWord?
    /// The Article split into words, worked out once. Re-splitting on every render would run the
    /// tokenizer over a whole 微信 article each time a tap wrote a row and invalidated the query.
    @State private var segmented: [SegmentedWord] = []
    @State private var rendered = AttributedString()
    /// What the last 读完 moved, shown quietly under the button. Ticket 17 replaces this with the
    /// Tick sheet; the line stays, because it is the only place the student is told what changed.
    @State private var banked: VocabularyLibrary.BankResult?
    /// 读完 couldn't save. The student has to be told: this is the one moment the app records what
    /// their reading proved, and a button that silently does nothing reads as broken.
    @State private var bankFailed = false
    /// Seconds the Article has actually been on screen. Not a record: it lives with the screen and
    /// is handed to the Tick sheet, and a kill mid-article means the student types the number in.
    @State private var secondsRead: TimeInterval = 0
    @State private var shownAt: Date?
    @State private var tickTarget: TickTarget?
    @State private var isChoosingAction = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // The student's own writing: never translated.
                Text(verbatim: article.title)
                    .font(Theme.serif(26))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 0) {
                    if let source = article.source {
                        Text(verbatim: source)
                        Text(verbatim: " · ")
                    }
                    Text(verbatim: importedDayText)
                }
                .font(Theme.meta)
                .foregroundStyle(Theme.muted)
                .padding(.top, 6)

                Text(rendered)
                    .font(Theme.serif(19))
                    .lineSpacing(11)
                    .tint(Theme.ink)
                    .padding(.top, 20)
                    .textSelection(.disabled)

                VStack(spacing: 10) {
                    Button("读完") {
                        do {
                            banked = try VocabularyLibrary(context: context).bank(article)
                            bankFailed = false
                            // A Word that reached Known loses its underline, so redraw.
                            rendered = render()
                            offerToTick()
                        } catch {
                            banked = nil
                            bankFailed = true
                        }
                    }
                    .buttonStyle(RedButtonStyle())

                    if bankFailed {
                        Text("没能记录这次阅读")
                            .font(Theme.meta)
                            .foregroundStyle(Theme.error)
                    } else if let banked {
                        bankedLine(banked)
                    }
                }
                .padding(.top, 28)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Theme.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { shownAt = Date() }
        .onDisappear { stopCounting() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                shownAt = Date()
            } else {
                // Time only accrues while the Article is really on screen. The app cannot tell
                // reading from staring, but it can tell reading from being in someone's pocket.
                stopCounting()
            }
        }
        .confirmationDialog(
            Text("记到哪个计划？"),
            isPresented: $isChoosingAction,
            titleVisibility: .visible
        ) {
            ForEach(offeredActions) { action in
                Button(action.title) { tick(action) }
            }
            // Always there, for reading that was not part of the plan. The evidence is banked
            // either way: Clean Sightings never depend on a Completion being saved.
            Button("不记录", role: .cancel) {
                // Still on the screen and probably still reading, so start counting again rather
                // than carrying a stale figure into the next 读完.
                secondsRead = 0
                shownAt = Date()
            }
        } message: {
            Text("读了 \(ReadingSession.minutes(forSeconds: secondsRead)) 分钟")
        }
        .sheet(item: $tickTarget) { target in
            TickSheetView(
                action: target.action,
                day: Day.today(),
                prefilledMinutes: target.minutes,
                prefilledNote: target.note
            )
        }
        .task(id: article.persistentModelID) {
            // SwiftUI can reuse this screen for a different Article, which is what the id is for.
            // The last Article's line must not be left sitting under the new one's button.
            banked = nil
            bankFailed = false
            secondsRead = 0
            shownAt = Date()
            segmented = VocabularyLibrary.segment(article.text)
            rendered = render()
        }
        .onChange(of: knownWords) {
            rendered = render()
        }
        .environment(\.openURL, OpenURLAction { url in
            guard let word = WordLink.word(from: url) else { return .systemAction }
            let library = VocabularyLibrary(context: context)
            // Read before recording, because recording the Lookup is what clears them.
            let cleared = ((try? library.cleanSightings(of: word)) ?? [])
                .compactMap { $0.article?.title }
            lookedUpWord = LookedUpWord(text: word, clearedArticles: cleared)
            try? library.lookUp(word, in: article)
            return .handled
        })
        .sheet(item: $lookedUpWord) { looked in
            WordLookupSheet(word: looked.text, clearedArticles: looked.clearedArticles)
                .presentationDetents([.medium])
        }
    }

    private func stopCounting() {
        guard let shownAt else { return }
        secondsRead += Date().timeIntervalSince(shownAt)
        self.shownAt = nil
    }

    /// After 读完, offer to tick today's reading Routine with the minutes just read.
    ///
    /// Nothing is offered when there is no suitable Action: the app never makes one by itself, and
    /// the evidence has been banked either way, so declining costs the student nothing.
    private func offerToTick() {
        stopCounting()
        guard !offeredActions.isEmpty else {
            // Nothing to offer, so the student is still reading: the clock goes back on.
            shownAt = Date()
            return
        }
        isChoosingAction = true
    }

    private var offeredActions: [Action] {
        let today = Day.today()
        return ReadingSession.offer(
            among: DayPlan.plan(candidateActions, on: today, today: today),
            completions: allCompletions,
            on: today
        )
    }

    private func tick(_ action: Action) {
        tickTarget = TickTarget(
            action: action,
            minutes: ReadingSession.minutes(forSeconds: secondsRead),
            note: (try? VocabularyLibrary(context: context).noteForSession(with: article)) ?? ""
        )
    }

    /// One quiet line. No animation, no celebration, no sound: this happens every time the student
    /// finishes something, and anything louder would wear out in a week.
    @ViewBuilder
    private func bankedLine(_ result: VocabularyLibrary.BankResult) -> some View {
        if result.wasReread {
            Text("重读 · 没有新的记录")
                .font(Theme.meta)
                .foregroundStyle(Theme.muted)
        } else {
            HStack(spacing: 6) {
                if result.newlyKnown > 0 {
                    Text("\(result.newlyKnown) 个词已掌握")
                        .foregroundStyle(Theme.onDone)
                }
                if result.newlyKnown > 0 && result.advanced > 0 {
                    Text(verbatim: "·").foregroundStyle(Theme.muted)
                }
                if result.advanced > 0 {
                    Text("\(result.advanced) 个词更近一步")
                        .foregroundStyle(Theme.muted)
                }
                // Losing ground is not the same as an Article with nothing in it, and the line
                // must not read as though nothing happened when the student just tapped their way
                // through every Word.
                if result.newlyKnown == 0 && result.advanced == 0 {
                    if result.returnedToZero > 0 {
                        Text("\(result.returnedToZero) 个词要重新开始")
                            .foregroundStyle(Theme.late)
                    } else {
                        Text("这篇没有新的词")
                            .foregroundStyle(Theme.muted)
                    }
                }
            }
            .font(Theme.meta)
        }
    }

    private var importedDayText: String {
        article.importedDay.date().formatted(.dateTime.month().day().locale(locale))
    }

    private var knownWords: Set<String> {
        Set(knownProgress.map(\.word))
    }

    /// The Article as one run of text: every word tappable, and the HSK 4/5 Words the student
    /// hasn't got yet marked with a thin rule. Punctuation and line breaks are kept exactly as they
    /// were written, so what is read is the real article.
    private func render() -> AttributedString {
        let text = article.text
        let known = knownWords
        var out = AttributedString()
        var cursor = text.startIndex

        for word in segmented {
            if cursor < word.range.lowerBound {
                out.append(plain(String(text[cursor..<word.range.lowerBound])))
            }
            var piece = AttributedString(word.text)
            piece.foregroundColor = Theme.ink
            piece.link = WordLink.url(for: word.text)
            // A Word already Known is not new any more, so it loses its mark.
            if word.isMeasured && !known.contains(word.text) {
                piece.underlineStyle = Text.LineStyle(pattern: .solid, color: Theme.rule)
            }
            out.append(piece)
            cursor = word.range.upperBound
        }
        if cursor < text.endIndex {
            out.append(plain(String(text[cursor...])))
        }
        return out
    }

    private func plain(_ text: String) -> AttributedString {
        var piece = AttributedString(text)
        piece.foregroundColor = Theme.ink
        return piece
    }
}

/// Carries a tapped word out of the rendered text.
///
/// SwiftUI has no per-word tap inside flowing text, so each word is a link and the screen handles
/// the opening itself. The scheme is the app's own and never leaves it.
enum WordLink {
    private static let scheme = "psword"

    static func url(for word: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "w"
        components.queryItems = [URLQueryItem(name: "t", value: word)]
        return components.url
    }

    static func word(from url: URL) -> String? {
        guard url.scheme == scheme else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == "t" }?
            .value
    }
}

/// The Action 读完 offers to tick, with what the session already knows to fill in.
struct TickTarget: Identifiable {
    let action: Action
    let minutes: Int
    let note: String
    var id: PersistentIdentifier { action.persistentModelID }
}

/// The word the lookup sheet is showing. A small type of its own rather than a bare String, so no
/// stdlib conformance has to be invented to satisfy `sheet(item:)`.
struct LookedUpWord: Identifiable {
    let text: String
    /// The Articles this tap just cost the Word, read before the **Lookup** cleared them.
    ///
    /// Captured here rather than queried in the sheet: the same tap that opens the sheet records the
    /// Lookup, which deletes the **Clean Sightings**, so by the time the sheet draws there is
    /// nothing left to find. See ADR 0004 for why a Lookup takes them.
    var clearedArticles: [String] = []
    var id: String { text }
}
