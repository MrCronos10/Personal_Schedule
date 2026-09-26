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
    /// `lookUp` itself already refuses to record one — stubbornWords() must not surface it. There is
    /// no HSKEntry to show, and ADR 0005 means it was never state to begin with.
    @Test func aRawLookupOfAnUnmeasuredWordIsNeverStubborn() throws {
        let shelf = try shelf()
        let first = try shelf.articles.add(text: "1\n正文")
        let second = try shelf.articles.add(text: "2\n正文")
        shelf.vocabulary.context.insert(WordLookup(word: "很", article: first, day: day))
        shelf.vocabulary.context.insert(WordLookup(word: "很", article: second, day: day))
        try shelf.vocabulary.context.saveOrRollBack()

        #expect(try shelf.vocabulary.stubbornWords().isEmpty)
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
