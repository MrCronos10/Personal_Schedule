import Foundation
import SwiftData
import Testing
@testable import PersonalSchedule

/// 今日新词: how a **Level** gets finished, because real Articles will never hold all 600 Words.
///
/// It must stay small and unpunishing. The moment it nags it is the abandoned flashcard deck
/// [ADR 0004](../docs/adr/0004-known-is-earned-by-reading-not-by-review.md) exists to avoid.
@MainActor
struct DailyNewWordsTests {
    private func library() throws -> VocabularyLibrary {
        let container = try ScheduleStore.makeContainer(inMemory: true)
        return VocabularyLibrary(context: ModelContext(container))
    }

    private let day = Day(number: 20260921)

    @Test func tenUnmetWordsOfTheServedLevelComeBack() throws {
        let shelf = try library()
        let words = try shelf.dailyNewWords(on: day)
        #expect(words.count == 10)
        #expect(words.allSatisfy { $0.level == .four })
        #expect(Set(words.map(\.word)).count == 10)
    }

    /// The same ten all day, so leaving the tab and coming back doesn't reshuffle them.
    @Test func theSameDayGivesTheSameTen() throws {
        let shelf = try library()
        let first = try shelf.dailyNewWords(on: day).map(\.word)
        let again = try shelf.dailyNewWords(on: day).map(\.word)
        #expect(first == again)
    }

    /// Answering one Word must not move the other nine. The window is seeded off the whole Word
    /// List, not the pool, because the pool shrinks the moment anything is answered — or the moment
    /// a word is tapped while reading.
    @Test func answeringOneWordDoesNotReshuffleTheRest() throws {
        let shelf = try library()
        let before = try shelf.dailyNewWords(on: day).map(\.word)
        try shelf.markKnown(before[0], on: day)

        let after = try shelf.dailyNewWords(on: day).map(\.word)
        #expect(Array(after.prefix(9)) == Array(before.dropFirst()))
    }

    @Test func aDifferentDayGivesDifferentWords() throws {
        let shelf = try library()
        let today = try shelf.dailyNewWords(on: day).map(\.word)
        let tomorrow = try shelf.dailyNewWords(on: day.adding(days: 1)).map(\.word)
        #expect(today != tomorrow)
    }

    /// A Word already on its way through reading is not offered here.
    @Test func aWordAlreadyMetIsNeverOffered() throws {
        let shelf = try library()
        let first = try #require(try shelf.dailyNewWords(on: day).first)
        try shelf.markNotKnownToday(first.word)

        #expect(try !shelf.dailyNewWords(on: day).map(\.word).contains(first.word))
    }

    @Test func markingAWordKnownRaisesTheLevelCount() throws {
        let shelf = try library()
        let first = try #require(try shelf.dailyNewWords(on: day).first)
        try shelf.markKnown(first.word, on: day)
        #expect(try shelf.level(.four).known == 1)
        #expect(try !shelf.dailyNewWords(on: day).map(\.word).contains(first.word))
    }

    /// The pool empties at HSK 5, because finishing HSK 4 moves the Served Level on rather than
    /// running the pool down — which is the behaviour, not a gap in it.
    @Test func fewerThanTenLeftIsFineAndNoneLeftIsFine() throws {
        let shelf = try library()
        for entry in HSKWordList.words(at: .four) {
            try shelf.markKnown(entry.word, on: day)
        }
        let five = HSKWordList.words(at: .five)
        for entry in five.dropLast(4) {
            try shelf.markKnown(entry.word, on: day)
        }
        #expect(try shelf.dailyNewWords(on: day).count == 4)

        for entry in five.suffix(4) {
            try shelf.markKnown(entry.word, on: day)
        }
        #expect(try shelf.dailyNewWords(on: day).isEmpty)
    }

    /// Once HSK 4 is Passed the pool becomes HSK 5. Passing changes this and nothing else.
    @Test func onceFourIsPassedTheWordsComeFromFive() throws {
        let shelf = try library()
        for entry in HSKWordList.words(at: .four).prefix(480) {
            try shelf.markKnown(entry.word, on: day)
        }
        #expect(try shelf.servedLevel() == .five)
        #expect(try shelf.dailyNewWords(on: day).allSatisfy { $0.level == .five })
    }

    /// A grammar entry is met here or nowhere: no word split out of an Article can ever match it,
    /// so the daily pool has to be willing to offer one.
    @Test func grammarEntriesAreOfferedHere() throws {
        let shelf = try library()
        let grammarEntry = HSKWordList.words(at: .four).first(where: \.isGrammarEntry)
        let grammar = try #require(grammarEntry)
        for entry in HSKWordList.words(at: .four) where entry.word != grammar.word {
            try shelf.markNotKnownToday(entry.word)
        }
        #expect(try shelf.dailyNewWords(on: day).map(\.word) == [grammar.word])
    }
}
