import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// 难词: the Words the store already knows are defeating the student, read back from **Lookups**
/// that have been recorded since ticket 15 and shown nowhere until now. See CONTEXT.md.
@MainActor
struct StubbornWordsTests {
    private struct Shelf {
        let vocabulary: VocabularyLibrary
        let articles: ArticleLibrary
    }

    private func shelf() throws -> Shelf {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        return Shelf(
            vocabulary: VocabularyLibrary(context: context),
            articles: ArticleLibrary(context: context)
        )
    }

    private let day = Day(number: 20260921)

    @Test func aWordLookedUpInTwoArticlesIsStubborn() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: "1\n正文")
        let second = try shelf.articles.add(text: "2\n正文")
        try shelf.vocabulary.lookUp("厕所", in: first, on: day)
        try shelf.vocabulary.lookUp("厕所", in: second, on: day)

        let stubborn = try shelf.vocabulary.stubbornWords()
        #expect(stubborn.map(\.entry.word) == ["厕所"])
        #expect(stubborn.first?.articleCount == 2)
    }

    @Test func aWordLookedUpInOnlyOneArticleIsNotStubborn() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "1\n正文")
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)
        #expect(try shelf.vocabulary.stubbornWords().isEmpty)
    }

    /// Two Lookups inside the *same* Article count as one Article, not two — matching how a Clean
    /// Sighting counts one Article regardless of how many times a Word appears in it. Otherwise one
    /// nervous re-tap during a single reading would make a Word look twice as stubborn as it really
    /// is. This is the decision the ticket left open, pinned here.
    @Test func twoLookupsInOneArticleCountAsOne() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "1\n正文")
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)
        #expect(try shelf.vocabulary.stubbornWords().isEmpty)
    }

    @Test func aWordThatBecomesKnownLeavesTheList() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: "1\n正文")
        let second = try shelf.articles.add(text: "2\n正文")
        try shelf.vocabulary.lookUp("厕所", in: first, on: day)
        try shelf.vocabulary.lookUp("厕所", in: second, on: day)
        #expect(try shelf.vocabulary.stubbornWords().count == 1)

        try shelf.vocabulary.markKnown("厕所", on: day)
        #expect(try shelf.vocabulary.stubbornWords().isEmpty)
    }

    /// Defence in depth: even if a WordLookup somehow existed for an unmeasured Word — today
    /// `lookUp` itself already refuses to record one, and `stubbornWords()` (ticket 10) doesn't even
    /// read `WordLookup` any more — stubbornWords() must not surface it. There is no HSKEntry to
    /// show, and ADR 0005 means it was never state to begin with.
    @Test func aRawLookupOfAnUnmeasuredWordIsNeverStubborn() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: "1\n正文")
        let second = try shelf.articles.add(text: "2\n正文")
        shelf.vocabulary.context.insert(WordLookup(word: "很", article: first, day: day))
        shelf.vocabulary.context.insert(WordLookup(word: "很", article: second, day: day))
        try shelf.vocabulary.context.saveOrRollBack()

        #expect(try shelf.vocabulary.stubbornWords().isEmpty)
    }

    // MARK: - The distinct-Article count itself (ticket 10)

    /// `stubbornArticleCount` is what `stubbornWords()` reads directly now, so it has to be right on
    /// its own, not only through the list it produces.
    @Test func lookingUpAWordInTwoArticlesCountsTwo() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: "1\n正文")
        let second = try shelf.articles.add(text: "2\n正文")
        try shelf.vocabulary.lookUp("厕所", in: first, on: day)
        try shelf.vocabulary.lookUp("厕所", in: second, on: day)
        #expect(try shelf.vocabulary.progress(for: "厕所")?.stubbornArticleCount == 2)
    }

    /// A second tap in the *same* Article must not move the count — the same rule
    /// `twoLookupsInOneArticleCountAsOne` pins through the list this count feeds.
    @Test func aSecondLookupInTheSameArticleLeavesTheCountAtOne() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "1\n正文")
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)
        #expect(try shelf.vocabulary.progress(for: "厕所")?.stubbornArticleCount == 1)
    }

    // MARK: - Backfilling a count written before this field existed

    /// A Word already looked up in more than one Article before this ticket must not vanish from
    /// 难词 the moment it ships: its count is nil, not zero, and the backfill has to tell that apart
    /// from a Word genuinely never looked up.
    @Test func theBackfillComputesTheTrueCountFromExistingLookups() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: "1\n正文")
        let second = try shelf.articles.add(text: "2\n正文")
        // Exactly what a pre-ticket-10 install has: WordLookup rows recording real history, and a
        // WordProgress row whose count was never set because the field didn't exist yet.
        shelf.vocabulary.context.insert(WordLookup(word: "厕所", article: first, day: day))
        shelf.vocabulary.context.insert(WordLookup(word: "厕所", article: second, day: day))
        let progress = try #require(try shelf.vocabulary.progressCreatingIfNeeded(for: "厕所"))
        try shelf.vocabulary.context.saveOrRollBack()
        #expect(progress.stubbornArticleCount == nil)

        #expect(try shelf.vocabulary.backfillStubbornArticleCounts() == 1)
        #expect(progress.stubbornArticleCount == 2)
        #expect(try shelf.vocabulary.stubbornWords().map(\.entry.word) == ["厕所"])
    }

    /// A Word genuinely never looked up settles to zero, not left nil forever, so the backfill never
    /// has reason to look at it again.
    @Test func theBackfillSettlesAWordWithNoLookupsToZero() throws {
        let shelf = try shelf()
        let progress = try #require(try shelf.vocabulary.progressCreatingIfNeeded(for: "厕所"))
        try shelf.vocabulary.context.saveOrRollBack()

        #expect(try shelf.vocabulary.backfillStubbornArticleCounts() == 1)
        #expect(progress.stubbornArticleCount == 0)
    }

    /// The race the review caught: a pre-ticket-10 row with real history (nil count) gets looked up
    /// again in a *new* Article before the startup backfill has reached it. `lookUp` must not assume
    /// nil means zero — that would silently throw away the two Articles already earned and replace
    /// them with "one", which the backfill would then skip forever since the row is no longer nil.
    @Test func lookingUpAWordWithUnbackfilledHistoryDoesNotLoseIt() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: "1\n正文")
        let second = try shelf.articles.add(text: "2\n正文")
        // Exactly what a pre-ticket-10 install has: real WordLookup history, count still nil.
        shelf.vocabulary.context.insert(WordLookup(word: "厕所", article: first, day: day))
        shelf.vocabulary.context.insert(WordLookup(word: "厕所", article: second, day: day))
        try shelf.vocabulary.context.saveOrRollBack()

        let third = try shelf.articles.add(text: "3\n正文")
        try shelf.vocabulary.lookUp("厕所", in: third, on: day)

        #expect(try shelf.vocabulary.progress(for: "厕所")?.stubbornArticleCount == 3)
    }

    /// Run at every start, so running it again must do nothing to a row already settled.
    @Test func runningTheBackfillAgainChangesNothing() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "1\n正文")
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)
        // The live path already sets the count on lookUp, so there's nothing left to backfill here —
        // this is the "already correct, must not be disturbed" case, reached the ordinary way rather
        // than by hand-inserting rows.
        #expect(try shelf.vocabulary.backfillStubbornArticleCounts() == 0)
        #expect(try shelf.vocabulary.progress(for: "厕所")?.stubbornArticleCount == 1)
    }

    @Test func orderedMostLookedUpFirst() throws {
        let shelf = try shelf()
        var articles: [Article] = []
        for index in 1...3 {
            articles.append(try shelf.articles.add(text: "\(index)\n正文"))
        }
        for article in articles {
            try shelf.vocabulary.lookUp("厕所", in: article, on: day)
        }
        for article in articles.prefix(2) {
            try shelf.vocabulary.lookUp("被子", in: article, on: day)
        }

        let stubborn = try shelf.vocabulary.stubbornWords()
        #expect(stubborn.map(\.entry.word) == ["厕所", "被子"])
    }

    // MARK: - Word Note

    @Test func aNoteCanBeSavedChangedAndCleared() throws {
        let shelf = try shelf()
        try shelf.vocabulary.setNote("想着「厕」字旁", for: "厕所")
        #expect(try shelf.vocabulary.progress(for: "厕所")?.noteText == "想着「厕」字旁")

        try shelf.vocabulary.setNote("换一个说法", for: "厕所")
        #expect(try shelf.vocabulary.progress(for: "厕所")?.noteText == "换一个说法")

        try shelf.vocabulary.setNote("", for: "厕所")
        #expect(try shelf.vocabulary.progress(for: "厕所")?.noteText == nil)
    }

    @Test func aNoteSurvivesTheWordBecomingKnown() throws {
        let shelf = try shelf()
        try shelf.vocabulary.setNote("笔记", for: "厕所")
        try shelf.vocabulary.markKnown("厕所", on: day)
        #expect(try shelf.vocabulary.progress(for: "厕所")?.noteText == "笔记")
    }

    /// A Word Note is not a Completion Note, and must never be read back by the unrelated screen
    /// that lists those.
    @Test func aWordNoteIsNeverAmongCompletionNotes() throws {
        let shelf = try shelf()
        try shelf.vocabulary.setNote("笔记", for: "厕所")
        let completions = try shelf.vocabulary.context.fetch(FetchDescriptor<Completion>())
        #expect(completions.isEmpty)
    }
}
