import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// The **Stubborn Deck**: every **Stubborn Word**, opened by choice from 难词. 认识 marks a Word
/// **Known**; 不认识 changes nothing. See ADR 0012.
///
/// Fixtures name their Words outright (厕所, 被子) and each test first asserts which Words are
/// Stubborn, so a count is never resting on a guess about the fixture.
@MainActor
struct StubbornDeckTests {
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

    private let day = Day(number: 20261120)

    /// Looks `word` up in two fresh Articles, the least that makes it Stubborn.
    private func makeStubborn(_ word: String, in shelf: Shelf) throws {
        let first = try shelf.articles.add(text: "\(word)1\n正文")
        let second = try shelf.articles.add(text: "\(word)2\n正文")
        try shelf.vocabulary.lookUp(word, in: first, on: day)
        try shelf.vocabulary.lookUp(word, in: second, on: day)
    }

    // MARK: - The back of a card

    @Test func aStubbornWordCarriesItsWordNote() throws {
        let shelf = try shelf()
        try makeStubborn("厕所", in: shelf)
        try makeStubborn("被子", in: shelf)
        try shelf.vocabulary.setNote("想着「厕」字旁", for: "厕所")

        let stubborn = try shelf.vocabulary.stubbornWords()
        #expect(Set(stubborn.map(\.entry.word)) == ["厕所", "被子"])
        #expect(stubborn.first { $0.entry.word == "厕所" }?.note == "想着「厕」字旁")
        #expect(stubborn.first { $0.entry.word == "被子" }?.note == nil)
    }

    // MARK: - Answering a card

    @Test func knownMarksTheWordKnownAndTakesItOutOfTheNextDeck() throws {
        let shelf = try shelf()
        try makeStubborn("厕所", in: shelf)
        try makeStubborn("被子", in: shelf)
        #expect(Set(try shelf.vocabulary.stubbornWords().map(\.entry.word)) == ["厕所", "被子"])

        try shelf.vocabulary.answerInStubbornDeck("厕所", known: true, on: day)

        #expect(try shelf.vocabulary.progress(for: "厕所")?.isKnown == true)
        #expect(try shelf.vocabulary.stubbornWords().map(\.entry.word) == ["被子"])
    }

    /// 不认识 on a Word already looked up in two Articles adds no evidence. Answered on a *later* day,
    /// so a stray `setAside` would show as a moved set-aside day — restarting its thirty days and
    /// quietly changing what Daily New Words offers (ADR 0012).
    @Test func notKnownChangesNothing() throws {
        let shelf = try shelf()
        try makeStubborn("厕所", in: shelf)
        #expect(try shelf.vocabulary.stubbornWords().map(\.entry.word) == ["厕所"])
        let before = try #require(try shelf.vocabulary.progress(for: "厕所"))
        let setAsideBefore = before.setAsideDayNumber
        let sightingsBefore = try shelf.vocabulary.cleanSightings(of: "厕所").count

        let later = Day(number: 20261215)
        try shelf.vocabulary.answerInStubbornDeck("厕所", known: false, on: later)

        let after = try #require(try shelf.vocabulary.progress(for: "厕所"))
        #expect(after.setAsideDayNumber == setAsideBefore)
        #expect(after.setAsideDayNumber != later.number)
        #expect(after.isKnown == false)
        #expect(try shelf.vocabulary.cleanSightings(of: "厕所").count == sightingsBefore)
        #expect(try shelf.vocabulary.stubbornWords().map(\.entry.word) == ["厕所"])
    }
}
