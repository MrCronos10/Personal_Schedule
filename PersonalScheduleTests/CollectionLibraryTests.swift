import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// The Collection Grid's rules: one cell per Word, in one of three Cell States. See CONTEXT.md and
/// ADR 0009. The screens ask this library; they never work a state out themselves.
@MainActor
struct CollectionLibraryTests {
    private struct Shelf {
        let collection: CollectionLibrary
        let vocabulary: VocabularyLibrary
        let topic: TopicLibrary
        let articles: ArticleLibrary
    }

    private func shelf() throws -> Shelf {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        return Shelf(
            collection: CollectionLibrary(context: context),
            vocabulary: VocabularyLibrary(context: context),
            topic: TopicLibrary(context: context),
            articles: ArticleLibrary(context: context)
        )
    }

    private let day = Day(number: 20260921)

    private func state(of word: String, in cells: [CollectionCell]) -> CellState? {
        cells.first { $0.word == word }?.state
    }

    @Test func aFreshInstallHasEveryCellNotMetOutOfTheFixedTotals() throws {
        let shelf = try shelf()
        let four = try shelf.collection.cells(for: .four)
        let five = try shelf.collection.cells(for: .five)
        let topic = try shelf.collection.topicCells()

        #expect(four.count == 600)
        #expect(five.count == 1300)
        #expect(topic.count == 125)
        #expect((four + five + topic).allSatisfy { $0.state == .notMet })
    }

    @Test func aKnownWordIsKnownAndTheKnownCellsMatchTheLevelCount() throws {
        let shelf = try shelf()
        try shelf.vocabulary.markKnown("厕所", on: day)

        let four = try shelf.collection.cells(for: .four)
        #expect(state(of: "厕所", in: four) == .known)
        #expect(four.filter { $0.state == .known }.count == (try shelf.vocabulary.level(.four).known))
        #expect(try shelf.collection.cells(for: .five).allSatisfy { $0.state == .notMet })
    }

    @Test func aLookedUpWordIsSeen() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "1\n厕所")
        #expect(VocabularyLibrary.hskWords(in: article.text).map(\.word) == ["厕所"])
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)

        #expect(state(of: "厕所", in: try shelf.collection.cells(for: .four)) == .seen)
    }

    @Test func aWordReadCleanButNotYetKnownIsSeen() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "1\n厕所")
        #expect(VocabularyLibrary.hskWords(in: article.text).map(\.word) == ["厕所"])
        try shelf.vocabulary.bank(article, on: day)

        #expect(state(of: "厕所", in: try shelf.collection.cells(for: .four)) == .seen)
    }

    @Test func aWordNeverMetStaysNotMetWhileOthersAreSeen() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "1\n厕所")
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)

        let four = try shelf.collection.cells(for: .four)
        #expect(four.filter { $0.state == .seen }.count == 1)
        #expect(four.filter { $0.state == .notMet }.count == 599)
    }

    @Test func aLookupOnAKnownWordLeavesItKnown() throws {
        let shelf = try shelf()
        let article = try shelf.articles.add(text: "1\n厕所")
        try shelf.vocabulary.markKnown("厕所", on: day)
        try shelf.vocabulary.lookUp("厕所", in: article, on: day)

        #expect(state(of: "厕所", in: try shelf.collection.cells(for: .four)) == .known)
    }

    @Test func takingKnownBackReturnsTheCellToNotMetOrSeen() throws {
        let shelf = try shelf()
        try shelf.vocabulary.markKnown("厕所", on: day)
        try shelf.vocabulary.markNotKnown("厕所", on: day)

        #expect(state(of: "厕所", in: try shelf.collection.cells(for: .four)) == .notMet)
    }

    @Test func cellsFollowTheWordListsOwnOrder() throws {
        let shelf = try shelf()
        let four = try shelf.collection.cells(for: .four)
        #expect(four.map(\.word) == HSKWordList.words(at: .four).map(\.word))
    }

    @Test func aTopicWordIsKnownOrNotMetAndNeverSeen() throws {
        let shelf = try shelf()
        try shelf.topic.markKnown("堆肥", on: day)

        let topic = try shelf.collection.topicCells()
        #expect(state(of: "堆肥", in: topic) == .known)
        #expect(topic.filter { $0.state == .seen }.isEmpty)
        #expect(topic.filter { $0.state == .known }.count == (try shelf.topic.meter().known))
    }

    @Test func aTopicWordKnownOnTheTopicListDoesNotFillAnHSKCell() throws {
        let shelf = try shelf()
        try shelf.topic.markKnown("农业", on: day)

        #expect(state(of: "农业", in: try shelf.collection.topicCells()) == .known)
        let hsk = try shelf.collection.cells(for: .four) + (try shelf.collection.cells(for: .five))
        #expect(state(of: "农业", in: hsk) != .known)
    }

    @Test func aCustomTopicWordGetsACell() throws {
        let shelf = try shelf()
        try shelf.topic.addCustom(word: "沼气池", pinyin: "zhǎoqìchí", english: "biogas digester", group: .ferment, on: day)

        let topic = try shelf.collection.topicCells()
        #expect(topic.count == 126)
        #expect(state(of: "沼气池", in: topic) == .notMet)
    }

    @Test func freshlyKnownIsWhatWasNotKnownTheLastTimeTheGridWasSeen() {
        let fresh = CollectionLibrary.freshlyKnown(current: ["a", "b", "c"], lastSeen: ["a"])
        #expect(fresh == ["b", "c"])
        #expect(CollectionLibrary.freshlyKnown(current: ["a"], lastSeen: ["a", "b"]).isEmpty)
    }
}
