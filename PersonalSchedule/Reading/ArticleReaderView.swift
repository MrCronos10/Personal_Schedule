import SwiftData
import SwiftUI

/// Reading one **Article**. The text is shown as it was written, with HSK 4/5 **Words** underlined,
/// and tapping any word says what it means.
///
/// This is the one screen in the app made for reading, so it gets the room: no chips, no meta, no
/// controls in the way of the text. Three zones (ADR 0009): the title and a thin progress bar, the
/// text with a Word's meaning dropping in under its paragraph, and the Coach Dock at the bottom.
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

    /// The Word whose meaning is open under a paragraph. One at a time: tapping another Word, in
    /// this paragraph or another, moves the card there.
    @State private var inlineLookup: InlineLookup?
    @State private var scroll = ScrollMetrics()
    @State private var viewportHeight: CGFloat = 0
    /// The Article split into words, worked out once. Re-splitting on every render would run the
    /// tokenizer over a whole 微信 article each time a tap wrote a row and invalidated the query.
    @State private var segmented: [SegmentedWord] = []
    @State private var paragraphs: [ReaderParagraph] = []
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
                    .font(Theme.serif(22))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    HStack(spacing: 0) {
                        if let source = article.source {
                            Text(verbatim: source)
                            Text(verbatim: " · ")
                        }
                        Text(verbatim: importedDayText)
                    }
                    Spacer()
                    // One control for the whole Article, and only one: a speaker on every sentence
                    // would break the screen's own rule of keeping controls out of the way of the
                    // text, so this is the single place reading aloud lives.
                    SpeakerButton(text: article.text)
                }
                .font(Theme.meta)
                .foregroundStyle(Theme.muted)
                .padding(.top, 6)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(paragraphs) { paragraph in
                        Text(paragraph.text)
                            .font(Theme.reading)
                            .lineSpacing(Theme.readingLineSpacing)
                            .tint(Theme.ink)
                            .textSelection(.disabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .environment(\.openURL, OpenURLAction { url in
                                open(url, inParagraph: paragraph.id)
                            })
                        if let inlineLookup, inlineLookup.paragraph == paragraph.id {
                            inlineCard(for: inlineLookup)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .padding(.top, 20)

                VStack(spacing: 10) {
                    Button("读完") {
                        do {
                            banked = try VocabularyLibrary(context: context).bank(article)
                            bankFailed = false
                            // A Word that reached Known loses its underline, so redraw.
                            paragraphs = render()
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
            .background(
                GeometryReader { content in
                    Color.clear.preference(
                        key: ScrollMetricsKey.self,
                        value: ScrollMetrics(
                            scrolled: -content.frame(in: .named("reader")).minY,
                            content: content.size.height
                        )
                    )
                }
            )
        }
        .coordinateSpace(name: "reader")
        .onPreferenceChange(ScrollMetricsKey.self) { scroll = $0 }
        .background(GeometryReader { viewport in
            Color.clear.onAppear { viewportHeight = viewport.size.height }
                .onChange(of: viewport.size.height) { _, height in viewportHeight = height }
        })
        .overlay(alignment: .top) { progressBar }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CoachDock(article: article)
        }
        .background(BackgroundView())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { shownAt = Date() }
        .onDisappear {
            stopCounting()
            // Only this Article's own narration: a Word sheet opened from within it never plays
            // anything longer-lived than the reader itself, but guarding here rather than calling
            // stop() outright keeps this screen from ever silencing sound that isn't its own.
            SpeechPlayer.shared.stop(ifPlaying: article.text)
        }
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
            paragraphs = render()
        }
        .onChange(of: knownWords) {
            paragraphs = render()
        }
    }

    /// The thin grid-red line under the top edge: how far down the Article the student has read.
    private var progressBar: some View {
        GeometryReader { bar in
            Rectangle()
                .fill(Theme.red)
                .frame(
                    width: bar.size.width * ReadingProgress.fraction(
                        scrolled: scroll.scrolled, content: scroll.content, viewport: viewportHeight
                    ),
                    height: 2
                )
        }
        .frame(height: 2)
        .accessibilityHidden(true)
    }

    /// A tapped Word: record the Lookup, then open its meaning under the paragraph it sits in.
    private func open(_ url: URL, inParagraph paragraph: Int) -> OpenURLAction.Result {
        guard let word = WordLink.word(from: url) else { return .systemAction }
        let library = VocabularyLibrary(context: context)
        // Read before recording, because recording the Lookup is what clears them.
        let cleared = ((try? library.cleanSightings(of: word)) ?? [])
            .compactMap { $0.article?.title }
        withAnimation(.easeOut(duration: 0.2)) {
            inlineLookup = InlineLookup(paragraph: paragraph, word: LookedUpWord(text: word, clearedArticles: cleared))
        }
        try? library.lookUp(word, in: article)
        paragraphs = render()
        return .handled
    }

    private func inlineCard(for lookup: InlineLookup) -> some View {
        WordLookupContent(
            word: lookup.word.text,
            clearedArticles: lookup.word.clearedArticles,
            onClose: { withAnimation(.easeOut(duration: 0.2)) { inlineLookup = nil } }
        )
        .id(lookup.word.text)
        .card()
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { inlineLookup = nil }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .padding(12)
            }
            .accessibilityLabel(Text("关闭"))
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

    /// Phrased by `BankedResultLine`, which the Article's row uses too, so the two can never come to
    /// word the same numbers differently.
    private func bankedLine(_ result: VocabularyLibrary.BankResult) -> some View {
        // Freshly banked: this is the one moment the stamp lands (ticket 08). The same line reused
        // on the Article's own row (ticket 03) never passes this, so it never replays there.
        BankedResultLine(result: result, isFreshlyBanked: true)
    }

    private var importedDayText: String {
        article.importedDay.date().formatted(.dateTime.month().day().locale(locale))
    }

    private var knownWords: Set<String> {
        Set(knownProgress.map(\.word))
    }

    /// The Article as paragraphs: every word tappable, and the HSK 4/5 Words the student hasn't got
    /// yet marked with a thin rule. Punctuation is kept exactly as it was written, so what is read
    /// is the real article.
    private func render() -> [ReaderParagraph] {
        let text = article.text
        let known = knownWords
        // Words already looked up in this Article get a darker rule: the same "seen" faded ink the
        // Collection Grid uses, so the two screens speak one language.
        let lookedUp = Set(((try? VocabularyLibrary(context: context).lookups(in: article)) ?? []).map(\.word))
        return ArticleParagraphs.ranges(in: text).enumerated().map { index, line in
            var out = AttributedString()
            var cursor = line.lowerBound
            for word in segmented where word.range.lowerBound >= line.lowerBound && word.range.upperBound <= line.upperBound {
                if cursor < word.range.lowerBound {
                    out.append(plain(String(text[cursor..<word.range.lowerBound])))
                }
                var piece = AttributedString(word.text)
                piece.foregroundColor = Theme.ink
                piece.link = WordLink.url(for: word.text)
                // A Word already Known is not new any more, so it loses its mark.
                if word.isMeasured && !known.contains(word.text) {
                    piece.underlineStyle = Text.LineStyle(
                        pattern: .solid, color: lookedUp.contains(word.text) ? Theme.muted : Theme.rule
                    )
                }
                out.append(piece)
                cursor = word.range.upperBound
            }
            if cursor < line.upperBound {
                out.append(plain(String(text[cursor..<line.upperBound])))
            }
            return ReaderParagraph(id: index, text: out)
        }
    }

    private func plain(_ text: String) -> AttributedString {
        var piece = AttributedString(text)
        piece.foregroundColor = Theme.ink
        return piece
    }
}

/// One paragraph of the Article as the reader draws it.
struct ReaderParagraph: Identifiable {
    let id: Int
    let text: AttributedString
}

/// Where a Word's meaning is open: under which paragraph, and for which Word.
struct InlineLookup {
    let paragraph: Int
    let word: LookedUpWord
}

struct ScrollMetrics: Equatable {
    var scrolled: CGFloat = 0
    var content: CGFloat = 0
}

struct ScrollMetricsKey: PreferenceKey {
    static var defaultValue = ScrollMetrics()
    static func reduce(value: inout ScrollMetrics, nextValue: () -> ScrollMetrics) { value = nextValue() }
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
